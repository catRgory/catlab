# Open an ACSet by specifying interface legs

Create a structured cospan from an ACSet and leg specifications. Each
leg is an integer vector of part indices in the interface object.

## Usage

``` r
open_acset(apex, interface_ob, ...)
```

## Arguments

- apex:

  ACSet

- interface_ob:

  Character: which object type forms the interface

- ...:

  Integer vectors: each argument is a leg (indices into interface_ob)

## Value

StructuredCospan

## Examples

``` r
# Open a path graph at its two endpoints
g <- path_graph(3)           # 1 -> 2 -> 3
sc <- open_acset(g, "V", 1L, 3L)
nlegs(sc)      # 2
#> [1] 2
foot_sizes(sc) # c(1, 1)
#> [1] 1 1
```
