# Extracted from test-typed-cospans.R:284

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T <- Graph()
add_vertices(T, 2)
G1 <- Graph()
add_vertices(G1, 3)
tG1 <- typed_acset(G1, T, V = c(1L, 2L, 1L), E = integer(0))
