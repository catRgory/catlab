# Sigma (left pushforward) migration

Given a functor F: C → D and a C-set X, compute Σ_F(X) — a D-set. This
is the left Kan extension of X along F, computed via colimits.

## Usage

``` r
sigma_migrate(functor, source, result_type)
```

## Arguments

- functor:

  A FinFunctor from source to target schema

- source:

  An ACSet on the source (domain) schema

- result_type:

  An acset_constructor for the result (codomain schema)

## Value

An ACSet on the target (codomain) schema

## Details

For each object d in D, the sigma is computed as the sum over all c with
F(c)=d of X(c). Parts from different C-objects mapping to the same
D-object are combined.

## Examples

``` r
# Identity functor: sigma migration copies the ACSet unchanged
cat_g <- FinCat(schema = SchGraph)
F_id <- FinFunctor(
  ob_map = list(V = "V", E = "E"),
  hom_map = list(src = "src", tgt = "tgt"),
  dom = cat_g, codom = cat_g
)
g <- path_graph(3)
g2 <- sigma_migrate(F_id, g, Graph)
nv(g2) # 3
#> [1] 3
ne(g2) # 2
#> [1] 2
```
