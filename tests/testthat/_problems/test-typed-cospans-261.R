# Extracted from test-typed-cospans.R:261

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G1 <- Graph()
add_vertices(G1, 2)
add_edge(G1, 1, 2)
sc1 <- open_acset(G1, "V", 1L, 2L)
