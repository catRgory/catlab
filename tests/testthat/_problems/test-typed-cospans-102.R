# Extracted from test-typed-cospans.R:102

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
T <- Graph()
add_vertices(T, 3)
dt <- discrete_typed(T, V = c(1L, 1L, 2L, 3L))
