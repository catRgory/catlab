# Typed ACSet: an ACSet with a typing morphism to a type system

A TypedACSet pairs an ACSet X with a morphism phi: X -\> T where T is
the "type system" (another ACSet on the same schema). Every element in X
is assigned a type by phi.

## Usage

``` r
TypedACSet(
  acset = acsets::ACSet(),
  type_system = acsets::ACSet(),
  typing = ACSetTransformation()
)
```

## Arguments

- acset:

  The ACSet instance

- type_system:

  The type system ACSet

- typing:

  An
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)
  from acset to type_system

## Examples

``` r
# Type system: two vertex types, one edge type
T <- Graph()
add_vertices(T, 2)
#> [1] 1 2
add_edge(T, 1, 2)
#> [1] 1
# Instance typed over T
g <- Graph()
add_vertices(g, 3)
#> [1] 1 2 3
add_edge(g, 1, 3)
#> [1] 1
add_edge(g, 2, 3)
#> [1] 2
typing <- ACSetTransformation(
  components = list(V = c(1L, 1L, 2L), E = c(1L, 1L)),
  dom_acset = g, codom_acset = T
)
tg <- TypedACSet(acset = g, type_system = T, typing = typing)
flatten_typed(tg) # returns g
#> <acsets::ACSet>
#>  @ schema: <acsets::BasicSchema>
#>  .. @ obs      : chr [1:2] "V" "E"
#>  .. @ homs     :List of 2
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "src"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "tgt"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. @ attrtypes: chr(0) 
#>  .. @ attrs    : list()
#>  @ .data :<environment: 0x55ee18dba798> 
```
