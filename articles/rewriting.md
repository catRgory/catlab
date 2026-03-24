# Graph Rewriting: DPO, SPO, and SqPO

## Introduction

Algebraic graph rewriting provides a principled way to transform graphs
using *rules*. Instead of ad hoc mutation, rewriting rules are defined
declaratively as *spans* of graph morphisms and applied via universal
constructions from category theory. This gives formal guarantees about
what a transformation preserves, what it deletes, and what it creates.

The `catlab` package implements three rewriting semantics, each
progressively more permissive:

| Semantics | Full name      | Key idea                                                       |
|-----------|----------------|----------------------------------------------------------------|
| **DPO**   | Double Pushout | Most restrictive; requires *gluing conditions* to be satisfied |
| **SPO**   | Single Pushout | Relaxes gluing conditions via *cascading deletion*             |
| **SqPO**  | Sesqui-Pushout | Most expressive; supports *cloning* of elements                |

This vignette walks through all three, comparing how they handle the
same situations differently.

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

## Rules as spans

A rewriting rule is a *span* of graph morphisms:

        l         r
    L ←---- I ----→ R

where:

- **L** (left-hand side) is the *pattern* to match in the host graph.
- **R** (right-hand side) is the *replacement*.
- **I** (interface) is the part shared between L and R — what gets
  preserved.
- **l : I → L** embeds the interface into the pattern.
- **r : I → R** embeds the interface into the replacement.

Elements of L not in the image of `l` are *deleted*. Elements of R not
in the image of `r` are *created*. Elements of I are *preserved*.

In `catlab`, a rule is created with the
[`rule()`](https://catrgory.github.io/catlab/reference/Rule.md)
function:

``` r
rule(l, r, monic = TRUE, semantics = "DPO")
```

where `l` and `r` are `ACSetTransformation` objects sharing the same
domain (the interface I).

## DPO rewriting

**Double Pushout (DPO)** rewriting is the classical approach. Applying a
rule to a host graph G proceeds in two steps:

1.  **Pushout complement**: Given `l : I → L` and a match `m : L → G`,
    compute the *context* graph K by removing from G everything matched
    by L that is not in the interface I.
2.  **Pushout**: Glue K and R along I to produce the result H.

&nbsp;

    L ←--l-- I --r--→ R
    |        |         |
    m        |         |
    ↓        ↓         ↓
    G ←----- K ------→ H

### Example: adding an edge

Let’s create a rule that adds an edge between two existing vertices.

``` r
# Interface: 2 vertices (preserved)
I <- Graph(); add_vertices(I, 2)
#> [1] 1 2

# Pattern: 2 isolated vertices
L <- Graph(); add_vertices(L, 2)
#> [1] 1 2

# Replacement: 2 vertices connected by an edge (1 → 2)
R <- path_graph(2)

# Morphisms: identity on vertices, no edges in interface
l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)

add_edge_rule <- rule(l, r)
add_edge_rule@semantics
#> [1] "DPO"
```

The interface I has 2 vertices that map identically into both L and R. L
has no edges (we match 2 isolated vertices), and R has one edge (we
create it).

Apply this rule to a graph with 3 isolated vertices:

``` r
G <- Graph(); add_vertices(G, 3)
#> [1] 1 2 3
cat("Before:", nv(G), "vertices,", ne(G), "edges\n")
#> Before: 3 vertices, 0 edges
to_graphviz(G)
```

``` r

result <- rewrite(add_edge_rule, G)
cat("After:", nv(result), "vertices,", ne(result), "edges\n")
#> After: 3 vertices, 1 edges
to_graphviz(result)
```

The rule found two isolated vertices and added an edge between them.

### Example: deleting an edge

Now a rule that deletes an edge while keeping its endpoints.

``` r
# Interface: 2 vertices (preserved)
I_de <- Graph(); add_vertices(I_de, 2)
#> [1] 1 2

# Pattern: an edge 1 → 2
L_de <- path_graph(2)

# Replacement: 2 isolated vertices
R_de <- Graph(); add_vertices(R_de, 2)
#> [1] 1 2

l_de <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_de, L_de)
r_de <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_de, R_de)

del_edge_rule <- rule(l_de, r_de)
```

Apply to a path graph 1 → 2 → 3:

``` r
G2 <- path_graph(3)
cat("Before:", nv(G2), "vertices,", ne(G2), "edges\n")
#> Before: 3 vertices, 2 edges

result2 <- rewrite(del_edge_rule, G2)
cat("After:", nv(result2), "vertices,", ne(result2), "edges\n")
#> After: 3 vertices, 1 edges
```

One edge was removed; the other remains.

### Example: deleting an isolated vertex

``` r
# Pattern: 1 vertex; Interface: empty; Replacement: empty
L_dv <- Graph(); add_vertices(L_dv, 1)
#> [1] 1
I_dv <- Graph()
R_dv <- Graph()

l_dv <- ACSetTransformation(list(V = integer(0), E = integer(0)), I_dv, L_dv)
r_dv <- ACSetTransformation(list(V = integer(0), E = integer(0)), I_dv, R_dv)

del_vertex_dpo <- rule(l_dv, r_dv)
```

This works on a graph with isolated vertices:

``` r
G3 <- Graph(); add_vertices(G3, 3)
#> [1] 1 2 3
cat("Before:", nv(G3), "vertices,", ne(G3), "edges\n")
#> Before: 3 vertices, 0 edges

result3 <- rewrite(del_vertex_dpo, G3)
cat("After:", nv(result3), "vertices,", ne(result3), "edges\n")
#> After: 2 vertices, 0 edges
```

## When DPO fails: the gluing conditions

DPO rewriting requires the **gluing conditions** to be satisfied:

1.  **No dangling edges**: Deleting a vertex must not leave any edge
    without a source or target. Every edge incident to a deleted vertex
    must also be in the image of the match and slated for deletion.
2.  **No identification**: Distinct elements of L that are not in the
    interface I must not be mapped to the same element of G by the
    match.

### The dangling edge condition

Let’s try to delete a vertex that has incident edges using DPO:

``` r
# Same deletion rule as above
G_path <- path_graph(3)  # 1 → 2 → 3

# Try to delete vertex 2, which has edges 1→2 and 2→3
m_dangling <- ACSetTransformation(list(V = 2L, E = integer(0)), L_dv, G_path)

tryCatch(
  rewrite_match(del_vertex_dpo, m_dangling),
  error = function(e) cat("Error:", conditionMessage(e), "\n")
)
#> Error: Gluing condition violated: dangling edge
#> ℹ Part 2 of E maps via src to deleted part 2 of V
```

DPO **refuses** to perform this rewrite. Vertex 2 is the target of edge
1→2 and the source of edge 2→3. Deleting vertex 2 would leave those
edges “dangling” — attached to a vertex that no longer exists. Since the
rule’s interface is empty (nothing is preserved), the edges are not
accounted for.

This is a fundamental design choice of DPO: it is *safe* in the sense
that it never produces ill-formed graphs.

### The identification condition

The identification condition prevents a match from mapping two distinct
deletable parts of L to the same element of G. This can occur when the
match is not injective on the parts being deleted.

## SPO rewriting: cascading deletion

**Single Pushout (SPO)** rewriting relaxes the gluing conditions.
Instead of failing when edges would dangle, SPO automatically performs
**cascading deletion**: if a vertex is deleted, all incident edges are
deleted too.

### Cascading deletion in action

Let’s apply the *same* vertex deletion rule that failed under DPO, but
now with SPO semantics:

``` r
# Same pattern/interface/replacement, but SPO semantics
del_vertex_spo <- rule(l_dv, r_dv, monic = FALSE, semantics = "SPO")

# Delete vertex 1 from path 1 → 2
G_spo1 <- path_graph(2)
cat("Before:", nv(G_spo1), "vertices,", ne(G_spo1), "edges\n")
#> Before: 2 vertices, 1 edges

m_spo1 <- ACSetTransformation(list(V = 1L, E = integer(0)), L_dv, G_spo1)
result_spo1 <- rewrite_match(del_vertex_spo, m_spo1)

cat("After:", nv(result_spo1$result), "vertices,", ne(result_spo1$result), "edges\n")
#> After: 1 vertices, 0 edges
```

Vertex 1 was deleted, and the edge 1→2 was *automatically* removed
because its source vertex was deleted. Under DPO, this same rewrite
would have raised a “dangling edge” error.

### Deleting a middle vertex

``` r
# Delete vertex 2 from 1 → 2 → 3
G_spo2 <- path_graph(3)
cat("Before:", nv(G_spo2), "vertices,", ne(G_spo2), "edges\n")
#> Before: 3 vertices, 2 edges

m_spo2 <- ACSetTransformation(list(V = 2L, E = integer(0)), L_dv, G_spo2)
result_spo2 <- rewrite_match(del_vertex_spo, m_spo2)

cat("After:", nv(result_spo2$result), "vertices,", ne(result_spo2$result), "edges\n")
#> After: 2 vertices, 0 edges
```

Both edges (1→2 and 2→3) were cascading-deleted because they were
incident to the deleted vertex 2. The resulting graph has 2 isolated
vertices and no edges.

### SPO on a hub vertex

What happens when we delete a vertex with many connections?

``` r
# Star graph: vertex 1 connected to 2, 3, 4
G_star <- Graph()
add_vertices(G_star, 4)
#> [1] 1 2 3 4
add_edge(G_star, 1, 2)
#> [1] 1
add_edge(G_star, 1, 3)
#> [1] 2
add_edge(G_star, 1, 4)
#> [1] 3
cat("Before:", nv(G_star), "vertices,", ne(G_star), "edges\n")
#> Before: 4 vertices, 3 edges
to_graphviz(G_star)
```

``` r

m_star <- ACSetTransformation(list(V = 1L, E = integer(0)), L_dv, G_star)
result_star <- rewrite_match(del_vertex_spo, m_star)

cat("After:", nv(result_star$result), "vertices,", ne(result_star$result), "edges\n")
#> After: 3 vertices, 0 edges
to_graphviz(result_star$result)
```

All three outgoing edges from vertex 1 were cascade-deleted.

### SPO agrees with DPO when gluing conditions hold

When the gluing conditions *are* satisfied, SPO and DPO give the same
result:

``` r
# Delete an isolated vertex: no dangling edges
G_iso <- Graph(); add_vertices(G_iso, 3)
#> [1] 1 2 3
m_iso <- ACSetTransformation(list(V = 2L, E = integer(0)), L_dv, G_iso)

result_dpo <- rewrite_match(del_vertex_dpo, m_iso)
result_spo <- rewrite_match(del_vertex_spo, m_iso)

cat("DPO:", nv(result_dpo$result), "V,", ne(result_dpo$result), "E\n")
#> DPO: 2 V, 0 E
cat("SPO:", nv(result_spo$result), "V,", ne(result_spo$result), "E\n")
#> SPO: 2 V, 0 E
```

### SPO for adding structure

SPO is not just about deletion. It also works for rules that add
structure:

``` r
add_edge_spo <- rule(l, r, semantics = "SPO")

G_spo3 <- Graph(); add_vertices(G_spo3, 3); add_edge(G_spo3, 1, 3)
#> [1] 1 2 3
#> [1] 1
cat("Before:", nv(G_spo3), "vertices,", ne(G_spo3), "edges\n")
#> Before: 3 vertices, 1 edges

m_spo3 <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), L, G_spo3)
result_spo3 <- rewrite_match(add_edge_spo, m_spo3)

cat("After:", nv(result_spo3$result), "vertices,", ne(result_spo3$result), "edges\n")
#> After: 3 vertices, 2 edges
```

The edge addition rule works identically under SPO and DPO because no
elements are being deleted.

## SqPO rewriting: cloning

**Sesqui-Pushout (SqPO)** is the most expressive of the three semantics.
Its key capability is **cloning**: duplicating elements of the host
graph.

In DPO and SPO, the left leg `l : I → L` is always *injective*
(one-to-one). In SqPO, `l` can be *non-injective* — multiple interface
elements can map to the same pattern element. When this happens, the
matched element in G is *cloned* into multiple copies.

### Cloning a vertex

Let’s create a rule that clones a single vertex into two copies:

``` r
# Pattern: 1 vertex
L_cl <- Graph(); add_vertices(L_cl, 1)
#> [1] 1

# Interface: 2 vertices, both mapping to the same vertex in L
I_cl <- Graph(); add_vertices(I_cl, 2)
#> [1] 1 2

# Replacement: 2 separate vertices
R_cl <- Graph(); add_vertices(R_cl, 2)
#> [1] 1 2

# l maps both I vertices to vertex 1 in L (non-injective!)
l_cl <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), I_cl, L_cl)
# r maps each I vertex to a distinct R vertex
r_cl <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_cl, R_cl)

clone_vertex <- rule(l_cl, r_cl, monic = FALSE, semantics = "SqPO")
```

The crucial detail is `V = c(1L, 1L)` in the left leg: both interface
vertices map to the same pattern vertex. This signals that the matched
vertex should be *duplicated*.

Apply this to a simple graph:

``` r
G_cl1 <- Graph(); add_vertices(G_cl1, 2)
#> [1] 1 2
cat("Before:", nv(G_cl1), "vertices,", ne(G_cl1), "edges\n")
#> Before: 2 vertices, 0 edges

m_cl1 <- ACSetTransformation(list(V = 1L, E = integer(0)), L_cl, G_cl1)
result_cl1 <- rewrite_match(clone_vertex, m_cl1)

cat("After:", nv(result_cl1$result), "vertices,", ne(result_cl1$result), "edges\n")
#> After: 3 vertices, 0 edges
```

Vertex 1 was cloned into two vertices, giving us 3 vertices total (2
original − 1 cloned + 2 copies = 3).

### Cloning duplicates incident edges

The real power of SqPO cloning is that **incident edges are
automatically duplicated**. If a cloned vertex has outgoing or incoming
edges, each copy of the vertex gets its own copy of those edges.

``` r
# Graph with outgoing edges from vertex 1
G_cl2 <- Graph()
add_vertices(G_cl2, 3)
#> [1] 1 2 3
add_edge(G_cl2, 1, 2)
#> [1] 1
add_edge(G_cl2, 1, 3)
#> [1] 2
cat("Before:", nv(G_cl2), "vertices,", ne(G_cl2), "edges\n")
#> Before: 3 vertices, 2 edges
to_graphviz(G_cl2)
```

``` r

m_cl2 <- ACSetTransformation(list(V = 1L, E = integer(0)), L_cl, G_cl2)
result_cl2 <- rewrite_match(clone_vertex, m_cl2)

cat("After:", nv(result_cl2$result), "vertices,", ne(result_cl2$result), "edges\n")
#> After: 4 vertices, 4 edges
to_graphviz(result_cl2$result)
```

Vertex 1 had two outgoing edges (1→2 and 1→3). After cloning vertex 1
into two copies, each copy gets its own version of both edges, for a
total of 4 edges and 4 vertices.

### Cloning duplicates incoming edges too

``` r
# Graph with incoming edge to vertex 1
G_cl3 <- Graph()
add_vertices(G_cl3, 2)
#> [1] 1 2
add_edge(G_cl3, 2, 1)  # edge INTO vertex 1
#> [1] 1
cat("Before:", nv(G_cl3), "vertices,", ne(G_cl3), "edges\n")
#> Before: 2 vertices, 1 edges

m_cl3 <- ACSetTransformation(list(V = 1L, E = integer(0)), L_cl, G_cl3)
result_cl3 <- rewrite_match(clone_vertex, m_cl3)

cat("After:", nv(result_cl3$result), "vertices,", ne(result_cl3$result), "edges\n")
#> After: 3 vertices, 2 edges
```

The single incoming edge 2→1 was duplicated into two edges — one going
to each copy of vertex 1.

### SqPO also handles dangling deletion

When the left leg *is* injective, SqPO handles dangling edges the same
way SPO does — by cascading deletion:

``` r
# Delete vertex 3 from a graph with edges to/from vertex 3
G_sqd <- Graph()
add_vertices(G_sqd, 4)
#> [1] 1 2 3 4
add_edge(G_sqd, 1, 2)
#> [1] 1
add_edge(G_sqd, 3, 2)
#> [1] 2
add_edge(G_sqd, 3, 4)
#> [1] 3
cat("Before:", nv(G_sqd), "vertices,", ne(G_sqd), "edges\n")
#> Before: 4 vertices, 3 edges

del_vertex_sqpo <- rule(l_dv, r_dv, monic = FALSE, semantics = "SqPO")

m_sqd <- ACSetTransformation(list(V = 3L, E = integer(0)), L_dv, G_sqd)
result_sqd <- rewrite_match(del_vertex_sqpo, m_sqd)

cat("After:", nv(result_sqd$result), "vertices,", ne(result_sqd$result), "edges\n")
#> After: 3 vertices, 1 edges
```

Vertex 3 was deleted, cascading to remove edges 3→2 and 3→4. Edge 1→2
remains untouched.

### SqPO agrees with DPO when conditions allow

When the left leg is injective and the gluing conditions hold, SqPO
produces the same result as DPO:

``` r
# Add edge: DPO and SqPO should agree
I_cmp <- Graph(); add_vertices(I_cmp, 2)
#> [1] 1 2
L_cmp <- Graph(); add_vertices(L_cmp, 2)
#> [1] 1 2
R_cmp <- path_graph(2)

l_cmp <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_cmp, L_cmp)
r_cmp <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_cmp, R_cmp)

G_cmp <- Graph(); add_vertices(G_cmp, 3)
#> [1] 1 2 3
m_cmp <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), L_cmp, G_cmp)

result_dpo_cmp <- rewrite_match(rule(l_cmp, r_cmp), m_cmp)
result_sqpo_cmp <- rewrite_match(
  rule(l_cmp, r_cmp, monic = FALSE, semantics = "SqPO"), m_cmp
)

cat("DPO:", nv(result_dpo_cmp$result), "V,", ne(result_dpo_cmp$result), "E\n")
#> DPO: 3 V, 1 E
cat("SqPO:", nv(result_sqpo_cmp$result), "V,", ne(result_sqpo_cmp$result), "E\n")
#> SqPO: 3 V, 1 E
```

## Comparison: the same scenario, three semantics

To crystallize the differences, let’s take a single scenario — deleting
a vertex with incident edges — and see what each semantics does.

### Setup: delete vertex 2 from a path 1 → 2 → 3

``` r
G_cmp <- path_graph(3)
cat("Host graph:", nv(G_cmp), "vertices,", ne(G_cmp), "edges\n")
#> Host graph: 3 vertices, 2 edges
cat("Structure: 1 → 2 → 3\n\n")
#> Structure: 1 → 2 → 3

# Rule: delete a single vertex (empty interface)
L_del <- Graph(); add_vertices(L_del, 1)
#> [1] 1
I_del <- Graph()
R_del <- Graph()
l_del <- ACSetTransformation(list(V = integer(0), E = integer(0)), I_del, L_del)
r_del <- ACSetTransformation(list(V = integer(0), E = integer(0)), I_del, R_del)

# Match: map the pattern vertex to vertex 2 in G
m_del <- ACSetTransformation(list(V = 2L, E = integer(0)), L_del, G_cmp)
```

### DPO: fails

``` r
rule_dpo <- rule(l_del, r_del, semantics = "DPO")

tryCatch(
  rewrite_match(rule_dpo, m_del),
  error = function(e) cat("DPO error:", conditionMessage(e), "\n")
)
#> DPO error: Gluing condition violated: dangling edge
#> ℹ Part 2 of E maps via src to deleted part 2 of V
```

DPO refuses because vertex 2 has incident edges (1→2 and 2→3) that are
not accounted for in the rule.

### SPO: cascading deletion

``` r
rule_spo <- rule(l_del, r_del, monic = FALSE, semantics = "SPO")
result_spo_cmp <- rewrite_match(rule_spo, m_del)

cat("SPO result:", nv(result_spo_cmp$result), "vertices,",
    ne(result_spo_cmp$result), "edges\n")
#> SPO result: 2 vertices, 0 edges
cat("Both edges cascade-deleted along with vertex 2\n")
#> Both edges cascade-deleted along with vertex 2
```

### SqPO: cascading deletion (same as SPO here)

``` r
rule_sqpo <- rule(l_del, r_del, monic = FALSE, semantics = "SqPO")
result_sqpo_cmp <- rewrite_match(rule_sqpo, m_del)

cat("SqPO result:", nv(result_sqpo_cmp$result), "vertices,",
    ne(result_sqpo_cmp$result), "edges\n")
#> SqPO result: 2 vertices, 0 edges
cat("Same as SPO when left leg is injective\n")
#> Same as SPO when left leg is injective
```

### Cloning: only SqPO

Now let’s try cloning vertex 2 (instead of deleting it). Only SqPO
supports this:

``` r
L_cl2 <- Graph(); add_vertices(L_cl2, 1)
#> [1] 1
I_cl2 <- Graph(); add_vertices(I_cl2, 2)
#> [1] 1 2
R_cl2 <- Graph(); add_vertices(R_cl2, 2)
#> [1] 1 2
l_cl2 <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), I_cl2, L_cl2)
r_cl2 <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_cl2, R_cl2)

clone_rule <- rule(l_cl2, r_cl2, monic = FALSE, semantics = "SqPO")

m_clone <- ACSetTransformation(list(V = 2L, E = integer(0)), L_cl2, G_cmp)
result_clone <- rewrite_match(clone_rule, m_clone)

cat("Clone result:", nv(result_clone$result), "vertices,",
    ne(result_clone$result), "edges\n")
#> Clone result: 4 vertices, 4 edges
cat("Vertex 2 was duplicated; each copy inherits incident edges\n")
#> Vertex 2 was duplicated; each copy inherits incident edges
```

### Summary table

| Scenario                          | DPO                | SPO                  | SqPO                 |
|-----------------------------------|--------------------|----------------------|----------------------|
| Add/delete without dangling       | ✓ Same result      | ✓ Same result        | ✓ Same result        |
| Delete vertex with incident edges | ✗ Fails (dangling) | ✓ Cascading deletion | ✓ Cascading deletion |
| Non-injective left leg (cloning)  | ✗ Not supported    | ✗ Not supported      | ✓ Clones elements    |
| Safety guarantees                 | Strongest          | Medium               | Most flexible        |

**Choose DPO** when you want strict guarantees that rewrites cannot
produce unexpected side effects. **Choose SPO** when you want automatic
cleanup of dangling structure. **Choose SqPO** when you need to
duplicate or clone elements.

## Finding matches

The
[`get_matches()`](https://catrgory.github.io/catlab/reference/get_matches.md)
function finds all valid matches (injective homomorphisms from the
pattern L into the host graph G, when `monic = TRUE`):

``` r
# How many places can we find an edge in a triangle?
triangle <- cycle_graph(3)
cat("Triangle:", nv(triangle), "vertices,", ne(triangle), "edges\n")
#> Triangle: 3 vertices, 3 edges

# Rule that looks for an edge (pattern = single edge)
I_m <- Graph(); add_vertices(I_m, 2)
#> [1] 1 2
L_m <- path_graph(2)
R_m <- Graph(); add_vertices(R_m, 2)
#> [1] 1 2
l_m <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_m, L_m)
r_m <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I_m, R_m)
find_edge_rule <- rule(l_m, r_m)

matches <- get_matches(find_edge_rule, triangle)
cat("Number of edge matches in triangle:", length(matches), "\n")
#> Number of edge matches in triangle: 3
```

Each match is an `ACSetTransformation` mapping L into G. The 3 matches
correspond to the 3 edges of the triangle.

``` r
# Inspect match components
for (i in seq_along(matches)) {
  cat("Match", i, "- vertices:", matches[[i]]@components$V,
      "edges:", matches[[i]]@components$E, "\n")
}
#> Match 1 - vertices: 1 2 edges: 1 
#> Match 2 - vertices: 2 3 edges: 2 
#> Match 3 - vertices: 3 1 edges: 3
```

### Matches in a complete graph

``` r
K4 <- complete_graph(4)
cat("K4:", nv(K4), "vertices,", ne(K4), "edges\n")
#> K4: 4 vertices, 12 edges

matches_k4 <- get_matches(find_edge_rule, K4)
cat("Edge matches in K4:", length(matches_k4), "\n")
#> Edge matches in K4: 12
```

## Iterated rewriting

Rules can be applied repeatedly until no more matches exist. This lets
you build complex transformations from simple rules.

### Adding edges step by step

The add-edge rule matches any pair of vertices, so we can apply it a
fixed number of times to gradually grow a graph:

``` r
G_iter <- Graph(); add_vertices(G_iter, 4)
#> [1] 1 2 3 4
cat("Start:", nv(G_iter), "V,", ne(G_iter), "E\n")
#> Start: 4 V, 0 E

for (step in 1:3) {
  G_new <- rewrite(add_edge_rule, G_iter)
  if (is.null(G_new)) break
  G_iter <- G_new
  cat("Step", step, ":", nv(G_iter), "V,", ne(G_iter), "E\n")
}
#> Step 1 : 4 V, 1 E
#> Step 2 : 4 V, 2 E
#> Step 3 : 4 V, 3 E

cat("\nFinal graph:\n")
#> 
#> Final graph:
to_graphviz(G_iter)
```

### Cascading deletion until empty (SPO)

The vertex-deletion rule under SPO will eventually consume the entire
graph:

``` r
G_chain <- path_graph(5)  # 1 → 2 → 3 → 4 → 5
cat("Start:", nv(G_chain), "V,", ne(G_chain), "E\n")
#> Start: 5 V, 4 E

step <- 1
while (nv(G_chain) > 0) {
  G_new <- rewrite(del_vertex_spo, G_chain)
  if (is.null(G_new)) break
  G_chain <- G_new
  cat("Step", step, ":", nv(G_chain), "V,", ne(G_chain), "E\n")
  step <- step + 1
}
#> Step 1 : 4 V, 3 E
#> Step 2 : 3 V, 2 E
#> Step 3 : 2 V, 1 E
#> Step 4 : 1 V, 0 E
#> Step 5 : 0 V, 0 E
```

Each step deletes a vertex and cascades to its incident edges. Notice
how the edge count can drop by more than one per step when a hub vertex
is removed.

## Summary

The three rewriting semantics in `catlab` give you precise control over
graph transformations:

- **DPO** is the safest: it never silently deletes or duplicates
  structure. Use it when you need strict control and are willing to
  ensure the gluing conditions hold.
- **SPO** adds automatic cascading deletion, making it convenient for
  rules that remove vertices without explicitly handling incident edges.
- **SqPO** goes further by supporting cloning via non-injective left
  legs. It subsumes both DPO and SPO when the left leg is injective.

All three are built on the same categorical foundations (pushouts and
their complements) and are available through a unified API:

``` r
my_rule <- rule(l, r, semantics = "DPO")  # or "SPO" or "SqPO"
result  <- rewrite(my_rule, G)
matches <- get_matches(my_rule, G)
```
