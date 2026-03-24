# Apply a rewrite rule at a specific match

Dispatches on rule semantics: DPO (pushout complement + pushout), SPO
(cascading deletion + pushout), or SqPO (final pullback complement +
pushout).

## Usage

``` r
rewrite_match(rule, match)
```

## Arguments

- rule:

  A Rule object

- match:

  ACSetTransformation L → G

## Value

List with `result` (ACSet H) and additional morphisms
