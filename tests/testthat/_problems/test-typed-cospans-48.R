# Extracted from test-typed-cospans.R:48

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T <- Graph()
add_vertices(T, 3)
G1 <- Graph()
add_vertices(G1, 2)
G2 <- Graph()
add_vertices(G2, 2)
tG1 <- typed_acset(G1, T, V = c(1L, 2L), E = integer(0))
