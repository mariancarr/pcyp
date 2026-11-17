// Guía 5: memoria transaccional y concurrencia en Haskell.
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

// El espacio flexible iguala la altura sin separar los ejemplos de código.
#let section-gap = [#v(0.4em, weak: false)#v(1fr)]

#let left-column = [
    *Cómo se ejecuta una transacción*

    Cuando un thread ejecuta `atomically t`, no realiza una operación
    bloqueante. Ejecuta `t` de manera _optimista_, suponiendo que ningún otro
    thread va a interferir, y mientras tanto va anotando en su _log_ (de la
    transacción) todas las TVars que lee, con el valor que vio, y todas las
    que escribe, con el valor nuevo. Las escrituras no impactan en las TVars
    mientras la transacción se está ejecutando: quedan sólo en el log.
    Es decir, no se vuelcan a memoria durante la transacción, como vamos a
    ver después, solamente se vuelcan al final, cuando se hace un commit
    exitoso. Por eso ningún otro thread puede ver un estado intermedio de
    la transacción. Si la misma transacción vuelve a leer una TVar que ya
    escribió, obtiene el valor nuevo que tiene anotado en su log.

    Al terminar, la transacción intenta hacer *commit*. Para eso verifica
    que todas las TVars que leyó sigan teniendo el valor que vio:
    - Si es así, todas sus escrituras impactan juntas, de una sola vez.
      Para el resto de los threads es como si la transacción entera hubiera
      ocurrido en ese instante.
    - Si alguna cambió (porque otro thread confirmó una transacción que la
      escribió), hay un _conflicto_. El log se descarta, como si la transacción
      nunca se hubiera ejecutado, y se vuelve a ejecutar desde el principio,
      inmediatamente, esta vez con los valores nuevos.

    #section-gap

    *STM vs. IO.* Una acción `STM a` combina acciones STM; `atomically` la
    ejecuta desde `IO a`. No se puede usar `atomically` dentro de STM ni hacer
    IO arbitrario dentro de una transacción (puede reejecutarse).

    - *`newTVar`, `readTVar`, `writeTVar`, `modifyTVar`, `retry`, `check`,
      `orElse`* son acciones de tipo `STM`. Solo se pueden combinar con otras
      acciones `STM` (con `do`, `>>=`, etc.), es decir, dentro de funciones
      cuyo resultado es `STM a`.
    - *`newTVarIO`, `readTVarIO`* son acciones de tipo `IO`. Se usan dentro
      de funciones `IO`.
    - *`atomically`* es el puente: toma una acción `STM a` y la ejecuta de
      forma atómica, devolviendo un `IO a`.

    #section-gap

    *Espera: `retry` y `check`.* `retry` descarta los cambios y duerme el
    thread hasta que cambie alguna TVar leída; entonces reintenta *toda* la
    transacción. No es espera activa. `check p` continúa si `p` es verdadero;
    si es falso hace `retry`. La condición indica cuándo *se puede seguir*.
    ```haskell
    decrementarSiPuede :: TVar Int -> STM ()
    decrementarSiPuede var = do
      actual <- readTVar var
      check (actual > 0)
      writeTVar var (actual - 1)
    ```
    Para contadores no negativos, el `check` reemplaza
    `if actual == 0 then retry else ...`.

    #section-gap

    *Alternativas: `orElse`.* Intenta la izquierda; si hace `retry`, descarta
    sus cambios y prueba la derecha. Si ambas hacen `retry`, espera cambios
    en las TVars leídas por cualquiera de las dos. Tiene *prioridad izquierda*.
    ```haskell
    decrementarAlguno v1 v2 =
      decrementarSiPuede v1 `orElse`
        decrementarSiPuede v2
    ```
    #section-gap

    ```haskell
    eterno = loop
      where
        loop = do
          print "Hola"
          threadDelay 1000000
          loop
    ```
]

#let right-column = [
    ```haskell
    data Juego = Juego
      { capacidad :: TVar Int
      , bolitas   :: TVar Int }
    type Contador = TVar Int
    -- juego :: Juego
    -- capacidad juego :: TVar Int
    -- readTVar (capacidad juego) :: STM Int
    ```

    #section-gap

    *Buffer opcional (`TVar (Maybe a)`).* Devuelve `Nothing` si está vacío;
    si hay un elemento, lo extrae y vacía el buffer. No espera.
    ```haskell
    intentarSacar buf = do
      contenido <- readTVar buf
      case contenido of
        Nothing -> return Nothing
        Just elemento -> do
          writeTVar buf Nothing
          return (Just elemento)
    ```
    #section-gap

    ```haskell
    demoSemaforo :: IO ()
    demoSemaforo = do
      semaforo <- newTVarIO 0
      consumidor <- async $ do
        atomically (do
          acquireSem semaforo
          acquireSem semaforo
          )
      wait consumidor
    ```

    #section-gap

    ```haskell
    tomarComida :: TVar Barra -> STM ()
    tomarComida barra = do
      b <- readTVar barra
      let g = cantidadGrandes b
          c = cantidadChicas b
      check (g > 0 || c > 1)
      case () of
        _ | g > 0 ->
              writeTVar barra (Barra c (g - 1))
          | c > 1 ->
              writeTVar barra (Barra (c - 2) g)
          | otherwise -> retry
    ```

    #section-gap

    ```haskell
    data Cola a = Cola (TVar [a])
    encolar :: Cola a -> a -> STM ()
    encolar (Cola ref) e = do
      xs <- readTVar ref
      writeTVar ref (xs ++ [e])
    desencolar :: Cola a -> STM a
    desencolar (Cola ref) = do
      xs <- readTVar ref
      case xs of
        [] -> retry
        e:resto -> do
          writeTVar ref resto
          return e
    encolarDesencolar :: Cola a -> Cola a -> IO ()
    encolarDesencolar destino origen =
      atomically $ do
        e <- desencolar origen
        encolar destino e
    ```

    #section-gap

    Si `fila` es una lista de TVars de booleanos (`[TVar Bool]`),
    `mapM readTVar` las lee todas dentro de STM y obtiene una lista común
    de booleanos: `estados :: [Bool]`.
    ```haskell
    estados <- mapM readTVar fila
    ```
]

// Medir primero el contenido permite usar sólo la altura necesaria.
#layout(size => {
  let column-width = (size.width - 8pt) / 2
  let column-height = calc.max(
    measure(left-column, width: column-width).height,
    measure(right-column, width: column-width).height,
  )
  grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    align: top,
    block(height: column-height, left-column),
    block(height: column-height, right-column),
  )
})
