# Compose a list of structured cospans via a UWD

Given a UWD (undirected wiring diagram) and a list of structured cospans
(one per box), compose them by identifying legs at shared junctions.

## Usage

``` r
oapply_cospans(w, cospans)
```

## Arguments

- w:

  UWD (an ACSet on SchUWD)

- cospans:

  List of StructuredCospan objects (one per box)

## Value

StructuredCospan with legs from outer ports

## Details

This is the general oapply for structured cospans: it takes the
coproduct of all apexes, then uses the UWD's wiring to build a pushout
that identifies interface parts at shared junctions.
