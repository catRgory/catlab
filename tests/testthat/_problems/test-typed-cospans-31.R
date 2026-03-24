# Extracted from test-typed-cospans.R:31

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T <- Graph()
add_vertices(T, 2)
add_edge(T, 1, 2)
G1 <- Graph()
add_vertices(G1, 3)
add_edge(G1, 1, 3)
add_edge(G1, 2, 3)
tG1 <- typed_acset(G1, T, V = c(1L, 1L, 2L), E = c(1L, 1L))
