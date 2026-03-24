# Data Migration with Functors

## Introduction

In applied category theory, a **schema** is a small category that
describes the shape of data — the types of entities and the
relationships between them. A **database instance** (or dataset) on a
schema $\mathcal{C}$ is a set-valued functor
$\left. X:\mathcal{C}\rightarrow{\mathbf{S}\mathbf{e}\mathbf{t}} \right.$,
assigning a set of rows to each entity type and a function to each
relationship.

In the `catlab` package, schemas are represented as `BasicSchema`
objects and instances are `ACSet`s (attributed C-sets). A **schema
morphism** — a functor
$\left. F:\mathcal{C}\rightarrow\mathcal{D} \right.$ between schemas —
induces **data migration** functors that systematically transform data
from one schema to another:

- **Delta migration** ($\Delta_{F}$): pulls data *back* along $F$
  (pullback / precomposition)
- **Sigma migration** ($\Sigma_{F}$): pushes data *forward* along $F$
  (left Kan extension)

These operations are adjoint: $\Sigma_{F} \dashv \Delta_{F}$. Together
they provide a principled, compositional framework for data
transformation that goes far beyond ad-hoc ETL scripts.

``` r
library(catlab)
library(acsets)
#> 
#> Attaching package: 'acsets'
#> The following object is masked from 'package:graphics':
#> 
#>     arrows
#> The following object is masked from 'package:base':
#> 
#>     objects
```

## Schemas, categories, and functors

A `BasicSchema` declares objects (entity types), homs (foreign keys),
and optionally attribute types and attributes. Wrapping a schema in
[`FinCat()`](https://catrgory.github.io/catlab/reference/FinCat.md)
treats it as a finite category;
[`FinFunctor()`](https://catrgory.github.io/catlab/reference/FinFunctor.md)
creates a structure-preserving map between two such categories.

``` r
# The standard directed-graph schema
SchGraph
#> <acsets::BasicSchema>
#>  @ obs      : chr [1:2] "V" "E"
#>  @ homs     :List of 2
#>  .. $ :List of 3
#>  ..  ..$ name : chr "src"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "tgt"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  @ attrtypes: chr(0) 
#>  @ attrs    : list()
cat("Objects:", objects(SchGraph), "\n")
#> Objects: V E
cat("Homs:\n")
#> Homs:
for (h in homs(SchGraph)) {
  cat(sprintf("  %s : %s -> %s\n", h$name, h$dom, h$codom))
}
#>   src : E -> V
#>   tgt : E -> V
```

A functor $\left. F:\mathcal{C}\rightarrow\mathcal{D} \right.$ is
specified by:

- `ob_map`: a named list sending each object of $\mathcal{C}$ to an
  object of $\mathcal{D}$
- `hom_map`: a named list sending each hom (and attribute) of
  $\mathcal{C}$ to a hom (or attribute) of $\mathcal{D}$

The functor must preserve the source/target structure of morphisms.

## Delta migration (pullback)

Given a functor $\left. F:\mathcal{C}\rightarrow\mathcal{D} \right.$ and
a $\mathcal{D}$-set $X$, the **delta migration** $\Delta_{F}(X)$ is the
$\mathcal{C}$-set defined by precomposition:
$\Delta_{F}(X) = X \circ F$.

Concretely:

- For each object $c$ in $\mathcal{C}$, the set of parts is
  $\Delta_{F}(X)(c) = X\left( F(c) \right)$
- For each hom $\left. h:c_{1}\rightarrow c_{2} \right.$ in
  $\mathcal{C}$, the function is
  $\Delta_{F}(X)(h) = X\left( F(h) \right)$

Delta migration is the most intuitive operation: it *renames and
reorganises* data by reinterpreting the same underlying tables through a
different lens.

### Example 1: Reversing a graph

The simplest non-trivial delta migration swaps the `src` and `tgt` homs
of a graph, reversing every edge.

``` r
# Functor F : SchGraph → SchGraph that swaps src and tgt
cat_G <- FinCat(schema = SchGraph)
F_rev <- FinFunctor(
  ob_map  = list(V = "V", E = "E"),
  hom_map = list(src = "tgt", tgt = "src"),
  dom = cat_G, codom = cat_G
)

g <- path_graph(4)  # 1 → 2 → 3 → 4
cat("Original graph:\n")
#> Original graph:
cat("  src:", subpart(g, NULL, "src"), "\n")
#>   src: 1 2 3
cat("  tgt:", subpart(g, NULL, "tgt"), "\n")
#>   tgt: 2 3 4

GraphType <- acset_type(SchGraph)
g_rev <- delta_migrate(F_rev, g, GraphType)
cat("\nReversed graph (delta along F_rev):\n")
#> 
#> Reversed graph (delta along F_rev):
cat("  src:", subpart(g_rev, NULL, "src"), "\n")
#>   src: 2 3 4
cat("  tgt:", subpart(g_rev, NULL, "tgt"), "\n")
#>   tgt: 1 2 3
```

The reversed path graph has the same vertices and edges, but every arrow
points in the opposite direction:
$\left. 4\rightarrow 3\rightarrow 2\rightarrow 1 \right.$.

``` r
cat("Original DOT:\n")
#> Original DOT:
cat(to_dot(g))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   1 -> 2;
#>   2 -> 3;
#>   3 -> 4;
#> }
cat("\nReversed DOT:\n")
#> 
#> Reversed DOT:
cat(to_dot(g_rev))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   2 -> 1;
#>   3 -> 2;
#>   4 -> 3;
#> }
```

### Example 2: Extracting a substructure

Delta migration can project a richer schema onto a simpler one. Consider
a weighted graph — we can forget the weights by pulling back along the
inclusion of `SchGraph` into `SchWeightedGraph`.

``` r
# Functor embedding SchGraph into SchWeightedGraph
cat_plain <- FinCat(schema = SchGraph)
cat_wt    <- FinCat(schema = SchWeightedGraph)

F_incl <- FinFunctor(
  ob_map  = list(V = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt"),
  dom = cat_plain, codom = cat_wt
)

# A weighted graph: triangle with weights
wg <- WeightedGraph(
  V = 3, E = 3,
  src = c(1L, 2L, 3L), tgt = c(2L, 3L, 1L),
  weight = c(1.0, 2.5, 0.7)
)
cat("Weighted graph: V =", nparts(wg, "V"), ", E =", nparts(wg, "E"), "\n")
#> Weighted graph: V = 3 , E = 3
cat("  weights:", subpart(wg, NULL, "weight"), "\n")
#>   weights: 1 2.5 0.7

# Delta pulls back to a plain graph — weights are dropped
plain <- delta_migrate(F_incl, wg, GraphType)
cat("\nPlain graph (delta forgets weights):\n")
#> 
#> Plain graph (delta forgets weights):
cat("  V =", nparts(plain, "V"), ", E =", nparts(plain, "E"), "\n")
#>   V = 3 , E = 3
cat("  src:", subpart(plain, NULL, "src"), "\n")
#>   src: 1 2 3
cat("  tgt:", subpart(plain, NULL, "tgt"), "\n")
#>   tgt: 2 3 1
```

The structure (vertices, edges, source/target) is preserved exactly;
only the weight attribute — which has no preimage under $F$ — is
discarded.

## Sigma migration (left Kan extension)

Sigma migration is the left adjoint to delta. Given
$\left. F:\mathcal{C}\rightarrow\mathcal{D} \right.$ and a
$\mathcal{C}$-set $X$, the **sigma migration** $\Sigma_{F}(X)$ is a
$\mathcal{D}$-set computed by left Kan extension.

Concretely, for each object $d$ in $\mathcal{D}$:
$$\Sigma_{F}(X)(d) = \coprod\limits_{\{ c \in \mathcal{C} \mid F{(c)} = d\}}X(c)$$

Parts from different $\mathcal{C}$-objects that map to the same
$\mathcal{D}$-object are *combined* (coproduct = disjoint union). Hom
values are remapped through the part offsets.

Sigma migration *merges and combines* structure.

### Example 1: Merging two edge types

Suppose we model a graph with two kinds of edges (e.g., red and blue) as
separate object types $E_{1}$ and $E_{2}$, each with their own source
and target homs. We can merge them into a single edge type using sigma
migration.

``` r
# Domain schema: graph with two edge types
SchTwoEdgeGraph <- BasicSchema(
  obs = c("V", "E1", "E2"),
  homs = list(
    hom("src1", "E1", "V"), hom("tgt1", "E1", "V"),
    hom("src2", "E2", "V"), hom("tgt2", "E2", "V")
  ),
  attrtypes = character(0),
  attrs = list()
)

# Functor merging E1 and E2 into E
cat_two  <- FinCat(schema = SchTwoEdgeGraph)
cat_one  <- FinCat(schema = SchGraph)
F_merge <- FinFunctor(
  ob_map  = list(V = "V", E1 = "E", E2 = "E"),
  hom_map = list(src1 = "src", tgt1 = "tgt",
                 src2 = "src", tgt2 = "tgt"),
  dom = cat_two, codom = cat_one
)

# Source data: 4 vertices, 2 "red" edges, 1 "blue" edge
src_two <- ACSet(SchTwoEdgeGraph)
add_parts(src_two, "V", 4)
#> [1] 1 2 3 4
add_parts(src_two, "E1", 2)
#> [1] 1 2
set_subpart(src_two, 1L, "src1", 1L); set_subpart(src_two, 1L, "tgt1", 2L)
set_subpart(src_two, 2L, "src1", 2L); set_subpart(src_two, 2L, "tgt1", 3L)
add_parts(src_two, "E2", 1)
#> [1] 1
set_subpart(src_two, 1L, "src2", 3L); set_subpart(src_two, 1L, "tgt2", 4L)

cat("Two-edge-type graph:\n")
#> Two-edge-type graph:
cat("  V =", nparts(src_two, "V"), "\n")
#>   V = 4
cat("  E1 =", nparts(src_two, "E1"),
    " (src1:", subpart(src_two, NULL, "src1"),
    ", tgt1:", subpart(src_two, NULL, "tgt1"), ")\n")
#>   E1 = 2  (src1: 1 2 , tgt1: 2 3 )
cat("  E2 =", nparts(src_two, "E2"),
    " (src2:", subpart(src_two, NULL, "src2"),
    ", tgt2:", subpart(src_two, NULL, "tgt2"), ")\n")
#>   E2 = 1  (src2: 3 , tgt2: 4 )

# Sigma merges both edge types into one
merged <- sigma_migrate(F_merge, src_two, GraphType)
cat("\nMerged graph (sigma):\n")
#> 
#> Merged graph (sigma):
cat("  V =", nparts(merged, "V"), ", E =", nparts(merged, "E"), "\n")
#>   V = 4 , E = 3
cat("  src:", subpart(merged, NULL, "src"), "\n")
#>   src: 1 2 3
cat("  tgt:", subpart(merged, NULL, "tgt"), "\n")
#>   tgt: 2 3 4
```

The 2 red edges and 1 blue edge are combined into 3 edges in the merged
graph, all sharing the same vertex set.

``` r
cat(to_dot(merged))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   1 -> 2;
#>   2 -> 3;
#>   3 -> 4;
#> }
```

### Example 2: Collapsing vertex types

Consider a bipartite-like schema with two vertex types ($V_{1}$ and
$V_{2}$) and edges only from $V_{1}$ to $V_{2}$. Sigma migration along a
functor that sends both vertex types to a single type $V$ collapses
them.

``` r
# Bipartite-ish schema
SchBipartite <- BasicSchema(
  obs = c("V1", "V2", "E"),
  homs = list(
    hom("src", "E", "V1"),
    hom("tgt", "E", "V2")
  ),
  attrtypes = character(0),
  attrs = list()
)

# Functor collapsing V1, V2 → V
cat_bip <- FinCat(schema = SchBipartite)
F_collapse <- FinFunctor(
  ob_map  = list(V1 = "V", V2 = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt"),
  dom = cat_bip, codom = cat_one
)

# Source: 2 left vertices, 3 right vertices, 3 edges
bip <- ACSet(SchBipartite)
add_parts(bip, "V1", 2)
#> [1] 1 2
add_parts(bip, "V2", 3)
#> [1] 1 2 3
add_parts(bip, "E", 3)
#> [1] 1 2 3
set_subpart(bip, 1L, "src", 1L); set_subpart(bip, 1L, "tgt", 1L)
set_subpart(bip, 2L, "src", 1L); set_subpart(bip, 2L, "tgt", 2L)
set_subpart(bip, 3L, "src", 2L); set_subpart(bip, 3L, "tgt", 3L)

cat("Bipartite source:\n")
#> Bipartite source:
cat("  V1 =", nparts(bip, "V1"), ", V2 =", nparts(bip, "V2"),
    ", E =", nparts(bip, "E"), "\n")
#>   V1 = 2 , V2 = 3 , E = 3

collapsed <- sigma_migrate(F_collapse, bip, GraphType)
cat("\nCollapsed graph (sigma):\n")
#> 
#> Collapsed graph (sigma):
cat("  V =", nparts(collapsed, "V"), "(= 2 + 3), E =", nparts(collapsed, "E"), "\n")
#>   V = 5 (= 2 + 3), E = 3
cat("  src:", subpart(collapsed, NULL, "src"), "\n")
#>   src: 1 1 2
cat("  tgt:", subpart(collapsed, NULL, "tgt"), "\n")
#>   tgt: 3 4 5
```

The 2 vertices from $V_{1}$ become vertices 1–2 and the 3 from $V_{2}$
become vertices 3–5 in the result. Edge targets are shifted accordingly:
original target 1 in $V_{2}$ becomes vertex 3 (= 2 + 1), etc.

``` r
cat(to_dot(collapsed))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   5;
#>   1 -> 3;
#>   1 -> 4;
#>   2 -> 5;
#> }
```

## Schema evolution

A common practical pattern is **schema evolution**: an existing schema
changes (new fields, renamed entities, restructured relationships) and
data must be migrated from the old schema to the new one. Functors
provide a principled way to do this.

### Evolving a labelled graph schema

Suppose we start with a schema where edges carry a `label` attribute,
and evolve to a schema where both vertices and edges carry labels.

``` r
# Old schema: only edge labels
SchOld <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = "Label",
  attrs = list(attr_spec("elabel", "E", "Label"))
)

# New schema: vertex and edge labels (= SchLabelledGraph)
SchNew <- SchLabelledGraph  # has vlabel and elabel

cat("Old schema attrs:\n")
#> Old schema attrs:
for (a in attrs(SchOld)) cat(sprintf("  %s : %s -> %s\n", a$name, a$dom, a$codom))
#>   elabel : E -> Label
cat("New schema attrs:\n")
#> New schema attrs:
for (a in attrs(SchNew)) cat(sprintf("  %s : %s -> %s\n", a$name, a$dom, a$codom))
#>   vlabel : V -> Label
#>   elabel : E -> Label
```

We define a functor from the old schema to the new schema. This
embedding maps each old entity/relationship to its counterpart in the
new schema.

``` r
cat_old <- FinCat(schema = SchOld)
cat_new <- FinCat(schema = SchNew)

# Old → New: embed the old schema into the new one
F_evolve <- FinFunctor(
  ob_map  = list(V = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt", elabel = "elabel"),
  dom = cat_old, codom = cat_new
)
```

### Migrating forward with sigma

Sigma migration pushes data from the old schema to the new schema.
Vertex labels (which didn’t exist in the old schema) are left unset.

``` r
# Old data
OldGraphType <- acset_type(SchOld)
old_data <- OldGraphType(
  V = 3, E = 2,
  src = c(1L, 2L), tgt = c(2L, 3L),
  elabel = c("knows", "likes")
)
cat("Old data: V =", nparts(old_data, "V"), ", E =", nparts(old_data, "E"), "\n")
#> Old data: V = 3 , E = 2
cat("  edge labels:", subpart(old_data, NULL, "elabel"), "\n")
#>   edge labels: knows likes

# Sigma: push forward to new schema
new_data <- sigma_migrate(F_evolve, old_data, LabelledGraph)
cat("\nNew data (sigma forward):\n")
#> 
#> New data (sigma forward):
cat("  V =", nparts(new_data, "V"), ", E =", nparts(new_data, "E"), "\n")
#>   V = 3 , E = 2
cat("  edge labels:", subpart(new_data, NULL, "elabel"), "\n")
#>   edge labels: knows likes
cat("  vertex labels:", subpart(new_data, NULL, "vlabel"), "\n")
#>   vertex labels: NA NA NA
```

The edge labels are preserved, vertices are carried over, and the new
`vlabel` attribute is `NA` (unset) — ready to be populated.

### Migrating backward with delta

Delta migration pulls data from the new schema back to the old schema.
The vertex labels are discarded since the old schema has no place for
them.

``` r
# Start with fully labelled data on the new schema
full_data <- LabelledGraph(
  V = 3, E = 2,
  src = c(1L, 2L), tgt = c(2L, 3L),
  vlabel = c("Alice", "Bob", "Carol"),
  elabel = c("knows", "likes")
)

# Delta: pull back to old schema
old_again <- delta_migrate(F_evolve, full_data, OldGraphType)
cat("Pulled back to old schema:\n")
#> Pulled back to old schema:
cat("  V =", nparts(old_again, "V"), ", E =", nparts(old_again, "E"), "\n")
#>   V = 3 , E = 2
cat("  edge labels:", subpart(old_again, NULL, "elabel"), "\n")
#>   edge labels: knows likes
# vlabel is gone — old schema doesn't have it
```

This illustrates the adjunction informally: sigma adds structure
(possibly leaving new fields empty), while delta forgets structure
(discarding fields without preimages).

## Composing migrations

Because data migration is functorial, composing functors composes the
corresponding migrations. If
$\left. F:\mathcal{A}\rightarrow\mathcal{B} \right.$ and
$\left. G:\mathcal{B}\rightarrow\mathcal{C} \right.$ are schema
morphisms, then:

$$\Delta_{G \circ F} = \Delta_{F} \circ \Delta_{G}$$

That is, pulling back along a composite functor is the same as pulling
back along $G$ first, then along $F$. (Note the reversal of order —
contravariance of delta.)

For sigma, the order is preserved:
$$\Sigma_{G \circ F} = \Sigma_{G} \circ \Sigma_{F}$$

### Demonstrating composition with delta

We compose two graph endofunctors — reversing edges, then reversing
again — which should recover the original graph.

``` r
# F_rev swaps src ↔ tgt (defined earlier)
g <- path_graph(3)  # 1 → 2 → 3
cat("Original: src =", subpart(g, NULL, "src"),
    ", tgt =", subpart(g, NULL, "tgt"), "\n")
#> Original: src = 1 2 , tgt = 2 3

# Apply F_rev twice via delta
g_rev1 <- delta_migrate(F_rev, g, GraphType)
g_rev2 <- delta_migrate(F_rev, g_rev1, GraphType)
cat("After two reversals: src =", subpart(g_rev2, NULL, "src"),
    ", tgt =", subpart(g_rev2, NULL, "tgt"), "\n")
#> After two reversals: src = 1 2 , tgt = 2 3
```

Two reversals return us to the original, as expected:
$\Delta_{F_{\text{rev}}}\left( \Delta_{F_{\text{rev}}}(G) \right) = G$.

### Composing different functors

We can also chain *different* functors. Here we first merge two edge
types (sigma), then reverse the result (delta).

``` r
# Reuse the two-edge-type source from earlier
merged <- sigma_migrate(F_merge, src_two, GraphType)
reversed_merged <- delta_migrate(F_rev, merged, GraphType)

cat("Merged then reversed:\n")
#> Merged then reversed:
cat("  V =", nparts(reversed_merged, "V"),
    ", E =", nparts(reversed_merged, "E"), "\n")
#>   V = 4 , E = 3
cat("  src:", subpart(reversed_merged, NULL, "src"), "\n")
#>   src: 2 3 4
cat("  tgt:", subpart(reversed_merged, NULL, "tgt"), "\n")
#>   tgt: 1 2 3
```

## Practical example: converting between graph representations

To tie everything together, consider a practical scenario. A
collaborator models a contact network using a schema with separate
“friendship” and “professional” edge types. We need to:

1.  Merge both edge types into a single graph
2.  Reverse the edges (to model “influenced-by” rather than
    “influences”)
3.  Extract just the graph structure (dropping any attributes)

``` r
# Collaborator's schema: labelled vertices, two relationship types
SchContactNet <- BasicSchema(
  obs = c("Person", "Friendship", "Professional"),
  homs = list(
    hom("f_from", "Friendship", "Person"),
    hom("f_to",   "Friendship", "Person"),
    hom("p_from", "Professional", "Person"),
    hom("p_to",   "Professional", "Person")
  ),
  attrtypes = character(0),
  attrs = list()
)

# Sample data: 5 people, 3 friendships, 2 professional links
net <- ACSet(SchContactNet)
add_parts(net, "Person", 5)
#> [1] 1 2 3 4 5
add_parts(net, "Friendship", 3)
#> [1] 1 2 3
set_subpart(net, 1L, "f_from", 1L); set_subpart(net, 1L, "f_to", 2L)
set_subpart(net, 2L, "f_from", 2L); set_subpart(net, 2L, "f_to", 3L)
set_subpart(net, 3L, "f_from", 1L); set_subpart(net, 3L, "f_to", 4L)
add_parts(net, "Professional", 2)
#> [1] 1 2
set_subpart(net, 1L, "p_from", 3L); set_subpart(net, 1L, "p_to", 5L)
set_subpart(net, 2L, "p_from", 4L); set_subpart(net, 2L, "p_to", 5L)

cat("Contact network:\n")
#> Contact network:
cat("  People:", nparts(net, "Person"), "\n")
#>   People: 5
cat("  Friendships:", nparts(net, "Friendship"), "\n")
#>   Friendships: 3
cat("  Professional:", nparts(net, "Professional"), "\n")
#>   Professional: 2
```

**Step 1**: Define a functor to merge both relationship types into a
single edge type.

``` r
cat_contact <- FinCat(schema = SchContactNet)
cat_graph   <- FinCat(schema = SchGraph)

F_flatten <- FinFunctor(
  ob_map  = list(Person = "V", Friendship = "E", Professional = "E"),
  hom_map = list(f_from = "src", f_to = "tgt",
                 p_from = "src", p_to = "tgt"),
  dom = cat_contact, codom = cat_graph
)

flat <- sigma_migrate(F_flatten, net, GraphType)
cat("Flattened graph: V =", nparts(flat, "V"),
    ", E =", nparts(flat, "E"), "\n")
#> Flattened graph: V = 5 , E = 5
cat("  src:", subpart(flat, NULL, "src"), "\n")
#>   src: 1 2 1 3 4
cat("  tgt:", subpart(flat, NULL, "tgt"), "\n")
#>   tgt: 2 3 4 5 5
```

**Step 2**: Reverse all edges using delta migration.

``` r
influenced_by <- delta_migrate(F_rev, flat, GraphType)
cat("Reversed (influenced-by): \n")
#> Reversed (influenced-by):
cat("  src:", subpart(influenced_by, NULL, "src"), "\n")
#>   src: 2 3 4 5 5
cat("  tgt:", subpart(influenced_by, NULL, "tgt"), "\n")
#>   tgt: 1 2 1 3 4
```

**Step 3**: Visualise the result.

``` r
cat(to_dot(influenced_by))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   5;
#>   2 -> 1;
#>   3 -> 2;
#>   4 -> 1;
#>   5 -> 3;
#>   5 -> 4;
#> }
```

Each step is a clean, composable transformation — no manual index
juggling, no off-by-one errors, just functors and their induced data
migrations.

## Summary

| Operation            | Function                 | Direction                  | Effect                       |
|----------------------|--------------------------|----------------------------|------------------------------|
| Delta ($\Delta_{F}$) | `delta_migrate(F, X, T)` | Pulls *back* along $F$     | Rename / reorganise / forget |
| Sigma ($\Sigma_{F}$) | `sigma_migrate(F, X, T)` | Pushes *forward* along $F$ | Merge / combine / extend     |

Key properties:

- **Adjunction**: $\Sigma_{F} \dashv \Delta_{F}$ — sigma is left adjoint
  to delta
- **Compositionality**: Composing functors composes migrations —
  $\Delta_{G \circ F} = \Delta_{F} \circ \Delta_{G}$ and
  $\Sigma_{G \circ F} = \Sigma_{G} \circ \Sigma_{F}$
- **Correctness by construction**: The categorical framework guarantees
  that structural constraints are preserved

For limits, colimits, homomorphism finding, and graph rewriting, see the
companion vignette
[`vignette("algebra", package = "catlab")`](https://catrgory.github.io/catlab/articles/algebra.md).
