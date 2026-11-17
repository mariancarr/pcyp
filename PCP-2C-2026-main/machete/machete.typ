// Parcial PCP: dos carillas A4, con dos guías por carilla.
#set page(paper: "a4", margin: (x: 0mm, y: 0mm))
#set text(size: 8.5pt)

#set par(
  leading: 0.5em,
  spacing: 1em,
)

#let content-box(data, full-height: true) = (
  grid.cell(
    inset: (x: 16pt, top: 5mm, bottom: 2pt),
    block(
      width: 100%,
      height: if full-height { 100% } else { auto },
      data,
    ),
  ),
)

// Carilla 1: guía 5 arriba y guía 6 abajo.
#grid(
  columns: 1fr,
  rows: (auto, 1fr),
  ..content-box([#include "guía5.typ"], full-height: false),
  grid.hline(stroke: gray),
  ..content-box([#include "guía6.typ"]),
)

#pagebreak()

// Carilla 2: guía 7 arriba y guía 8 abajo.
#grid(
  columns: 1fr,
  rows: (auto, 1fr),
  ..content-box([#include "guía7.typ"], full-height: false),
  grid.hline(stroke: gray),
  ..content-box([#include "guía8.typ"]),
)
