// Guía 7: sistemas de transiciones etiquetadas (LTS).
#set par(leading: 0.2em, spacing: 0.4em)

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  align: top,
  [
    *Ejemplo composición*

    #align(center)[
      #image("images/lts-lock.svg", width: 120pt)
      #v(2pt)
      #image("images/lts-componentes.svg", width: 95%)
      #v(2pt)
      #image("images/lts-composicion.svg", width: 75%)
    ]

    #text(size: 7.5pt)[
      #table(
        columns: (0.95fr, 1.85fr, 1.85fr),
        inset: (x: 2pt, y: 3pt),
        stroke: 0.3pt + gray,
        align: left + top,
        table.header([], [*Safety*], [*Liveness*]),
        [*Qué dice*],
        [Nunca pasa algo malo.],
        [Algo bueno termina pasando.],
        [*Formas típicas*],
        [$□ ¬ italic("bad")$, $□ (p → □ q)$,
          $phi thin upright(bold(W)) thin psi$],
        [$◇ p$, $□ ◇ p$, $□ (p → ◇ q)$],
        [*Contraejemplo*],
        [Un *prefijo finito*, es decir, un camino desde el estado inicial
          hasta lo malo. Cómo siga después no importa.],
        [Un *lazo*, es decir, un camino hasta un ciclo, y el ciclo repetido
          para siempre, sin que pase lo bueno. Un estado sin salidas cuenta
          como un ciclo de largo uno.],
        [*Para demostrarla*],
        [Para $□ ¬ italic("bad")$, recorremos los estados alcanzables y
          vemos que en ninguno vale $italic("bad")$.],
        [Vemos que no hay ningún lazo que evite lo bueno. Para $□ ◇ p$,
          todo ciclo alcanzable, y todo estado sin salidas, tiene algún
          estado donde vale $p$.],
        [*Fair choice*],
        [No cambia nada. Un prefijo malo se puede continuar de forma justa.],
        [Solo cuentan los lazos justos, es decir, los que dan vueltas por
          una componente terminal entera. Para $□ ◇ p$, vale si toda
          componente terminal alcanzable tiene algún estado donde vale $p$.],
      )
    ]
  ],
  [
    *Siguiente.* $sigma, i ⊨ ○ phi$ si $sigma, i + 1 ⊨ phi$.
    Mira exactamente una posición adelante.

    *Eventualmente.* $sigma, i ⊨ ◇ phi$ si existe $j ≥ i$ con
    $sigma, j ⊨ phi$. Ojo con el $≥$, porque _incluye la posición actual_.

    *Siempre.* $sigma, i ⊨ □ phi$ si para todo $j ≥ i$ vale
    $sigma, j ⊨ phi$. También incluye la posición actual.

    *Hasta.* $sigma, i ⊨ phi thin upright(bold(U)) thin psi$ si existe $k ≥ i$ con
    $sigma, k ⊨ psi$, y para todo $j$ con $i ≤ j < k$ vale
    $sigma, j ⊨ phi$. En castellano, $psi$ ocurre en algún momento, y hasta
    entonces (sin incluirlo) vale $phi$.

    *Hasta débil.* $sigma, i ⊨ phi thin upright(bold(W)) thin psi$ si vale
    $sigma, i ⊨ phi thin upright(bold(U)) thin psi$, o si para todo $j ≥ i$ vale
    $sigma, j ⊨ phi$. Escrito con los operadores que ya tenemos:
    $ phi thin upright(bold(W)) thin psi ≡ (phi thin upright(bold(U)) thin psi) ∨ □ phi $
    En castellano, $phi$ vale hasta que ocurra $psi$, _si es que ocurre_.
    Si $psi$ no llega nunca, alcanza con que $phi$ valga para siempre.

    *Fórmulas útiles*

    - $□ ◇ p$: “siempre, eventualmente $p$”. Desde cualquier posición hay
      un $p$ más adelante. Es decir, $p$ *ocurre infinitas veces*.
    - $◇ □ p$: “eventualmente, siempre $p$”. A partir de algún momento,
      $p$ vale para siempre. $p$ *se estabiliza*.
    - $□ (p → ◇ q)$: *respuesta*. Cada vez que vale $p$, en ese momento
      o después vale $q$.
    - $□ (p → □ q)$: una vez que vale $p$, $q$ vale para siempre.

    *Dualidades.* La negación atraviesa los operadores cambiándolos:
    $ ¬ ○ phi ≡ ○ ¬ phi quad ¬ ◇ phi ≡ □ ¬ phi quad ¬ □ phi ≡ ◇ ¬ phi $

    *Distribución.* $□$ distribuye sobre $∧$ y $◇$ distribuye sobre $∨$:
    $ □ (phi ∧ psi) ≡ □ phi ∧ □ psi quad ◇ (phi ∨ psi) ≡ ◇ phi ∨ ◇ psi $

    *En el próximo:* la próxima vez que vale $psi$, también vale $phi$.
    #box[$phi thin upright(bold(N)) thin psi ≡ ¬ psi thin upright(bold(W)) thin (phi ∧ psi)$].

    *Mientras:* $phi$ vale al menos mientras valga $psi$.
    #box[$phi thin upright(bold(M)) thin psi ≡ phi thin upright(bold(W)) thin ¬ psi$].

    *Antes:* si $psi$ vale alguna vez, $phi$ vale antes de su primera
    aparición (estrictamente antes).
    #box[$phi thin upright(bold(B)) thin psi ≡ ¬ psi thin upright(bold(W)) thin (phi ∧ ¬ psi)$].

    *Con fair choice vale:* Toda ejecución justa termina en una componente
    terminal y la recorre entera infinitas veces. Como la única es el LTS
    completo, la ejecución pasa infinitas veces por CRITICAL, es decir,
    vale $□ ◇ upright("CRITICAL")$. Entonces, desde cualquier posición
    (en particular desde las que valen TRYING) hay un CRITICAL más adelante,
    y $□ (upright("TRYING") → ◇ upright("CRITICAL"))$ vale.

    Para LTL los estados van a ser: $upright("noncritical")_i$,
    $upright("wait")_i$, $upright("critical")_i$ y $upright("release")_i$.

    *Exclusión mutua:*
    $□ ¬ (upright("critical")_0 ∧ upright("critical")_1)$.

    *Ausencia de inanición:*
    $□ ◇ upright("critical")_0 ∧ □ ◇ upright("critical")_1$.

    *Ausencia de deadlock* (dos alternativas para este modelo):
    + Si algún thread espera, eventualmente alguno entra a la sección crítica:
      $ □ ((upright("wait")_0 ∨ upright("wait")_1) → ◇ (upright("critical")_0 ∨ upright("critical")_1)) $
    + No ocurre que, desde algún momento, ambos threads queden en espera
      para siempre:
      $ ¬ ◇ □ (upright("wait")_0 ∧ upright("wait")_1) $
  ],
)
