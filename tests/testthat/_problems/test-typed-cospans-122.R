# Extracted from test-typed-cospans.R:122

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G <- complete_graph(4)
sc <- open_acset(G, "V", c(1L, 2L), c(3L, 4L))
