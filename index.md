# catlab ![](reference/figures/logo.png)

An R port of core
[Catlab.jl](https://github.com/AlgebraicJulia/Catlab.jl) functionality —
**categorical algebra for applied category theory**. Provides
limits/colimits, graph rewriting (DPO/SPO/SqPO), undirected wiring
diagrams, data migration, typed ACSets, and structured cospans.

Built on top of the [acsets](https://github.com/catRgory/acsets)
package.

## Installation

Install from GitHub (requires the `acsets` dependency):

``` r
# install.packages("remotes")
remotes::install_github("catRgory/acsets")
remotes::install_github("catRgory/catlab")
```

## Quick example

``` r
library(catlab)

# Create two graphs and glue them along a shared vertex
g1 <- path_graph(3)   # 1 → 2 → 3
g2 <- path_graph(2)   # 1 → 2

# Identify vertex 3 of g1 with vertex 1 of g2
interface <- Graph()
add_vertex(interface)
f <- ACSetTransformation(list(V = 3L, E = integer(0)), interface, g1)
g <- ACSetTransformation(list(V = 1L, E = integer(0)), interface, g2)
result <- pushout(f, g)
nv(result$pushout)  # 4 vertices: the two paths joined end-to-end
ne(result$pushout)  # 3 edges

# DPO graph rewriting: add an edge between two vertices
I <- Graph(); add_vertices(I, 2)
L <- Graph(); add_vertices(L, 2)
R <- path_graph(2)  # 1 → 2
l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
add_edge_rule <- rule(l, r)

triangle <- cycle_graph(3)
result <- rewrite(add_edge_rule, triangle)
ne(result)  # 4 edges (added one to the triangle)
```

## Features

- **Graphs** — Directed, symmetric, reflexive, weighted, and labelled
  graph schemas with constructors (`path_graph`, `cycle_graph`,
  `complete_graph`) and query functions (`nv`, `ne`, `neighbors`)
- **Finite categories & functors** — `FinCat`, `FinFunctor`, and
  `ACSetTransformation` with naturality checking
- **Limits & colimits** — `product`, `pullback`, `equalizer`,
  `coproduct`, `pushout`, `coequalizer`, plus `terminal`/`initial`
  objects
- **Homomorphism search** — Backtracking search for graph homomorphisms
  (`find_homomorphism`, `find_all_homomorphisms`, `is_homomorphic`) with
  monic and initial-match support
- **Graph rewriting** — DPO, SPO, and SqPO semantics via
  [`rule()`](https://catrgory.github.io/catlab/reference/Rule.md),
  [`rewrite()`](https://catrgory.github.io/catlab/reference/rewrite.md),
  [`get_matches()`](https://catrgory.github.io/catlab/reference/get_matches.md),
  and
  [`rewrite_match()`](https://catrgory.github.io/catlab/reference/rewrite_match.md)
- **Data migration** — Pull back (`delta_migrate`) and push forward
  (`sigma_migrate`) data along schema functors
- **Undirected wiring diagrams** — Compositional system specification
  with a concise DSL
  ([`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md),
  [`relation()`](https://catrgory.github.io/catlab/reference/relation.md))
- **Typed ACSets** — Type-stratified graphs with `typed_product`
  (pullback over types) and `typed_coproduct`
- **Structured cospans** — Open systems with interfaces; compose via
  `compose_cospans`, `otimes_cospans`, and `oapply_cospans`
- **Visualization** — Graphviz/DOT output for graphs, Petri nets, and
  UWDs via
  [`to_dot()`](https://catrgory.github.io/catlab/reference/to_dot.md) /
  [`to_graphviz()`](https://catrgory.github.io/catlab/reference/to_graphviz.md)

## Vignettes

Detailed tutorials are available as package vignettes: - [Limits,
colimits, and graph
rewriting](https://catrgory.github.io/catlab/articles/algebra.html) —
terminal/initial objects, products, coproducts, pushouts, pullbacks,
equalizers, coequalizers - [Graphs and
visualization](https://catrgory.github.io/catlab/articles/graphs.html) —
graph schemas, constructors, homomorphisms, DOT rendering - [Undirected
wiring diagrams](https://catrgory.github.io/catlab/articles/uwd.html) —
composing open systems via shared variables (SIR, SEIR, Lotka–Volterra
examples) - [Data migration with
functors](https://catrgory.github.io/catlab/articles/migration.html) —
delta/sigma migration for schema evolution and data transformation -
[Graph rewriting: DPO, SPO, and
SqPO](https://catrgory.github.io/catlab/articles/rewriting.html) —
algebraic graph transformation with gluing conditions - [Open systems
and typed
ACSets](https://catrgory.github.io/catlab/articles/open-systems.html) —
typed products, structured cospans, and UWD-directed composition

## Author

**Simon Frost** ([@sdwfrost](https://github.com/sdwfrost)) — [ORCID
0000-0002-5207-9879](https://orcid.org/0000-0002-5207-9879)

## License

MIT — see [LICENSE](https://catrgory.github.io/catlab/LICENSE) for
details.

## Part of the catRgory ecosystem

`catlab` is part of [catRgory](https://github.com/catRgory), an R
ecosystem for applied category theory. It builds on: -
[acsets](https://github.com/catRgory/acsets) — Acyclic C-Sets (schemas,
instances, and morphisms)
