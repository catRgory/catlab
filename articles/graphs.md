# Graphs and Visualization in catlab

## Introduction

In category theory, a **graph** is not just a set of vertices and edges
— it is a *functor* from a small category (the **schema**) to the
category of finite sets. This functorial perspective, known as a
**C-set** (or copresheaf), gives graphs a precise algebraic structure
that supports powerful operations like homomorphism finding, limits,
colimits, and rewriting.

The `catlab` package implements graphs as **ACSets** (Attributed
C-Sets), built on the `acsets` package. This means every graph is an
instance of a schema, and operations on graphs are inherited from the
general ACSet machinery.

This vignette covers:

1.  Graph schemas and what they mean categorically
2.  Creating and manipulating graphs
3.  Graph generators
4.  Weighted and labelled graphs
5.  Visualization with DOT format
6.  Graph homomorphisms as ACSet transformations
7.  Defining custom graph schemas

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

## Graph schemas

A graph schema describes the *shape* of graph data. The simplest
directed graph schema, `SchGraph`, has:

- Two **objects**: `V` (vertices) and `E` (edges)
- Two **morphisms** (homs): `src : E → V` and `tgt : E → V`

Categorically, this is the free category on the diagram
$E\underset{tgt}{\overset{src}{\rightrightarrows}}V$. A graph is then a
*functor* from this category to **Set**, assigning a finite set to each
object and a function to each morphism.

``` r
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
```

We can inspect the schema programmatically:

``` r
cat("Objects:", objects(SchGraph), "\n")
#> Objects: V E
for (h in homs(SchGraph)) {
  cat("  Hom:", h$name, ":", h$dom, "->", h$codom, "\n")
}
#>   Hom: src : E -> V 
#>   Hom: tgt : E -> V
```

The `catlab` package provides several built-in graph schemas:

| Schema              | Extra structure                            | Description                  |
|---------------------|--------------------------------------------|------------------------------|
| `SchGraph`          | —                                          | Directed graph               |
| `SchSymmetricGraph` | `inv : E → E`                              | Undirected (edge involution) |
| `SchReflexiveGraph` | `refl : V → E`                             | Self-loops at every vertex   |
| `SchWeightedGraph`  | `weight : E → Weight`                      | Numeric edge weights         |
| `SchLabelledGraph`  | `vlabel : V → Label`, `elabel : E → Label` | Vertex and edge labels       |

``` r
SchWeightedGraph
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
#>  @ attrtypes: chr "Weight"
#>  @ attrs    :List of 1
#>  .. $ :List of 3
#>  ..  ..$ name : chr "weight"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "Weight"
```

``` r
SchLabelledGraph
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
#>  @ attrtypes: chr "Label"
#>  @ attrs    :List of 2
#>  .. $ :List of 3
#>  ..  ..$ name : chr "vlabel"
#>  ..  ..$ dom  : chr "V"
#>  ..  ..$ codom: chr "Label"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "elabel"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "Label"
```

The symmetric graph adds an involution morphism `inv : E → E` that pairs
each edge with its reverse:

``` r
SchSymmetricGraph
#> <acsets::BasicSchema>
#>  @ obs      : chr [1:2] "V" "E"
#>  @ homs     :List of 3
#>  .. $ :List of 3
#>  ..  ..$ name : chr "src"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "tgt"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "inv"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "E"
#>  @ attrtypes: chr(0) 
#>  @ attrs    : list()
```

The reflexive graph adds a morphism `refl : V → E` assigning a
distinguished self-loop to each vertex:

``` r
SchReflexiveGraph
#> <acsets::BasicSchema>
#>  @ obs      : chr [1:2] "V" "E"
#>  @ homs     :List of 3
#>  .. $ :List of 3
#>  ..  ..$ name : chr "src"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "tgt"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "refl"
#>  ..  ..$ dom  : chr "V"
#>  ..  ..$ codom: chr "E"
#>  @ attrtypes: chr(0) 
#>  @ attrs    : list()
```

## Creating graphs

### Using the constructor with initial data

The [`Graph()`](https://catrgory.github.io/catlab/reference/Graph.md)
constructor creates an ACSet with the `SchGraph` schema. You can specify
the number of vertices and edges, along with the `src` and `tgt`
morphism values:

``` r
# A path: 1 → 2 → 3 → 4
g <- Graph(V = 4, E = 3, src = c(1L, 2L, 3L), tgt = c(2L, 3L, 4L))
cat("Vertices:", nv(g), "\n")
#> Vertices: 4
cat("Edges:", ne(g), "\n")
#> Edges: 3
cat("Sources:", edge_src(g), "\n")
#> Sources: 1 2 3
cat("Targets:", edge_tgt(g), "\n")
#> Targets: 2 3 4
```

### Building a graph incrementally

You can also build a graph step by step using
[`add_vertex()`](https://catrgory.github.io/catlab/reference/add_vertex.md),
[`add_vertices()`](https://catrgory.github.io/catlab/reference/add_vertices.md),
and
[`add_edge()`](https://catrgory.github.io/catlab/reference/add_edge.md).
Each function mutates the graph in place and returns the new part ID(s):

``` r
g <- Graph()

# Add vertices one at a time
v1 <- add_vertex(g)
v2 <- add_vertex(g)
v3 <- add_vertex(g)
cat("Added vertices:", v1, v2, v3, "\n")
#> Added vertices: 1 2 3

# Add vertices in bulk
new_ids <- add_vertices(g, 2)
cat("Bulk vertex IDs:", new_ids, "\n")
#> Bulk vertex IDs: 4 5

# Add directed edges
e1 <- add_edge(g, 1, 2)
e2 <- add_edge(g, 2, 3)
e3 <- add_edge(g, 3, 1)
cat("Triangle edges:", e1, e2, e3, "\n")
#> Triangle edges: 1 2 3

cat("Final graph: V =", nv(g), ", E =", ne(g), "\n")
#> Final graph: V = 5 , E = 3
```

## Graph helpers

The `catlab` package provides convenience functions for querying graphs:

``` r
g <- Graph(V = 4, E = 4,
           src = c(1L, 2L, 3L, 1L),
           tgt = c(2L, 3L, 1L, 4L))

cat("Number of vertices:", nv(g), "\n")
#> Number of vertices: 4
cat("Number of edges:", ne(g), "\n")
#> Number of edges: 4
```

### Edge endpoints

[`edge_src()`](https://catrgory.github.io/catlab/reference/edge_src.md)
and
[`edge_tgt()`](https://catrgory.github.io/catlab/reference/edge_tgt.md)
retrieve the source and target of edges. Pass an edge ID to get a single
value, or omit it to get all values:

``` r
cat("Source of edge 1:", edge_src(g, 1), "\n")
#> Source of edge 1: 1
cat("Target of edge 1:", edge_tgt(g, 1), "\n")
#> Target of edge 1: 2
cat("All sources:", edge_src(g), "\n")
#> All sources: 1 2 3 1
cat("All targets:", edge_tgt(g), "\n")
#> All targets: 2 3 1 4
```

### Neighbors

The
[`neighbors()`](https://catrgory.github.io/catlab/reference/neighbors.md)
function returns all vertices adjacent to a given vertex (both
in-neighbors and out-neighbors):

``` r
# In our graph: 1→2, 2→3, 3→1, 1→4
cat("Neighbors of vertex 1:", sort(neighbors(g, 1)), "\n")
#> Neighbors of vertex 1: 2 3 4
cat("Neighbors of vertex 2:", sort(neighbors(g, 2)), "\n")
#> Neighbors of vertex 2: 1 3
cat("Neighbors of vertex 4:", sort(neighbors(g, 4)), "\n")
#> Neighbors of vertex 4: 1
```

## Graph generators

The package includes generators for common graph families:

### Path graph

`path_graph(n)` creates a directed path
$\left. 1\rightarrow 2\rightarrow\cdots\rightarrow n \right.$ with $n$
vertices and $n - 1$ edges:

``` r
p5 <- path_graph(5)
cat("Path graph P5: V =", nv(p5), ", E =", ne(p5), "\n")
#> Path graph P5: V = 5 , E = 4
cat("Sources:", edge_src(p5), "\n")
#> Sources: 1 2 3 4
cat("Targets:", edge_tgt(p5), "\n")
#> Targets: 2 3 4 5
```

### Cycle graph

`cycle_graph(n)` creates a directed cycle
$\left. 1\rightarrow 2\rightarrow\cdots\rightarrow n\rightarrow 1 \right.$
with $n$ vertices and $n$ edges:

``` r
c4 <- cycle_graph(4)
cat("Cycle graph C4: V =", nv(c4), ", E =", ne(c4), "\n")
#> Cycle graph C4: V = 4 , E = 4
cat("Sources:", edge_src(c4), "\n")
#> Sources: 1 2 3 4
cat("Targets:", edge_tgt(c4), "\n")
#> Targets: 2 3 4 1
```

### Complete graph

`complete_graph(n)` creates the complete directed graph on $n$ vertices,
with all $n(n - 1)$ directed edges (excluding self-loops):

``` r
k4 <- complete_graph(4)
cat("Complete graph K4: V =", nv(k4), ", E =", ne(k4), "\n")
#> Complete graph K4: V = 4 , E = 12
```

## Weighted and labelled graphs

### Weighted graphs

`SchWeightedGraph` extends `SchGraph` with a `weight` attribute on
edges. The
[`WeightedGraph()`](https://catrgory.github.io/catlab/reference/WeightedGraph.md)
constructor creates instances of this schema:

``` r
wg <- WeightedGraph(V = 3, E = 2,
                    src = c(1L, 2L), tgt = c(2L, 3L),
                    weight = c(1.5, 2.5))
cat("Weight of edge 1:", subpart(wg, 1, "weight"), "\n")
#> Weight of edge 1: 1.5
cat("Weight of edge 2:", subpart(wg, 2, "weight"), "\n")
#> Weight of edge 2: 2.5
```

You can also build weighted graphs incrementally, passing the `weight`
attribute when adding edges:

``` r
wg <- WeightedGraph()
add_vertices(wg, 3)
#> [1] 1 2 3
add_edge(wg, 1, 2, weight = 0.5)
#> [1] 1
add_edge(wg, 2, 3, weight = 1.2)
#> [1] 2
add_edge(wg, 1, 3, weight = 3.0)
#> [1] 3
cat("Weights:", subpart(wg, NULL, "weight"), "\n")
#> Weights: 0.5 1.2 3
```

### Labelled graphs

`SchLabelledGraph` adds both vertex labels (`vlabel`) and edge labels
(`elabel`). The
[`LabelledGraph()`](https://catrgory.github.io/catlab/reference/LabelledGraph.md)
constructor supports these attributes:

``` r
lg <- LabelledGraph()
add_part(lg, "V", vlabel = "Alice")
#> [1] 1
add_part(lg, "V", vlabel = "Bob")
#> [1] 2
add_part(lg, "V", vlabel = "Carol")
#> [1] 3
add_edge(lg, 1, 2, elabel = "friends")
#> [1] 1
add_edge(lg, 2, 3, elabel = "colleagues")
#> [1] 2

cat("Vertex labels:", subpart(lg, NULL, "vlabel"), "\n")
#> Vertex labels: Alice Bob Carol
cat("Edge labels:", subpart(lg, NULL, "elabel"), "\n")
#> Edge labels: friends colleagues
```

## Visualization with DOT

The `catlab` package can convert graphs to the [DOT
language](https://graphviz.org/doc/info/lang.html) used by Graphviz. The
[`to_graphviz()`](https://catrgory.github.io/catlab/reference/to_graphviz.md)
function renders interactive diagrams via the `DiagrammeR` package,
while
[`graph_to_dot()`](https://catrgory.github.io/catlab/reference/graph_to_dot.md)
returns raw DOT strings for use with external tools.

### Basic DOT output

[`graph_to_dot()`](https://catrgory.github.io/catlab/reference/graph_to_dot.md)
converts any graph ACSet to a DOT string. Use
[`to_graphviz()`](https://catrgory.github.io/catlab/reference/to_graphviz.md)
to render it as an interactive diagram:

``` r
g <- path_graph(4)
to_graphviz(g)
```

### Labelled DOT output

Pass `node_label` and `edge_label` to use ACSet attributes as labels in
the DOT output:

``` r
lg <- LabelledGraph(V = 3, E = 2,
                    src = c(1L, 2L), tgt = c(2L, 3L),
                    vlabel = c("Alice", "Bob", "Carol"),
                    elabel = c("friends", "colleagues"))
to_graphviz(lg, node_label = "vlabel", edge_label = "elabel")
```

### Weighted graph visualization

Edge weights can be displayed as edge labels:

``` r
wg <- WeightedGraph(V = 3, E = 3,
                    src = c(1L, 2L, 1L), tgt = c(2L, 3L, 3L),
                    weight = c(0.5, 1.2, 3.0))
to_graphviz(wg, edge_label = "weight")
```

### Undirected rendering

Set `directed = FALSE` to render an undirected graph (using `--` instead
of `->`):

``` r
g <- cycle_graph(4)
to_graphviz(g, directed = FALSE)
```

### Graph attributes

The `graph_attrs` parameter adds global DOT attributes:

``` r
g <- path_graph(3)
to_graphviz(g, graph_attrs = "rankdir=LR")
```

### Generic ACSet visualization

[`generic_to_dot()`](https://catrgory.github.io/catlab/reference/generic_to_dot.md)
can visualize any ACSet by showing all objects and morphisms from the
schema. This is useful for understanding the internal structure:

``` r
g <- path_graph(3)
DiagrammeR::grViz(generic_to_dot(g))
```

This representation shows each part as a labelled box node (e.g., `V:1`,
`E:2`) with arrows for each morphism value (`src`, `tgt`). It reveals
the full functorial structure of the graph as a C-set.

## ACSet transformations on graphs

A **graph homomorphism** is a structure-preserving map between two
graphs. In categorical terms, it is a **natural transformation** between
the functors representing the two graphs. Concretely, a homomorphism
$\left. \alpha:G\rightarrow H \right.$ assigns:

- A function $\left. \alpha_{V}:V_{G}\rightarrow V_{H} \right.$ (mapping
  vertices)
- A function $\left. \alpha_{E}:E_{G}\rightarrow E_{H} \right.$ (mapping
  edges)

such that the **naturality condition** holds: for every edge $e$ in $G$,
$\alpha_{V}\left( {src}(e) \right) = {src}\left( \alpha_{E}(e) \right)$
and
$\alpha_{V}\left( {tgt}(e) \right) = {tgt}\left( \alpha_{E}(e) \right)$.

### Constructing a homomorphism

``` r
# Map a path 1→2 into a path 1→2→3 (embed at the start)
g1 <- path_graph(2)   # 1 → 2
g2 <- path_graph(3)   # 1 → 2 → 3

alpha <- ACSetTransformation(
  components = list(V = c(1L, 2L), E = c(1L)),
  dom_acset = g1, codom_acset = g2
)
cat("Vertex map:", alpha@components$V, "\n")
#> Vertex map: 1 2
cat("Edge map:", alpha@components$E, "\n")
#> Edge map: 1
cat("Natural?", is_natural(alpha), "\n")
#> Natural? TRUE
```

### Identity and composition

Every graph has an identity homomorphism, and homomorphisms compose:

``` r
g1 <- path_graph(2)
g2 <- path_graph(3)
g3 <- path_graph(4)

# g1 → g2: embed at start
alpha <- ACSetTransformation(
  components = list(V = c(1L, 2L), E = c(1L)),
  dom_acset = g1, codom_acset = g2
)
# g2 → g3: embed at start
beta <- ACSetTransformation(
  components = list(V = c(1L, 2L, 3L), E = c(1L, 2L)),
  dom_acset = g2, codom_acset = g3
)

# Compose: g1 → g3
gamma <- compose_transformations(alpha, beta)
cat("Composed vertex map:", gamma@components$V, "\n")
#> Composed vertex map: 1 2
cat("Composed edge map:", gamma@components$E, "\n")
#> Composed edge map: 1
cat("Natural?", is_natural(gamma), "\n")
#> Natural? TRUE

# Identity
id <- id_transformation(g1)
cat("Identity vertex map:", id@components$V, "\n")
#> Identity vertex map: 1 2
```

### Finding homomorphisms automatically

The
[`find_homomorphism()`](https://catrgory.github.io/catlab/reference/find_homomorphism.md)
function uses backtracking search to find a homomorphism from a pattern
graph to a target graph:

``` r
# Find an embedding of a triangle in K4
triangle <- cycle_graph(3)
k4 <- complete_graph(4)

h <- find_homomorphism(triangle, k4)
cat("Triangle → K4:\n")
#> Triangle → K4:
cat("  Vertex map:", h@components$V, "\n")
#>   Vertex map: 1 2 3
cat("  Edge map:", h@components$E, "\n")
#>   Edge map: 4 8 2
cat("  Natural?", is_natural(h), "\n")
#>   Natural? TRUE
```

### All monic homomorphisms

[`find_all_homomorphisms()`](https://catrgory.github.io/catlab/reference/find_all_homomorphisms.md)
enumerates all homomorphisms. With `monic = TRUE`, it finds only
injective (monic) morphisms — graph embeddings:

``` r
edge <- path_graph(2)
triangle <- cycle_graph(3)

all_h <- find_all_homomorphisms(edge, triangle, monic = TRUE)
cat("Monic embeddings of an edge into a triangle:", length(all_h), "\n")
#> Monic embeddings of an edge into a triangle: 3
for (i in seq_along(all_h)) {
  cat(sprintf("  Embedding %d: V = [%s], E = [%s]\n", i,
    paste(all_h[[i]]@components$V, collapse = ", "),
    paste(all_h[[i]]@components$E, collapse = ", ")))
}
#>   Embedding 1: V = [1, 2], E = [1]
#>   Embedding 2: V = [2, 3], E = [2]
#>   Embedding 3: V = [3, 1], E = [3]
```

There are 3 monic embeddings — one for each edge of the triangle.

### Checking embeddability

[`is_homomorphic()`](https://catrgory.github.io/catlab/reference/is_homomorphic.md)
is a quick boolean check:

``` r
cat("Edge embeds in triangle?",
    is_homomorphic(edge, triangle, monic = TRUE), "\n")
#> Edge embeds in triangle? TRUE
cat("Triangle embeds in edge?",
    is_homomorphic(triangle, edge, monic = TRUE), "\n")
#> Triangle embeds in edge? FALSE
```

## Advanced: Custom graph schemas

Since graphs in `catlab` are ACSets, you can define your own graph
variants by creating a custom `BasicSchema`. This is the key advantage
of the functorial approach — new graph types are defined declaratively.

### Example: Colored graph

Let’s define a graph schema where each vertex has a color attribute:

``` r
SchColoredGraph <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = "Color",
  attrs = list(attr_spec("vcolor", "V", "Color"))
)
SchColoredGraph
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
#>  @ attrtypes: chr "Color"
#>  @ attrs    :List of 1
#>  .. $ :List of 3
#>  ..  ..$ name : chr "vcolor"
#>  ..  ..$ dom  : chr "V"
#>  ..  ..$ codom: chr "Color"
```

Create a constructor for the new type:

``` r
ColoredGraph <- acset_type(SchColoredGraph, name = "ColoredGraph",
                           index = c("src", "tgt"))

cg <- ColoredGraph(V = 4, E = 3,
                   src = c(1L, 2L, 3L), tgt = c(2L, 3L, 4L),
                   vcolor = c("red", "green", "blue", "yellow"))
cat("Vertex 1 color:", subpart(cg, 1, "vcolor"), "\n")
#> Vertex 1 color: red
cat("Vertex 2 color:", subpart(cg, 2, "vcolor"), "\n")
#> Vertex 2 color: green
cat("Vertex 3 color:", subpart(cg, 3, "vcolor"), "\n")
#> Vertex 3 color: blue
cat("Vertex 4 color:", subpart(cg, 4, "vcolor"), "\n")
#> Vertex 4 color: yellow
```

The
[`graph_to_dot()`](https://catrgory.github.io/catlab/reference/graph_to_dot.md)
function can use the custom attribute as labels:

``` r
to_graphviz(cg, node_label = "vcolor")
```

### Example: Edge-typed graph

Here’s a schema with categorized edges (e.g., for a social network with
“follows” and “blocks” relationships):

``` r
SchTypedEdgeGraph <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = "EdgeType",
  attrs = list(attr_spec("etype", "E", "EdgeType"))
)

TypedEdgeGraph <- acset_type(SchTypedEdgeGraph, name = "TypedEdgeGraph",
                             index = c("src", "tgt"))

tg <- TypedEdgeGraph()
add_vertices(tg, 3)
#> [1] 1 2 3
add_edge(tg, 1, 2, etype = "follows")
#> [1] 1
add_edge(tg, 2, 3, etype = "follows")
#> [1] 2
add_edge(tg, 3, 1, etype = "blocks")
#> [1] 3

cat("Edge types:", subpart(tg, NULL, "etype"), "\n")
#> Edge types: follows follows blocks
to_graphviz(tg, edge_label = "etype")
```

All the standard `catlab` operations — homomorphism finding, limits,
colimits, rewriting — work automatically on any custom graph schema,
because they are defined at the level of ACSets.

## Summary

| Function                                                                          | Description                                        |
|-----------------------------------------------------------------------------------|----------------------------------------------------|
| `SchGraph`                                                                        | Directed graph schema (V, E, src, tgt)             |
| `SchWeightedGraph`                                                                | Graph with edge weights                            |
| `SchLabelledGraph`                                                                | Graph with vertex and edge labels                  |
| [`Graph()`](https://catrgory.github.io/catlab/reference/Graph.md)                 | Create a directed graph                            |
| [`WeightedGraph()`](https://catrgory.github.io/catlab/reference/WeightedGraph.md) | Create a weighted graph                            |
| [`LabelledGraph()`](https://catrgory.github.io/catlab/reference/LabelledGraph.md) | Create a labelled graph                            |
| `add_vertex(g)`                                                                   | Add one vertex, returns its ID                     |
| `add_vertices(g, n)`                                                              | Add *n* vertices, returns their IDs                |
| `add_edge(g, s, t)`                                                               | Add edge s → t, returns edge ID                    |
| `nv(g)`, `ne(g)`                                                                  | Count vertices / edges                             |
| `edge_src(g, e)`, `edge_tgt(g, e)`                                                | Get edge endpoints                                 |
| `neighbors(g, v)`                                                                 | All adjacent vertices                              |
| `path_graph(n)`                                                                   | Path 1 → 2 → … → n                                 |
| `cycle_graph(n)`                                                                  | Cycle 1 → 2 → … → n → 1                            |
| `complete_graph(n)`                                                               | All n(n−1) directed edges                          |
| `graph_to_dot(g, ...)`                                                            | Convert graph to DOT string                        |
| `generic_to_dot(acs)`                                                             | Visualize any ACSet as DOT                         |
| `to_graphviz(g, ...)`                                                             | Render graph as interactive diagram via DiagrammeR |
| `ACSetTransformation(...)`                                                        | Graph homomorphism (natural transformation)        |
| `is_natural(alpha)`                                                               | Check naturality condition                         |
| `find_homomorphism(P, G)`                                                         | Find a homomorphism P → G                          |
| `find_all_homomorphisms(P, G)`                                                    | Enumerate all homomorphisms                        |
| `is_homomorphic(P, G)`                                                            | Quick embeddability check                          |
| `BasicSchema(...)`                                                                | Define a custom graph schema                       |
| `acset_type(schema)`                                                              | Create a constructor for a custom schema           |
