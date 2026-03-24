# Check if a morphism between typed ACSets preserves typing

Given typed ACSets phi_1: X_1 -\> T and phi_2: X_2 -\> T and a morphism
f: X_1 -\> X_2, check that phi_2 . f = phi_1 (types are preserved).

## Usage

``` r
is_typed_morphism(f, tacs1, tacs2)
```

## Arguments

- f:

  ACSetTransformation from tacs1 to tacs2

- tacs1:

  TypedACSet (domain)

- tacs2:

  TypedACSet (codomain)

## Value

logical
