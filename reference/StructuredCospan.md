# Structured multicospan (open system with multiple legs/feet)

Represents an open ACSet: an apex with multiple legs mapping discrete
feet into the apex. Each leg identifies which parts of the apex are
"exposed" at that interface.

## Usage

``` r
StructuredCospan(
  apex = acsets::ACSet(),
  legs = list(),
  interface_ob = character(0)
)
```

## Arguments

- apex:

  The ACSet forming the cospan apex

- legs:

  List of
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)
  objects from discrete feet to apex

- interface_ob:

  Name of the object type used for interfaces
