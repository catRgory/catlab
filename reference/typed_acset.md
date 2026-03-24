# Create a typed ACSet

Create a typed ACSet

## Usage

``` r
typed_acset(acset, type_system, ...)
```

## Arguments

- acset:

  The concrete ACSet

- type_system:

  The type system ACSet

- ...:

  Named integer vectors: component mappings for the typing morphism

## Value

TypedACSet

## Examples

``` r
T <- Graph()
add_vertices(T, 2)
#> [1] 1 2
add_edge(T, 1, 2)
#> [1] 1
g <- Graph()
add_vertices(g, 3)
#> [1] 1 2 3
add_edge(g, 1, 3)
#> [1] 1
add_edge(g, 2, 3)
#> [1] 2
tg <- typed_acset(g, T, V = c(1L, 1L, 2L), E = c(1L, 1L))
flatten_typed(tg)
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
#>  @ .data :<environment: 0x55ee193398e0> 
```
