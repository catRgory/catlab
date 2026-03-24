# Equalizer of two parallel ACSet transformations

Given f, g: A → B, compute the subobject of A where f and g agree.

## Usage

``` r
equalizer(f, g)
```

## Arguments

- f:

  ACSetTransformation A → B

- g:

  ACSetTransformation A → B

## Value

List with `equalizer` (ACSet) and `incl` (inclusion morphism)

## Examples

``` r
A <- Graph(V = 2)
B <- Graph(V = 2)
f <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), A, B)
g <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), A, B)
eq <- equalizer(f, g)
nv(eq$equalizer) # 1 (only vertex 1 agrees)
#> [1] 1
```
