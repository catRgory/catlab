# Create a discrete typed ACSet from a type assignment

Given a type system T and a named list of type assignments (one per
object), create a TypedACSet where each element is assigned its type.

## Usage

``` r
discrete_typed(type_system, ..., schema = type_system@schema)
```

## Arguments

- type_system:

  ACSet (the type system)

- ...:

  Named integer vectors: for each object, which type each element has

- schema:

  BasicSchema (defaults to type_system's schema)

## Value

TypedACSet
