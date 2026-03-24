# Extracted from test-typed-cospans.R:72

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T1 <- Graph()
add_vertices(T1, 2)
T2 <- Graph()
add_vertices(T2, 3)
G1 <- Graph()
add_vertices(G1, 1)
G2 <- Graph()
add_vertices(G2, 1)
tG1 <- typed_acset(G1, T1, V = 1L, E = integer(0))
