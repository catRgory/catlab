# Create a wiring diagram using relation-style DSL

Create a wiring diagram using relation-style DSL

## Usage

``` r
relation(..., .boxes = list())
```

## Arguments

- ...:

  Named outer port variables (junction names exposed to outside)

- .boxes:

  A list of box specifications, each a named list with `name` and
  junction variable references

## Value

A UWD ACSet

## Examples

``` r
w <- relation(s = "s", r = "r",
  .boxes = list(
    box_spec("infection", "s", "i"),
    box_spec("recovery",  "i", "r")
  ))
acsets::nparts(w, "Box") # 2
#> [1] 2
```
