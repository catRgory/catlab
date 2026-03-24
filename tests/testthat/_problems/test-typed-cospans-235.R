# Extracted from test-typed-cospans.R:235

# prequel ----------------------------------------------------------------------
library(testthat)
library(catlab)
library(acsets)

# test -------------------------------------------------------------------------
make_edge <- function() {
    G <- Graph(); add_vertices(G, 2); add_edge(G, 1, 2)
    open_acset(G, "V", 1L, 2L)
  }
w <- uwd(c("a", "d"),
    e1 = c("a", "b"),
    e2 = c("b", "c"),
    e3 = c("c", "d")
  )
result <- oapply_cospans(w, list(make_edge(), make_edge(), make_edge()))
