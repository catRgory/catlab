# Extracted from test-typed-cospans.R:148

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G1 <- path_graph(2)
sc1 <- open_acset(G1, "V", 1L, 2L)
