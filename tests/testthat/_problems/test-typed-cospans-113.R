# Extracted from test-typed-cospans.R:113

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G <- path_graph(3)
sc <- open_acset(G, "V", 1L, 3L)
