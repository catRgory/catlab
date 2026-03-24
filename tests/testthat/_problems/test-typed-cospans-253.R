# Extracted from test-typed-cospans.R:253

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
make_edge <- function() {
    G <- Graph(); add_vertices(G, 2); add_edge(G, 1, 2)
    open_acset(G, "V", 1L, 2L)
  }
w <- uwd(c("a", "b", "c"),
    e1 = c("center", "a"),
    e2 = c("center", "b"),
    e3 = c("center", "c")
  )
result <- oapply_cospans(w, list(make_edge(), make_edge(), make_edge()))
