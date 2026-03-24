# Extracted from test-typed-cospans.R:135

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
G <- path_graph(3)
leg <- make_leg(SchGraph, "V", c(1L, 3L), G)
