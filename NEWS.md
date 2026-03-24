# catlab 0.1.0

Initial CRAN release of catlab — categorical algebra tools for R, porting
key functionality from AlgebraicJulia's Catlab.jl.

## Core features

* **Graph schemas and constructors** — `SchGraph`, `SchSymmetricGraph`,
  `SchReflexiveGraph`, `SchWeightedGraph`, `SchLabelledGraph`; convenience
  constructors `Graph()`, `WeightedGraph()`, `LabelledGraph()`; graph generators
  `path_graph()`, `cycle_graph()`, `complete_graph()`.

* **Finite categories and functors** — `FinCat`, `FinFunctor`, and
  `ACSetTransformation` S7 classes with naturality checking (`is_natural()`),
  identity (`id_transformation()`), and composition
  (`compose_transformations()`).

* **Limits and colimits of ACSets** — `product()`, `pullback()`,
  `equalizer()`, `terminal()`, `to_terminal()` (limits); `coproduct()`,
  `pushout()`, `coequalizer()`, `initial()`, `from_initial()` (colimits).

* **Homomorphism search** — backtracking-based `find_homomorphism()`,
  `find_all_homomorphisms()`, and `is_homomorphic()` with optional monic
  (injective) constraint.

* **Algebraic graph rewriting** — `Rule` / `rule()` for DPO (double pushout),
  SPO (single pushout), and SqPO (sesqui-pushout) semantics; `rewrite()`,
  `rewrite_match()`, `get_matches()`; supporting primitives
  `pushout_complement()`, `cascading_complement()`,
  `final_pullback_complement()`.

* **Data migration** — `delta_migrate()` (pullback migration) and
  `sigma_migrate()` (left Kan extension / pushforward) along schema functors.

* **Undirected wiring diagrams** — `SchUWD` schema, `UWD()` constructor,
  `uwd()` convenience builder, and `relation()` / `box_spec()` DSL.

* **Typed ACSets** — `TypedACSet` S7 class with `typed_acset()`,
  `typed_product()`, `typed_coproduct()`, `flatten_typed()`,
  `is_typed_morphism()`, `discrete_typed()`.

* **Structured cospans** — `StructuredCospan` S7 class with `open_acset()`,
  `compose_cospans()`, `otimes_cospans()`, and `oapply_cospans()` for
  composing open systems via undirected wiring diagrams.

* **Graphviz output** — `graph_to_dot()`, `generic_to_dot()`, `petri_to_dot()`,
  `uwd_to_dot()` for DOT format; `to_graphviz()` for interactive rendering
  via DiagrammeR.

## Infrastructure

* Built on the **S7** class system and the **acsets** package.
* 196 unit tests via testthat.
