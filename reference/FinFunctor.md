# Functor between finite categories (schema morphism)

Functor between finite categories (schema morphism)

## Usage

``` r
FinFunctor(ob_map = list(), hom_map = list(), dom = FinCat(), codom = FinCat())
```

## Arguments

- ob_map:

  Named list mapping domain objects to codomain objects

- hom_map:

  Named list mapping domain morphisms to codomain morphisms

- dom:

  Domain [FinCat](https://catrgory.github.io/catlab/reference/FinCat.md)

- codom:

  Codomain
  [FinCat](https://catrgory.github.io/catlab/reference/FinCat.md)

## Examples

``` r
cat_g <- FinCat(schema = SchGraph)
F <- FinFunctor(
  ob_map = list(V = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt"),
  dom = cat_g, codom = cat_g
)
F@ob_map$V # "V"
#> [1] "V"
```
