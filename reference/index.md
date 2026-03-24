# Package index

## Graphs

Graph schemas, constructors, and accessors

- [`Graph()`](https://catrgory.github.io/catlab/reference/Graph.md) :
  Create a directed graph
- [`LabelledGraph()`](https://catrgory.github.io/catlab/reference/LabelledGraph.md)
  : Create a labelled graph
- [`WeightedGraph()`](https://catrgory.github.io/catlab/reference/WeightedGraph.md)
  : Create a weighted graph
- [`SchGraph`](https://catrgory.github.io/catlab/reference/SchGraph.md)
  : Directed graph schema: V (vertices), E (edges), src, tgt
- [`SchLabelledGraph`](https://catrgory.github.io/catlab/reference/SchLabelledGraph.md)
  : Labelled graph schema (vertex and edge labels)
- [`SchReflexiveGraph`](https://catrgory.github.io/catlab/reference/SchReflexiveGraph.md)
  : Reflexive graph schema: adds refl : V → E
- [`SchSymmetricGraph`](https://catrgory.github.io/catlab/reference/SchSymmetricGraph.md)
  : Symmetric graph schema: adds inv : E → E (edge involution)
- [`SchWeightedGraph`](https://catrgory.github.io/catlab/reference/SchWeightedGraph.md)
  : Weighted graph schema
- [`add_edge()`](https://catrgory.github.io/catlab/reference/add_edge.md)
  : Add an edge from s to t
- [`add_vertex()`](https://catrgory.github.io/catlab/reference/add_vertex.md)
  : Add a vertex, returning its ID
- [`add_vertices()`](https://catrgory.github.io/catlab/reference/add_vertices.md)
  : Add multiple vertices
- [`complete_graph()`](https://catrgory.github.io/catlab/reference/complete_graph.md)
  : Complete graph on n vertices
- [`cycle_graph()`](https://catrgory.github.io/catlab/reference/cycle_graph.md)
  : Cycle graph: 1 → 2 → ... → n → 1
- [`path_graph()`](https://catrgory.github.io/catlab/reference/path_graph.md)
  : Path graph: 1 → 2 → ... → n
- [`edge_src()`](https://catrgory.github.io/catlab/reference/edge_src.md)
  : Source of edge(s)
- [`edge_tgt()`](https://catrgory.github.io/catlab/reference/edge_tgt.md)
  : Target of edge(s)
- [`ne()`](https://catrgory.github.io/catlab/reference/ne.md) : Number
  of edges
- [`neighbors()`](https://catrgory.github.io/catlab/reference/neighbors.md)
  : Neighbors of vertex v
- [`nv()`](https://catrgory.github.io/catlab/reference/nv.md) : Number
  of vertices

## Limits & Colimits

Categorical limits, colimits, and universal constructions

- [`product()`](https://catrgory.github.io/catlab/reference/product.md)
  : Product (categorical product) of two ACSets
- [`coproduct()`](https://catrgory.github.io/catlab/reference/coproduct.md)
  : Coproduct (disjoint union) with injection morphisms
- [`pushout()`](https://catrgory.github.io/catlab/reference/pushout.md)
  : Pushout of ACSets along two morphisms from a common apex
- [`pullback()`](https://catrgory.github.io/catlab/reference/pullback.md)
  : Pullback of ACSets along a cospan
- [`equalizer()`](https://catrgory.github.io/catlab/reference/equalizer.md)
  : Equalizer of two parallel ACSet transformations
- [`coequalizer()`](https://catrgory.github.io/catlab/reference/coequalizer.md)
  : Coequalizer of two parallel ACSet transformations
- [`initial()`](https://catrgory.github.io/catlab/reference/initial.md)
  : Initial object: zero parts
- [`terminal()`](https://catrgory.github.io/catlab/reference/terminal.md)
  : Terminal object: exactly one part per object type
- [`from_initial()`](https://catrgory.github.io/catlab/reference/from_initial.md)
  : Unique morphism from initial object
- [`to_terminal()`](https://catrgory.github.io/catlab/reference/to_terminal.md)
  : Unique morphism to terminal object

## Graph Rewriting

Double-pushout and sesqui-pushout rewriting

- [`Rule()`](https://catrgory.github.io/catlab/reference/Rule.md)
  [`rule()`](https://catrgory.github.io/catlab/reference/Rule.md) :
  Rewriting rules
- [`rewrite()`](https://catrgory.github.io/catlab/reference/rewrite.md)
  : Apply a rule to a graph, finding the first valid match
- [`rewrite_match()`](https://catrgory.github.io/catlab/reference/rewrite_match.md)
  : Apply a rewrite rule at a specific match
- [`get_matches()`](https://catrgory.github.io/catlab/reference/get_matches.md)
  : Find all matches of a rule in a graph
- [`pushout_complement()`](https://catrgory.github.io/catlab/reference/pushout_complement.md)
  : Compute pushout complement (DPO step 1)
- [`final_pullback_complement()`](https://catrgory.github.io/catlab/reference/final_pullback_complement.md)
  : Compute the final pullback complement (FPC) for SqPO rewriting
- [`cascading_complement()`](https://catrgory.github.io/catlab/reference/cascading_complement.md)
  : Cascading deletion: compute subobject of G after removing matched
  elements

## Undirected Wiring Diagrams

Compositional interfaces via UWDs

- [`SchUWD`](https://catrgory.github.io/catlab/reference/SchUWD.md) :
  UWD Schema
- [`UWD()`](https://catrgory.github.io/catlab/reference/UWD.md)
  [`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md) :
  Undirected wiring diagrams
- [`relation()`](https://catrgory.github.io/catlab/reference/relation.md)
  : Create a wiring diagram using relation-style DSL
- [`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md)
  : Shorthand for creating a relation box spec
- [`nlegs()`](https://catrgory.github.io/catlab/reference/nlegs.md) :
  Get the number of legs (feet) of a structured cospan
- [`foot_sizes()`](https://catrgory.github.io/catlab/reference/foot_sizes.md)
  : Get the foot sizes of a structured cospan

## Data Migration

Functorial data migration between schemas

- [`delta_migrate()`](https://catrgory.github.io/catlab/reference/delta_migrate.md)
  : Perform delta (pullback) migration
- [`sigma_migrate()`](https://catrgory.github.io/catlab/reference/sigma_migrate.md)
  : Sigma (left pushforward) migration
- [`FinCat()`](https://catrgory.github.io/catlab/reference/FinCat.md) :
  Finite category (presented by an ACSet schema)
- [`FinFunctor()`](https://catrgory.github.io/catlab/reference/FinFunctor.md)
  : Functor between finite categories (schema morphism)

## Typed ACSets

ACSets typed over a base ACSet

- [`TypedACSet()`](https://catrgory.github.io/catlab/reference/TypedACSet.md)
  : Typed ACSet: an ACSet with a typing morphism to a type system
- [`typed_acset()`](https://catrgory.github.io/catlab/reference/typed_acset.md)
  : Create a typed ACSet
- [`typed_product()`](https://catrgory.github.io/catlab/reference/typed_product.md)
  : Typed product of typed ACSets
- [`typed_coproduct()`](https://catrgory.github.io/catlab/reference/typed_coproduct.md)
  : Typed coproduct of typed ACSets
- [`discrete_typed()`](https://catrgory.github.io/catlab/reference/discrete_typed.md)
  : Create a discrete typed ACSet from a type assignment
- [`flatten_typed()`](https://catrgory.github.io/catlab/reference/flatten_typed.md)
  : Flatten a typed ACSet (forget the typing)

## ACSet Transformations & Homomorphisms

Morphisms between ACSets

- [`ACSetTransformation()`](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)
  : ACSet transformation (natural transformation between ACSets)
- [`compose_transformations()`](https://catrgory.github.io/catlab/reference/compose_transformations.md)
  : Compose two ACSet transformations
- [`id_transformation()`](https://catrgory.github.io/catlab/reference/id_transformation.md)
  : Identity transformation
- [`is_natural()`](https://catrgory.github.io/catlab/reference/is_natural.md)
  : Check naturality of an ACSet transformation
- [`is_typed_morphism()`](https://catrgory.github.io/catlab/reference/is_typed_morphism.md)
  : Check if a morphism between typed ACSets preserves typing
- [`find_homomorphism()`](https://catrgory.github.io/catlab/reference/find_homomorphism.md)
  : Find a homomorphism between two ACSets
- [`find_all_homomorphisms()`](https://catrgory.github.io/catlab/reference/find_all_homomorphisms.md)
  : Find all homomorphisms between two ACSets
- [`is_homomorphic()`](https://catrgory.github.io/catlab/reference/is_homomorphic.md)
  : Check if a homomorphism exists
- [`discrete_acset()`](https://catrgory.github.io/catlab/reference/discrete_acset.md)
  : Create a discrete (empty) ACSet with n parts in a given object

## Structured Cospans

Open systems via structured cospans

- [`StructuredCospan()`](https://catrgory.github.io/catlab/reference/StructuredCospan.md)
  : Structured multicospan (open system with multiple legs/feet)
- [`structured_cospan()`](https://catrgory.github.io/catlab/reference/structured_cospan.md)
  : Create a structured cospan (open system)
- [`open_acset()`](https://catrgory.github.io/catlab/reference/open_acset.md)
  : Open an ACSet by specifying interface legs
- [`compose_cospans()`](https://catrgory.github.io/catlab/reference/compose_cospans.md)
  : Compose two structured cospans along a shared foot
- [`oapply_cospans()`](https://catrgory.github.io/catlab/reference/oapply_cospans.md)
  : Compose a list of structured cospans via a UWD
- [`otimes_cospans()`](https://catrgory.github.io/catlab/reference/otimes_cospans.md)
  : Monoidal product of two structured cospans (side-by-side)
- [`cospan_apex()`](https://catrgory.github.io/catlab/reference/cospan_apex.md)
  : Extract the apex from a structured cospan
- [`make_leg()`](https://catrgory.github.io/catlab/reference/make_leg.md)
  : Create a leg morphism from a discrete foot into an apex

## Visualization

Graphviz DOT output for graphs and diagrams

- [`to_dot()`](https://catrgory.github.io/catlab/reference/to_dot.md) :
  Convert an ACSet to DOT format string
- [`to_graphviz()`](https://catrgory.github.io/catlab/reference/to_graphviz.md)
  : Render an ACSet as an interactive diagram via DiagrammeR
- [`generic_to_dot()`](https://catrgory.github.io/catlab/reference/generic_to_dot.md)
  : Convert an arbitrary ACSet to DOT format
- [`graph_to_dot()`](https://catrgory.github.io/catlab/reference/graph_to_dot.md)
  : Convert a graph ACSet to DOT format
- [`uwd_to_dot()`](https://catrgory.github.io/catlab/reference/uwd_to_dot.md)
  : Render a UWD as a DOT diagram
- [`petri_to_dot()`](https://catrgory.github.io/catlab/reference/petri_to_dot.md)
  : Render a Petri net as a bipartite DOT graph
