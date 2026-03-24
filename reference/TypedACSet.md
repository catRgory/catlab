# Typed ACSet: an ACSet with a typing morphism to a type system

A TypedACSet pairs an ACSet X with a morphism phi: X -\> T where T is
the "type system" (another ACSet on the same schema). Every element in X
is assigned a type by phi.

## Usage

``` r
TypedACSet(
  acset = acsets::ACSet(),
  type_system = acsets::ACSet(),
  typing = ACSetTransformation()
)
```

## Arguments

- acset:

  The ACSet instance

- type_system:

  The type system ACSet

- typing:

  An
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)
  from acset to type_system
