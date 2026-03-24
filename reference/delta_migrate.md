# Perform delta (pullback) migration

Given a functor F: C → D (as a FinFunctor) and a D-set (ACSet on schema
D), produce a C-set by pulling back along F.

## Usage

``` r
delta_migrate(functor, source, result_type)
```

## Arguments

- functor:

  A FinFunctor from source schema to target schema

- source:

  An ACSet on the target (codomain) schema

- result_type:

  An acset_constructor for the result (source domain schema)

## Value

An ACSet on the source (domain) schema
