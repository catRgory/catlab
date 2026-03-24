# Apply a rule to a graph, finding the first valid match

Apply a rule to a graph, finding the first valid match

## Usage

``` r
rewrite(rule, graph)
```

## Arguments

- rule:

  A Rule object

- graph:

  Target ACSet

## Value

The rewritten ACSet, or NULL if no match found

## Examples

``` r
# Delete an edge via DPO rewriting
L <- path_graph(2)
I <- Graph(V = 2)
R <- Graph(V = 2)
l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
rl <- rule(l, r)
g <- path_graph(3)
result <- rewrite(rl, g)
ne(result) # 1 (one edge removed)
#> [1] 1
```
