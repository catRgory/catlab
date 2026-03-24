# Changelog

## catlab 0.1.0

Initial CRAN release of catlab — categorical algebra tools for R,
porting key functionality from AlgebraicJulia’s Catlab.jl.

### Core features

- **Graph schemas and constructors** — `SchGraph`, `SchSymmetricGraph`,
  `SchReflexiveGraph`, `SchWeightedGraph`, `SchLabelledGraph`;
  convenience constructors
  [`Graph()`](https://catrgory.github.io/catlab/reference/Graph.md),
  [`WeightedGraph()`](https://catrgory.github.io/catlab/reference/WeightedGraph.md),
  [`LabelledGraph()`](https://catrgory.github.io/catlab/reference/LabelledGraph.md);
  graph generators
  [`path_graph()`](https://catrgory.github.io/catlab/reference/path_graph.md),
  [`cycle_graph()`](https://catrgory.github.io/catlab/reference/cycle_graph.md),
  [`complete_graph()`](https://catrgory.github.io/catlab/reference/complete_graph.md).

- **Finite categories and functors** — `FinCat`, `FinFunctor`, and
  `ACSetTransformation` S7 classes with naturality checking
  ([`is_natural()`](https://catrgory.github.io/catlab/reference/is_natural.md)),
  identity
  ([`id_transformation()`](https://catrgory.github.io/catlab/reference/id_transformation.md)),
  and composition
  ([`compose_transformations()`](https://catrgory.github.io/catlab/reference/compose_transformations.md)).

- **Limits and colimits of ACSets** —
  [`product()`](https://catrgory.github.io/catlab/reference/product.md),
  [`pullback()`](https://catrgory.github.io/catlab/reference/pullback.md),
  [`equalizer()`](https://catrgory.github.io/catlab/reference/equalizer.md),
  [`terminal()`](https://catrgory.github.io/catlab/reference/terminal.md),
  [`to_terminal()`](https://catrgory.github.io/catlab/reference/to_terminal.md)
  (limits);
  [`coproduct()`](https://catrgory.github.io/catlab/reference/coproduct.md),
  [`pushout()`](https://catrgory.github.io/catlab/reference/pushout.md),
  [`coequalizer()`](https://catrgory.github.io/catlab/reference/coequalizer.md),
  [`initial()`](https://catrgory.github.io/catlab/reference/initial.md),
  [`from_initial()`](https://catrgory.github.io/catlab/reference/from_initial.md)
  (colimits).

- **Homomorphism search** — backtracking-based
  [`find_homomorphism()`](https://catrgory.github.io/catlab/reference/find_homomorphism.md),
  [`find_all_homomorphisms()`](https://catrgory.github.io/catlab/reference/find_all_homomorphisms.md),
  and
  [`is_homomorphic()`](https://catrgory.github.io/catlab/reference/is_homomorphic.md)
  with optional monic (injective) constraint.

- **Algebraic graph rewriting** — `Rule` /
  [`rule()`](https://catrgory.github.io/catlab/reference/Rule.md) for
  DPO (double pushout), SPO (single pushout), and SqPO (sesqui-pushout)
  semantics;
  [`rewrite()`](https://catrgory.github.io/catlab/reference/rewrite.md),
  [`rewrite_match()`](https://catrgory.github.io/catlab/reference/rewrite_match.md),
  [`get_matches()`](https://catrgory.github.io/catlab/reference/get_matches.md);
  supporting primitives
  [`pushout_complement()`](https://catrgory.github.io/catlab/reference/pushout_complement.md),
  [`cascading_complement()`](https://catrgory.github.io/catlab/reference/cascading_complement.md),
  [`final_pullback_complement()`](https://catrgory.github.io/catlab/reference/final_pullback_complement.md).

- **Data migration** —
  [`delta_migrate()`](https://catrgory.github.io/catlab/reference/delta_migrate.md)
  (pullback migration) and
  [`sigma_migrate()`](https://catrgory.github.io/catlab/reference/sigma_migrate.md)
  (left Kan extension / pushforward) along schema functors.

- **Undirected wiring diagrams** — `SchUWD` schema,
  [`UWD()`](https://catrgory.github.io/catlab/reference/UWD.md)
  constructor,
  [`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md)
  convenience builder, and
  [`relation()`](https://catrgory.github.io/catlab/reference/relation.md)
  /
  [`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md)
  DSL.

- **Typed ACSets** — `TypedACSet` S7 class with
  [`typed_acset()`](https://catrgory.github.io/catlab/reference/typed_acset.md),
  [`typed_product()`](https://catrgory.github.io/catlab/reference/typed_product.md),
  [`typed_coproduct()`](https://catrgory.github.io/catlab/reference/typed_coproduct.md),
  [`flatten_typed()`](https://catrgory.github.io/catlab/reference/flatten_typed.md),
  [`is_typed_morphism()`](https://catrgory.github.io/catlab/reference/is_typed_morphism.md),
  [`discrete_typed()`](https://catrgory.github.io/catlab/reference/discrete_typed.md).

- **Structured cospans** — `StructuredCospan` S7 class with
  [`open_acset()`](https://catrgory.github.io/catlab/reference/open_acset.md),
  [`compose_cospans()`](https://catrgory.github.io/catlab/reference/compose_cospans.md),
  [`otimes_cospans()`](https://catrgory.github.io/catlab/reference/otimes_cospans.md),
  and
  [`oapply_cospans()`](https://catrgory.github.io/catlab/reference/oapply_cospans.md)
  for composing open systems via undirected wiring diagrams.

- **Graphviz output** —
  [`graph_to_dot()`](https://catrgory.github.io/catlab/reference/graph_to_dot.md),
  [`generic_to_dot()`](https://catrgory.github.io/catlab/reference/generic_to_dot.md),
  [`petri_to_dot()`](https://catrgory.github.io/catlab/reference/petri_to_dot.md),
  [`uwd_to_dot()`](https://catrgory.github.io/catlab/reference/uwd_to_dot.md)
  for DOT format;
  [`to_graphviz()`](https://catrgory.github.io/catlab/reference/to_graphviz.md)
  for interactive rendering via DiagrammeR.

### Infrastructure

- Built on the **S7** class system and the **acsets** package.
- 196 unit tests via testthat.
