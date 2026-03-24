# Create a discrete (empty) ACSet with n parts in a given object

The L functor: FinSet -\> ACSet maps a finite set of size n to an ACSet
with n parts in the interface object and nothing else.

## Usage

``` r
discrete_acset(schema, ob, n)
```

## Arguments

- schema:

  BasicSchema

- ob:

  Character: which object to populate

- n:

  Integer: how many parts

## Value

ACSet
