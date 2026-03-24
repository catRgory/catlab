# Rewriting rules

A rule is a span L ← I → R where:

- L is the pattern (left-hand side)

- I is the interface (preserved structure)

- R is the replacement (right-hand side)

## Usage

``` r
Rule(
  l = ACSetTransformation(),
  r = ACSetTransformation(),
  monic = logical(0),
  semantics = character(0)
)

rule(l, r, monic = TRUE, semantics = "DPO")
```

## Arguments

- l:

  ACSetTransformation I → L (left leg, pattern embedding)

- r:

  ACSetTransformation I → R (right leg, replacement embedding)

- monic:

  Logical; require match to be injective (default TRUE)

- semantics:

  Rewriting semantics: "DPO", "SPO", or "SqPO" (default "DPO")

## Value

A Rule object

## Details

`Rule` is the S7 class; `rule()` is a convenience constructor.

## Examples

``` r
# DPO rule: delete an edge (keep both vertices)
L <- path_graph(2)           # 1 -> 2  (pattern: an edge)
I <- Graph(V = 2)            # 1  2    (interface: two vertices, no edge)
R <- Graph(V = 2)            # 1  2    (replacement: same)
l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
rl <- rule(l, r)
# Apply to a triangle (3-cycle)
tri <- cycle_graph(3)
result <- rewrite(rl, tri)
ne(result)  # 2 (one edge deleted)
#> [1] 2
```
