# Perform delta (pullback) migration

Given a functor F: C → D (as a FinFunctor) and a D-set (ACSet on schema
D), produce a C-set by pulling back along F.

## Usage

``` r
delta_migrate(functor, source, result_type)
```

## Arguments

- functor:

  A FinFunctor from source schema to target schema

- source:

  An ACSet on the target (codomain) schema

- result_type:

  An acset_constructor for the result (source domain schema)

## Value

An ACSet on the source (domain) schema

## Examples

``` r
# Identity functor: delta migration copies the ACSet unchanged
cat_g <- FinCat(schema = SchGraph)
F_id <- FinFunctor(
  ob_map = list(V = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt"),
  dom = cat_g, codom = cat_g
)
g <- path_graph(3)
g2 <- delta_migrate(F_id, g, Graph)
nv(g2) # 3
#> [1] 3
ne(g2) # 2
#> [1] 2
```
