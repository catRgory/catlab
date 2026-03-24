# Finite category (presented by an ACSet schema)

Finite category (presented by an ACSet schema)

## Usage

``` r
FinCat(schema = acsets::BasicSchema())
```

## Arguments

- schema:

  A
  [acsets::BasicSchema](https://catrgory.github.io/acsets/reference/BasicSchema.html)
  defining the category

## Examples

``` r
cat_graph <- FinCat(schema = SchGraph)
acsets::objects(cat_graph@schema) # "V" "E"
#> [1] "V" "E"
```
