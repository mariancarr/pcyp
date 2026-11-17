// Guía 8: paralelismo con Fork/Join.
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
    ```java
    task.fork()    // correr la tarea (eventualmente) en el pool
    task.join()    // espera a que termine y da el resultado
    task.compute() // hace el trabajo en el propio worker
    pool.invoke(t) // corre t en el pool y espera a que termine
    ```

    // Compactar las definiciones conserva lugar para el ejemplo de matrices.
    #set text(size: 8pt)
    #set par(leading: 0.15em, spacing: 0.2em)

    - *Work $T_1$:* la cantidad total de pasos. Es lo que tarda con un solo
      procesador.
    - *Span $T_∞$:* la longitud del camino más largo del DAG (el _camino
      crítico_). Es lo que tarda con infinitos procesadores.
    - *Speedup* (aceleración) con $P$ procesadores: $T_1 / T_P$.
    - *Paralelismo:* $T_1 / T_∞$. Es el speedup máximo posible.
    - Cuando dos partes van *en secuencia*, sus works se suman y sus spans
      también se suman.
    - Cuando van *en paralelo*, sus works se suman, pero el span es el
      máximo de los dos.
    - Así analizamos la suma y el producto de matrices en la teórica.

    - *Ley del work:* $T_P ≥ T_1 / P$. No se puede repartir mejor que
      en partes iguales.
    - *Ley del span:* $T_P ≥ T_∞$. No se puede ganarle al camino más largo.

    *Teorema (scheduler greedy).* Un scheduler _greedy_ (en cada paso
    ejecuta todo lo que esté listo, hasta $P$ cosas) tarda un tiempo
    $T_P^*$ que cumple: #box[$T_P^* ≤ T_1 / P + T_∞$].

    #block(above: 0pt, below: 0pt)[
      #set par(spacing: 0pt)
      *Cota scheduler greedy normal:* $T_P ≈ T_1 / P + T_∞$.

      *Cota scheduler greedy optimizada:* $T_P^* ≤ (T_1 - T_∞) / P + T_∞$.

      *Para cualquier scheduler*, valen las cotas inferiores:
      #box[$T_P ≥ max(T_1 / P, T_∞)$]. Ninguno puede superar esos límites
      físicos del cómputo.
    ]

    $ log_b(a) = log(a) / log(b) $

    ```java
    public class MatrixMulTask
        extends RecursiveAction {
      // umbral para hacer el producto a mano
      static final int THRESHOLD = ...;

      public void compute() {
        int n = lhs.getDim();
        if (n <= THRESHOLD) {
          Matrix.multiply(lhs, rhs, product);
        } else {
          List<MatrixMulTask> tasks = new ArrayList<>(8);
          Matrix[] term = new Matrix[]{
              new Matrix(n), new Matrix(n)};

          for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 2; j++) {
              for (int k = 0; k < 2; k++) {
                tasks.add(
                    new MatrixMulTask(
                        lhs.split(j, i), rhs.split(i, k),
                        term[i].split(j, k)));
              }
            }
          }

          tasks.stream().forEach((task) -> {task.fork();});
          tasks.stream().forEach((task) -> {task.join();});

          (new MatrixAddTask(term[0], term[1], product))
              .compute();
        }
      }
    }
    ```
  ],
  [
    ```java
    import java.util.concurrent.ForkJoinPool;
    import java.util.concurrent.RecursiveTask;

    public class VectorSumTask
        extends RecursiveTask<Integer> {
      private final int[] vector;
      private final int left;
      private final int right;

      public VectorSumTask(
          int[] vector, int left, int right) {
        this.vector = vector;
        this.left = left;
        this.right = right;
      }

      @Override
      protected Integer compute() {
        int cantidad = right - left;
        if (cantidad == 2) {
          return vector[left] + vector[left + 1];
        }

        int middle = left + (right - left) / 2;
        VectorSumTask rightTask =
            new VectorSumTask(vector, middle, right);
        rightTask.fork();

        VectorSumTask leftTask =
            new VectorSumTask(vector, left, middle);

        return leftTask.compute() + rightTask.join();
      }
    }
    ```

    ```java
    class MaxSubArrayTask extends RecursiveTask<Integer> {
      int[] A;
      int lo;
      int hi;

      public MaxSubArrayTask(int[] A, int lo, int hi) {
        // setea los valores
      }

      protected Integer compute() {
        if (hi - lo == 1) {
          return A[lo];
        }

        int mid = (lo + hi) / 2;
        MaxSubArrayTask low =
            new MaxSubArrayTask(A, lo, mid);
        low.fork();

        int high =
            new MaxSubArrayTask(A, mid, hi).compute();

        // mejor sufijo de la parte baja
        int cruza = mejorSumaLineal(A, mid-1, lo-1)
            // mejor prefijo de la parte alta
            + mejorSumaLineal(A, mid, hi-1);

        return max(low.join(), high, cruza);
      }
    }
    ```
  ],
)
