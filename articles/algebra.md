# Limits, colimits, and graph rewriting in catlab

## Introduction

The `catlab` package provides categorical algebra tools for R, built on
the `acsets` package for attributed C-sets. This vignette demonstrates:

1.  **Limits** — products, pullbacks, equalizers, terminal objects
2.  **Colimits** — coproducts, pushouts, coequalizers, initial objects
3.  **Homomorphism finding** — pattern matching in graphs
4.  **DPO graph rewriting** — algebraic graph transformation via double
    pushout
5.  **Data migration** — delta (pullback) and sigma (pushforward)
    migration

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

## Limits and colimits

Limits and colimits are universal constructions in category theory. For
ACSets (attributed C-sets), these operations work pointwise on each
object type.

### Terminal and initial objects

The **terminal object** has exactly one part per object type. Every
ACSet has a unique morphism to it. The **initial object** has zero
parts.

``` r
t <- terminal(SchGraph)
cat("Terminal graph: V =", nv(t), ", E =", ne(t), "\n")
#> Terminal graph: V = 1 , E = 1

i <- initial(SchGraph)
cat("Initial graph: V =", nv(i), ", E =", ne(i), "\n")
#> Initial graph: V = 0 , E = 0

# Unique morphism to terminal
g <- path_graph(3)
alpha <- to_terminal(g)
cat("Morphism maps all", nv(g), "vertices to vertex 1\n")
#> Morphism maps all 3 vertices to vertex 1
cat("Natural?", is_natural(alpha), "\n")
#> Natural? TRUE
```

### Coproducts (disjoint union)

The coproduct of two ACSets is their disjoint union, with injection
morphisms tracking where each part came from.

``` r
g1 <- path_graph(2)   # 1 → 2
g2 <- cycle_graph(3)  # 1 → 2 → 3 → 1

cp <- coproduct(g1, g2)
cat("g1: V =", nv(g1), ", E =", ne(g1), "\n")
#> g1: V = 2 , E = 1
cat("g2: V =", nv(g2), ", E =", ne(g2), "\n")
#> g2: V = 3 , E = 3
cat("Coproduct: V =", nv(cp$coproduct), ", E =", ne(cp$coproduct), "\n")
#> Coproduct: V = 5 , E = 4
cat("Injection 1 (V):", cp$inj1@components$V, "\n")
#> Injection 1 (V): 1 2
cat("Injection 2 (V):", cp$inj2@components$V, "\n")
#> Injection 2 (V): 3 4 5
```

### Products (categorical product)

The product of two graphs contains all pairs of vertices. An edge exists
in the product only when both component graphs have edges between the
corresponding vertices.

``` r
g1 <- path_graph(2)  # 1 → 2
g2 <- path_graph(2)  # 1 → 2

p <- product(g1, g2)
cat("Product of two edges: V =", nv(p$product), ", E =", ne(p$product), "\n")
#> Product of two edges: V = 4 , E = 1
cat("Projection 1 (V):", p$proj1@components$V, "\n")
#> Projection 1 (V): 1 2 1 2
cat("Projection 2 (V):", p$proj2@components$V, "\n")
#> Projection 2 (V): 1 1 2 2
```

The product has 4 vertices (pairs) but only 1 edge: the pair of edges
$\left( 1\rightarrow 2,1\rightarrow 2 \right)$ maps to vertex pair
$\left. (1,1)\rightarrow(2,2) \right.$.

### Pushouts (gluing)

The pushout glues two ACSets along a common substructure. Given
morphisms $\left. f:A\rightarrow B \right.$ and
$\left. g:A\rightarrow C \right.$, the pushout identifies $f(a)$ with
$g(a)$ for each part $a$ of $A$.

``` r
# Glue two edges at a shared vertex
A <- Graph(); add_vertices(A, 1)  # Shared vertex
#> [1] 1
B <- path_graph(2)                 # 1 → 2
C <- path_graph(2)                 # 1 → 2

# Share the source vertex
f <- ACSetTransformation(list(V = 1L, E = integer(0)), A, B)
g <- ACSetTransformation(list(V = 1L, E = integer(0)), A, C)

po <- pushout(f, g)
cat("Pushout: V =", nv(po$pushout), ", E =", ne(po$pushout), "\n")
#> Pushout: V = 3 , E = 2
# 2 + 2 - 1 = 3 vertices, 2 edges (the shared vertex is identified)
```

### Pullbacks (fiber product)

The pullback of a cospan $\left. B\rightarrow D\leftarrow C \right.$
consists of pairs $(b,c)$ where $f(b) = g(c)$ — the “fiber product.”

``` r
# D: 2 vertices; B: 3 vertices mapping {1,2→1, 3→2}; C: 2 vertices mapping {1→1, 2→2}
D <- Graph(); add_vertices(D, 2)
#> [1] 1 2
B <- Graph(); add_vertices(B, 3)
#> [1] 1 2 3
C <- Graph(); add_vertices(C, 2)
#> [1] 1 2

f <- ACSetTransformation(list(V = c(1L, 1L, 2L), E = integer(0)), B, D)
g <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), C, D)

pb <- pullback(f, g)
cat("Pullback: V =", nv(pb$pullback), "\n")
#> Pullback: V = 3
cat("Pairs (B, C):")
#> Pairs (B, C):
for (i in seq_len(nv(pb$pullback))) {
  cat(sprintf(" (%d,%d)", pb$proj1@components$V[i], pb$proj2@components$V[i]))
}
#>  (1,1) (2,1) (3,2)
cat("\n")
# Fiber over D=1: B parts {1,2} × C parts {1} = 2 pairs
# Fiber over D=2: B parts {3} × C parts {2} = 1 pair
```

### Equalizers and coequalizers

The **equalizer** of two parallel morphisms
$\left. f,g:A\rightarrow B \right.$ is the subobject of $A$ where $f$
and $g$ agree.

``` r
A <- Graph(); add_vertices(A, 3)
#> [1] 1 2 3
B <- Graph(); add_vertices(B, 3)
#> [1] 1 2 3

# f: 1→1, 2→2, 3→3 (identity); g: 1→1, 2→1, 3→3 (merges 2 into 1)
f <- ACSetTransformation(list(V = c(1L, 2L, 3L), E = integer(0)), A, B)
g <- ACSetTransformation(list(V = c(1L, 1L, 3L), E = integer(0)), A, B)

eq <- equalizer(f, g)
cat("Equalizer: V =", nv(eq$equalizer), "\n")
#> Equalizer: V = 2
cat("Included vertices:", eq$incl@components$V, "\n")
#> Included vertices: 1 3
# Vertices 1 and 3 agree; vertex 2 doesn't
```

The **coequalizer** identifies elements in the codomain:

``` r
# Identify vertices 1 and 2 in B
A <- Graph(); add_vertices(A, 1)
#> [1] 1
B <- Graph(); add_vertices(B, 3)
#> [1] 1 2 3

f <- ACSetTransformation(list(V = 1L, E = integer(0)), A, B)
g <- ACSetTransformation(list(V = 2L, E = integer(0)), A, B)

coeq <- coequalizer(f, g)
cat("Coequalizer: V =", nv(coeq$coequalizer), "(from 3)\n")
#> Coequalizer: V = 2 (from 3)
cat("Quotient map:", coeq$proj@components$V, "\n")
#> Quotient map: 1 1 2
```

## Homomorphism finding

A **homomorphism** between two ACSets is an ACSet transformation — a
structure-preserving map. The
[`find_homomorphism()`](https://catrgory.github.io/catlab/reference/find_homomorphism.md)
function uses backtracking search to find morphisms from a pattern to a
target.

``` r
# Find an edge in a triangle
edge <- path_graph(2)
triangle <- cycle_graph(3)

h <- find_homomorphism(edge, triangle)
cat("Edge maps to triangle:\n")
#> Edge maps to triangle:
cat("  V:", h@components$V, "\n")
#>   V: 1 2
cat("  E:", h@components$E, "\n")
#>   E: 1
cat("  Natural?", is_natural(h), "\n")
#>   Natural? TRUE
```

### Finding all homomorphisms

``` r
all_h <- find_all_homomorphisms(edge, triangle, monic = TRUE)
cat("Monic homomorphisms (edge → triangle):", length(all_h), "\n")
#> Monic homomorphisms (edge → triangle): 3
for (i in seq_along(all_h)) {
  cat(sprintf("  Match %d: V=[%s], E=[%s]\n", i,
    paste(all_h[[i]]@components$V, collapse = ","),
    paste(all_h[[i]]@components$E, collapse = ",")))
}
#>   Match 1: V=[1,2], E=[1]
#>   Match 2: V=[2,3], E=[2]
#>   Match 3: V=[3,1], E=[3]
```

### Checking embeddability

``` r
cat("Edge embeds in triangle?", is_homomorphic(edge, triangle, monic = TRUE), "\n")
#> Edge embeds in triangle? TRUE
cat("Triangle embeds in edge?", is_homomorphic(triangle, edge, monic = TRUE), "\n")
#> Triangle embeds in edge? FALSE
```

## Double pushout (DPO) graph rewriting

DPO rewriting is the categorical foundation of algebraic graph
transformation. A **rewrite rule** is a span
$\left. L\leftarrow I\rightarrow R \right.$:

- **L** (left-hand side): the pattern to match
- **I** (interface): the structure preserved during rewriting
- **R** (right-hand side): the replacement

The DPO construction proceeds in two steps:

1.  **Pushout complement**: Remove matched pattern, keeping interface →
    context K
2.  **Pushout**: Glue replacement R to context K via interface → result
    H

&nbsp;

         l         r
      L ← I → R
    m ↓   ↓     ↓
      G ← K → H

### Example 1: Add an edge

Create a rule that adds an edge between two matched vertices.

``` r
# Interface: 2 isolated vertices
I <- Graph(); add_vertices(I, 2)
#> [1] 1 2
# Pattern: 2 isolated vertices (same as interface)
L <- Graph(); add_vertices(L, 2)
#> [1] 1 2
# Replacement: edge 1 → 2
R <- path_graph(2)

l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
add_edge_rule <- rule(l, r)

# Apply to a graph with 3 isolated vertices
G <- Graph(); add_vertices(G, 3)
#> [1] 1 2 3
H <- rewrite(add_edge_rule, G)
cat("Before: V =", nv(G), ", E =", ne(G), "\n")
#> Before: V = 3 , E = 0
cat("After:  V =", nv(H), ", E =", ne(H), "\n")
#> After:  V = 3 , E = 1
```

### Example 2: Delete an edge

``` r
# Interface: 2 isolated vertices
I <- Graph(); add_vertices(I, 2)
#> [1] 1 2
# Pattern: edge 1 → 2
L <- path_graph(2)
# Replacement: 2 isolated vertices
R <- Graph(); add_vertices(R, 2)
#> [1] 1 2

l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
del_edge_rule <- rule(l, r)

# Apply to path graph 1 → 2 → 3
G <- path_graph(3)
H <- rewrite(del_edge_rule, G)
cat("Before: V =", nv(G), ", E =", ne(G), "\n")
#> Before: V = 3 , E = 2
cat("After:  V =", nv(H), ", E =", ne(H), "\n")
#> After:  V = 3 , E = 1
```

### Example 3: Add a vertex

``` r
I <- Graph()  # Empty interface
L <- Graph()  # Empty pattern (matches anywhere)
R <- Graph(); add_vertices(R, 1)  # Add a vertex
#> [1] 1

l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
add_vertex_rule <- rule(l, r, monic = FALSE)

G <- path_graph(2)
H <- rewrite(add_vertex_rule, G)
cat("Before: V =", nv(G), ", E =", ne(G), "\n")
#> Before: V = 2 , E = 1
cat("After:  V =", nv(H), ", E =", ne(H), "\n")
#> After:  V = 3 , E = 1
```

### Finding all matches

Before rewriting, we can enumerate all valid matches:

``` r
matches <- get_matches(del_edge_rule, cycle_graph(4))
cat("Delete-edge rule has", length(matches), "matches in a 4-cycle\n")
#> Delete-edge rule has 4 matches in a 4-cycle
for (i in seq_along(matches)) {
  cat(sprintf("  Match %d: V=[%s], E=[%s]\n", i,
    paste(matches[[i]]@components$V, collapse = ","),
    paste(matches[[i]]@components$E, collapse = ",")))
}
#>   Match 1: V=[1,2], E=[1]
#>   Match 2: V=[2,3], E=[2]
#>   Match 3: V=[3,4], E=[3]
#>   Match 4: V=[4,1], E=[4]
```

### Gluing condition violations

DPO rewriting requires **gluing conditions** to be satisfied. Deleting a
vertex that has incident edges (not in the interface) violates the
dangling condition:

``` r
# Try to delete a vertex from a graph where it has edges
I <- Graph()
L <- Graph(); add_vertices(L, 1)
#> [1] 1
R <- Graph()

l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
del_vertex_rule <- rule(l, r, monic = FALSE)

G <- path_graph(2)  # 1 → 2
# Matching vertex 1 (which has an outgoing edge) should fail
tryCatch(
  rewrite_match(del_vertex_rule,
    ACSetTransformation(list(V = 1L, E = integer(0)), L, G)),
  error = function(e) cat("Expected error:", conditionMessage(e), "\n")
)
#> Expected error: Gluing condition violated: dangling edge
#> ℹ Part 1 of E maps via src to deleted part 1 of V
```

## Data migration

Data migration transforms ACSets between different schemas using
functors.

### Delta migration (pullback)

Given a functor $\left. F:C\rightarrow D \right.$ and a $D$-set, delta
migration produces a $C$-set by pulling back along $F$.

``` r
# Reverse a graph: swap src and tgt
cat_G <- FinCat(schema = SchGraph)
reverse_F <- FinFunctor(
  ob_map = list(V = "V", E = "E"),
  hom_map = list(src = "tgt", tgt = "src"),  # Swap!
  dom = cat_G, codom = cat_G
)

g <- path_graph(3)  # 1 → 2 → 3
GraphType <- acset_type(SchGraph)
g_rev <- delta_migrate(reverse_F, g, GraphType)

cat("Original: src =", subpart(g, NULL, "src"), ", tgt =", subpart(g, NULL, "tgt"), "\n")
#> Original: src = 1 2 , tgt = 2 3
cat("Reversed: src =", subpart(g_rev, NULL, "src"), ", tgt =", subpart(g_rev, NULL, "tgt"), "\n")
#> Reversed: src = 2 3 , tgt = 1 2
```

### Sigma migration (left Kan extension)

Sigma migration is the left adjoint to delta — it pushes data forward
along a functor via colimits.

``` r
# Combine two edge types into one graph
dom_sch <- BasicSchema(
  obs = c("V", "E1", "E2"),
  homs = list(
    hom("src1", "E1", "V"), hom("tgt1", "E1", "V"),
    hom("src2", "E2", "V"), hom("tgt2", "E2", "V")
  )
)
codom_sch <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)

cat_dom <- FinCat(schema = dom_sch)
cat_codom <- FinCat(schema = codom_sch)
F <- FinFunctor(
  ob_map = list(V = "V", E1 = "E", E2 = "E"),
  hom_map = list(src1 = "src", tgt1 = "tgt", src2 = "src", tgt2 = "tgt"),
  dom = cat_dom, codom = cat_codom
)

# Source: 3 vertices, 1 E1-edge (1→2), 1 E2-edge (2→3)
source <- ACSet(dom_sch)
add_parts(source, "V", 3)
#> [1] 1 2 3
add_parts(source, "E1", 1)
#> [1] 1
set_subpart(source, 1, "src1", 1); set_subpart(source, 1, "tgt1", 2)
add_parts(source, "E2", 1)
#> [1] 1
set_subpart(source, 1, "src2", 2); set_subpart(source, 1, "tgt2", 3)

ResultType <- acset_type(codom_sch)
result <- sigma_migrate(F, source, ResultType)
cat("Combined graph: V =", nparts(result, "V"), ", E =", nparts(result, "E"), "\n")
#> Combined graph: V = 3 , E = 2
cat("Edge sources:", subpart(result, NULL, "src"), "\n")
#> Edge sources: 1 2
cat("Edge targets:", subpart(result, NULL, "tgt"), "\n")
#> Edge targets: 2 3
```

## Summary

| Operation     | Function                  | Description                        |
|---------------|---------------------------|------------------------------------|
| Terminal      | `terminal(schema)`        | 1 part per object                  |
| Initial       | `initial(schema)`         | 0 parts                            |
| Product       | `product(A, B)`           | Cartesian product with projections |
| Coproduct     | `coproduct(A, B)`         | Disjoint union with injections     |
| Pullback      | `pullback(f, g)`          | Fiber product of cospan            |
| Pushout       | `pushout(f, g)`           | Gluing of span                     |
| Equalizer     | `equalizer(f, g)`         | Subobject where f = g              |
| Coequalizer   | `coequalizer(f, g)`       | Quotient identifying f(a) ~ g(a)   |
| Homomorphism  | `find_homomorphism(P, G)` | Pattern matching                   |
| Rule          | `rule(l, r)`              | DPO rewriting rule                 |
| Rewrite       | `rewrite(rule, G)`        | Apply rule (auto-match)            |
| Delta migrate | `delta_migrate(F, X, T)`  | Pullback along functor             |
| Sigma migrate | `sigma_migrate(F, X, T)`  | Pushforward along functor          |
