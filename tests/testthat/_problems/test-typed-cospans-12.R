# Extracted from test-typed-cospans.R:12

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T <- Graph()
add_vertices(T, 2)
add_edge(T, 1, 2)
G <- Graph()
add_vertices(G, 3)
add_edge(G, 1, 3)
add_edge(G, 2, 3)
tG <- typed_acset(G, T, V = c(1L, 1L, 2L), E = c(1L, 1L))
