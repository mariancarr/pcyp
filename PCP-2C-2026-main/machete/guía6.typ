// Guía 6: concurrencia en Go.
#set par(leading: 0.2em, spacing: 0.4em)
#set raw(tab-size: 2)
#show raw.where(block: false): set text(size: 7.3pt, font: "DejaVu Sans Mono")
#show raw.where(block: true): it => block(
  width: 100%,
  inset: (x: 4pt, y: 3pt),
  fill: rgb("f5f6f8"),
  radius: 2pt,
  above: 2pt,
  below: 3pt,
)[
  #set text(size: 7pt, font: "DejaVu Sans Mono")
  #set par(leading: 0.12em, spacing: 0pt)
  #it
]

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  align: top,
  [
    *Channels*
    ```go
    type Message struct {
      Text string
    }
    messages := make(chan Message)
    go func() {
      messages <- Message{Text: "hola"}
    }()
    msg := <-messages
    ```

    #text(size: 7.5pt)[
      #table(
        columns: (0.95fr, 1.2fr, 1.2fr),
        inset: (x: 3pt, y: 3pt),
        stroke: 0.3pt + gray,
        align: left + top,
        table.header(
          [*Canal*],
          [*Escritura* \ `ch <- valor`],
          [*Lectura* \ `valor := <-ch`],
        ),
        [*Sin buffer* \ `make(chan T)`],
        [Espera a que haya un lector listo.],
        [Espera a que haya un escritor listo.],
        [*Con buffer* \ `make(chan T, n)`],
        [Si hay lugar, deposita el valor y continúa. Si está lleno, espera
          a que se libere lugar.],
        [Si hay elementos, retira uno y continúa. Si está vacío, espera
          a que llegue un valor.],
      )
    ]

    En el canal *sin buffer*, el envío y la recepción se sincronizan:
    el valor pasa directamente del escritor al lector.

    ```go
    type Cmd string
    const (
      Next  Cmd = "Next"
      Count Cmd = "Count"
    )
    type Pedido struct {
      cmd   Cmd
      canal chan int
    }
    ```

    ```go
    ch <- Pedido{
      cmd:   Count,
      canal: miCanal,
    }
    ```

    ```go
    select {
    case value := <-results:
      use(value)
    default:
      doOtherWork()
    }
    ```

    Un canal `nil` deshabilita su caso en el `select`.

    ```go
    array := [4]int{1,2,3,4}
    make([]int, cantidadClientes)
    ```
  ],
  [
    *Ejemplo: enviar cada frecuencia*
    ```go
    func Timer(frecuencia int, canales []chan struct{}) {
      cantidadCanales := len(canales)
      ticker := time.NewTicker(
        time.Duration(frecuencia) * time.Millisecond,
      )
      defer ticker.Stop()
      for range ticker.C {
        for i := range cantidadCanales {
          select {
          case canales[i] <- struct{}{}:
            // Se pudo enviar
          default:
            // No hacemos nada
          }
        }
      }
    }
    ```

    *Cierre de canales.* El emisor hace `close(canalNombres)` para indicar
    que no enviará más valores. Los pendientes se pueden seguir leyendo.
    El receptor detecta el cierre así:
    ```go
    nombre, ok := <-canalNombres
    ```

    *Envío en una goroutine.* Para evitar un deadlock cuando el envío
    bloquearía a la rutina que debe continuar hasta la recepción, se puede
    enviar desde otra goroutine. El envío espera allí hasta que haya un
    receptor; la rutina actual puede seguir ejecutándose.
    ```go
    go func(patente int, canal chan<- MensajeADisponibles) {
      canal <- MensajeADisponibles{patente: patente}
    }(pago.patente, canalConDisponiblesParaBajas)
    ```

    *Recursos libres como buffer (simulacro, ej. 2).* El canal con buffer
    de capacidad N guarda los *números de los lugares libres*, sin repetir.
    Pedir un lugar es recibir del canal: lo retira y queda reservado para
    ese trapito. Si está vacío, espera hasta que se libere alguno.
    ```go
    disponibles := make(chan int, N)
    liberados := make(chan int)
    go lugares(N, disponibles, liberados)
    // Trapito: toma y reserva un lugar libre.
    lugar := <-disponibles
    // Barra: después de aceptar el pago.
    liberados <- lugar
    ```

    El auxiliar carga los N lugares y devuelve al buffer los liberados:
    ```go
    func lugares(n int, disponibles chan<- int,
        liberados <-chan int) {
      for i := 0; i < n; i++ {
        disponibles <- i
      }
      for lugar := range liberados {
        disponibles <- lugar
      }
    }
    ```
    *Recibir ya reserva*. Cada lugar se devuelve una sola vez al quedar libre.
  ],
)
