# Extracted from test-typed-cospans.R:207

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G_inf <- Graph()
add_vertices(G_inf, 2)
add_edge(G_inf, 1, 2)
sc_inf <- open_acset(G_inf, "V", 1L, 2L)
