# Undirected wiring diagrams

`UWD` is the ACSet type constructor for undirected wiring diagrams.
`uwd()` is a convenience constructor using concise syntax.

## Usage

``` r
UWD(...)

uwd(outer, ...)
```

## Arguments

- ...:

  For `uwd()`: box specifications as named character vectors.
  `infection = c("s", "i")` creates a box "infection" with ports
  connected to junctions "s" and "i".

- outer:

  Character vector of outer junction names

## Value

A UWD ACSet

## Examples

``` r
# SIR-style wiring diagram: two boxes sharing junction "i"
w <- uwd(c("s", "i", "r"),
          c("s", "i"),   # box 1: infection
          c("i", "r"))   # box 2: recovery
acsets::nparts(w, "Box")      # 2
#> [1] 2
acsets::nparts(w, "Junction") # 3
#> [1] 3
```
