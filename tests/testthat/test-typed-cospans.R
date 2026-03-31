library(testthat)
library(catlab)
library(acsets)

# ============================================================================
# Typed ACSets
# ============================================================================

test_that("typed_acset creates valid typed graph", {
  T <- Graph(); add_vertices(T, 2); add_edge(T, 1, 2)
  G <- Graph(); add_vertices(G, 3); add_edge(G, 1, 3); add_edge(G, 2, 3)
  tG <- typed_acset(G, T, V = c(1L, 1L, 2L), E = c(1L, 1L))
  expect_s3_class(tG, "catlab::TypedACSet")
  expect_equal(nv(tG@acset), 3)
  expect_equal(tG@typing@components$V, c(1L, 1L, 2L))
})

test_that("typed_acset validates naturality", {
  T <- Graph(); add_vertices(T, 2); add_edge(T, 1, 2)
  G <- Graph(); add_vertices(G, 2); add_edge(G, 1, 2)
  # Valid typing: edge 1→2 maps to type edge 1→2
  tG <- typed_acset(G, T, V = c(1L, 2L), E = c(1L))
  expect_s3_class(tG, "catlab::TypedACSet")
})

test_that("typed_product computes pullback over type system", {
  T <- Graph(); add_vertices(T, 2); add_edge(T, 1, 2)

  # G1: 2 type-1 vertices, 1 type-2 vertex, 2 edges (both type 1→2)
  G1 <- Graph(); add_vertices(G1, 3); add_edge(G1, 1, 3); add_edge(G1, 2, 3)
  tG1 <- typed_acset(G1, T, V = c(1L, 1L, 2L), E = c(1L, 1L))

  # G2: 1 type-1, 1 type-2, 1 edge
  G2 <- Graph(); add_vertices(G2, 2); add_edge(G2, 1, 2)
  tG2 <- typed_acset(G2, T, V = c(1L, 2L), E = c(1L))

  tp <- typed_product(tG1, tG2)
  # Product V: pairs (v1,v2) with same type: (1,1),(2,1),(3,2) → 3 vertices
  expect_equal(nv(tp@acset), 3)
  # Product E: pairs (e1,e2) with same type: (1,1),(2,1) → 2 edges
  expect_equal(ne(tp@acset), 2)
})

test_that("typed_product with disjoint types gives empty result", {
  T <- Graph(); add_vertices(T, 3)  # 3 vertex types, no edges
  G1 <- Graph(); add_vertices(G1, 2)
  G2 <- Graph(); add_vertices(G2, 2)
  tG1 <- typed_acset(G1, T, V = c(1L, 2L), E = integer(0))
  tG2 <- typed_acset(G2, T, V = c(3L, 3L), E = integer(0))

  tp <- typed_product(tG1, tG2)
  expect_equal(nv(tp@acset), 0)  # no shared types
})

test_that("typed_coproduct gives disjoint union with combined typing", {
  T <- Graph(); add_vertices(T, 2)
  G1 <- Graph(); add_vertices(G1, 2)
  G2 <- Graph(); add_vertices(G2, 3)
  tG1 <- typed_acset(G1, T, V = c(1L, 2L), E = integer(0))
  tG2 <- typed_acset(G2, T, V = c(1L, 1L, 2L), E = integer(0))

  tc <- typed_coproduct(tG1, tG2)
  expect_equal(nv(tc@acset), 5)
  expect_equal(tc@typing@components$V, c(1L, 2L, 1L, 1L, 2L))
})

test_that("typed_coproduct requires same type system", {
  T1 <- Graph(); add_vertices(T1, 2)
  T2 <- Graph(); add_vertices(T2, 3)
  G1 <- Graph(); add_vertices(G1, 1)
  G2 <- Graph(); add_vertices(G2, 1)
  tG1 <- typed_acset(G1, T1, V = 1L, E = integer(0))
  tG2 <- typed_acset(G2, T2, V = 1L, E = integer(0))
  expect_error(typed_coproduct(tG1, tG2), "same type system")
})

test_that("flatten_typed recovers underlying ACSet", {
  T <- Graph(); add_vertices(T, 2); add_edge(T, 1, 2)
  G <- Graph(); add_vertices(G, 3); add_edge(G, 1, 3)  # type1→type2
  tG <- typed_acset(G, T, V = c(1L, 1L, 2L), E = c(1L))
  expect_identical(flatten_typed(tG), G)
})

test_that("is_typed_morphism validates type preservation", {
  T <- Graph(); add_vertices(T, 2)
  G1 <- Graph(); add_vertices(G1, 2)
  G2 <- Graph(); add_vertices(G2, 3)
  tG1 <- typed_acset(G1, T, V = c(1L, 2L), E = integer(0))
  tG2 <- typed_acset(G2, T, V = c(1L, 2L, 1L), E = integer(0))

  # Valid: maps type-1 to type-1, type-2 to type-2
  f_good <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), G1, G2)
  expect_true(is_typed_morphism(f_good, tG1, tG2))

  # Invalid: maps type-1 to type-2
  f_bad <- ACSetTransformation(list(V = c(2L, 1L), E = integer(0)), G1, G2)
  expect_false(is_typed_morphism(f_bad, tG1, tG2))
})

test_that("discrete_typed creates typed ACSet from type assignments", {
  T <- Graph(); add_vertices(T, 3)
  dt <- discrete_typed(T, V = c(1L, 1L, 2L, 3L))
  expect_equal(nv(dt@acset), 4)
  expect_equal(dt@typing@components$V, c(1L, 1L, 2L, 3L))
})

# ============================================================================
# Structured Cospans - Basic Operations
# ============================================================================

test_that("open_acset creates structured cospan", {
  G <- path_graph(3)
  sc <- open_acset(G, "V", 1L, 3L)
  expect_s3_class(sc, "catlab::StructuredCospan")
  expect_equal(nv(cospan_apex(sc)), 3)
  expect_equal(nlegs(sc), 2)
  expect_equal(foot_sizes(sc), c(1L, 1L))
})

test_that("open_acset with multi-element legs", {
  G <- complete_graph(4)
  sc <- open_acset(G, "V", c(1L, 2L), c(3L, 4L))
  expect_equal(nlegs(sc), 2)
  expect_equal(foot_sizes(sc), c(2L, 2L))
})

test_that("discrete_acset creates ACSet with parts in one object only", {
  d <- discrete_acset(SchGraph, "V", 3)
  expect_equal(nv(d), 3)
  expect_equal(ne(d), 0)
})

test_that("make_leg creates valid transformation", {
  G <- path_graph(3)
  leg <- make_leg(SchGraph, "V", c(1L, 3L), G)
  expect_s3_class(leg, "catlab::ACSetTransformation")
  expect_equal(leg@components$V, c(1L, 3L))
  expect_equal(nv(leg@dom_acset), 2)
})

# ============================================================================
# Structured Cospans - Composition
# ============================================================================

test_that("compose_cospans glues two open graphs", {
  # A: 1→2, exposed at {1} and {2}
  G1 <- path_graph(2)
  sc1 <- open_acset(G1, "V", 1L, 2L)

  # B: 1→2, exposed at {1} and {2}
  G2 <- path_graph(2)
  sc2 <- open_acset(G2, "V", 1L, 2L)

  # Compose: glue vertex 2 of G1 to vertex 1 of G2
  comp <- compose_cospans(sc1, sc2)
  expect_equal(nv(cospan_apex(comp)), 3)  # 1,2=3,4 → 3 vertices
  expect_equal(ne(cospan_apex(comp)), 2)  # 2 edges
})

test_that("compose_cospans preserves edges correctly", {
  G1 <- path_graph(3)  # 1→2→3
  sc1 <- open_acset(G1, "V", 1L, 3L)

  G2 <- path_graph(2)  # 1→2
  sc2 <- open_acset(G2, "V", 1L, 2L)

  comp <- compose_cospans(sc1, sc2)
  apex <- cospan_apex(comp)
  expect_equal(nv(apex), 4)  # 3 + 2 - 1 (shared vertex)
  expect_equal(ne(apex), 3)  # 2 + 1 edges
})

test_that("compose_cospans fails on foot mismatch", {
  G1 <- path_graph(2)
  sc1 <- open_acset(G1, "V", 1L, 2L)  # right foot: 1 element

  G2 <- Graph(); add_vertices(G2, 3)
  sc2 <- open_acset(G2, "V", c(1L, 2L), 3L)  # left foot: 2 elements

  expect_error(compose_cospans(sc1, sc2), "foot mismatch")
})

test_that("compose_cospans requires at least two legs on both inputs", {
  G1 <- path_graph(2)
  sc1 <- open_acset(G1, "V", 2L)

  G2 <- path_graph(2)
  sc2 <- open_acset(G2, "V", 1L)

  expect_error(compose_cospans(sc1, sc2), "at least 2 legs")
})

# ============================================================================
# Structured Cospans - Monoidal Product
# ============================================================================

test_that("otimes_cospans places cospans side by side", {
  G1 <- path_graph(2)
  sc1 <- open_acset(G1, "V", 1L, 2L)

  G2 <- path_graph(3)
  sc2 <- open_acset(G2, "V", 1L, 3L)

  tens <- otimes_cospans(sc1, sc2)
  expect_equal(nv(cospan_apex(tens)), 5)  # 2 + 3
  expect_equal(ne(cospan_apex(tens)), 3)  # 1 + 2
  expect_equal(nlegs(tens), 4)  # 2 + 2
})

# ============================================================================
# Structured Cospans - UWD Composition (oapply_cospans)
# ============================================================================

test_that("oapply_cospans composes SIR-like open graphs", {
  # Infection: S→I, ports [S, I]
  G_inf <- Graph(); add_vertices(G_inf, 2); add_edge(G_inf, 1, 2)
  sc_inf <- open_acset(G_inf, "V", 1L, 2L)

  # Recovery: I→R, ports [I, R]
  G_rec <- Graph(); add_vertices(G_rec, 2); add_edge(G_rec, 1, 2)
  sc_rec <- open_acset(G_rec, "V", 1L, 2L)

  w <- uwd(c("s", "i", "r"), infection = c("s", "i"), recovery = c("i", "r"))
  result <- oapply_cospans(w, list(sc_inf, sc_rec))

  apex <- cospan_apex(result)
  expect_equal(nv(apex), 3)  # S, I, R identified
  expect_equal(ne(apex), 2)  # S→I and I→R
  expect_equal(nlegs(result), 1)  # outer ports as single leg
  expect_equal(foot_sizes(result), 3L)  # 3 outer ports
})

test_that("oapply_cospans composes 3-box system", {
  # Three open edges: A→B, B→C, C→D
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
  apex <- cospan_apex(result)
  expect_equal(nv(apex), 4)  # a, b, c, d
  expect_equal(ne(apex), 3)  # a→b, b→c, c→d
})

test_that("oapply_cospans handles shared junctions (3-way merge)", {
  # Three edges all meeting at a central junction
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
  apex <- cospan_apex(result)
  expect_equal(nv(apex), 4)  # center + a + b + c (3 edges' src=center identified)
  expect_equal(ne(apex), 3)
})

test_that("oapply_cospans with no outer ports", {
  G1 <- Graph(); add_vertices(G1, 2); add_edge(G1, 1, 2)
  sc1 <- open_acset(G1, "V", 1L, 2L)

  G2 <- Graph(); add_vertices(G2, 2); add_edge(G2, 1, 2)
  sc2 <- open_acset(G2, "V", 1L, 2L)

  # Closed system: no outer ports, two boxes share a junction
  w <- uwd(character(0), box1 = c("a", "b"), box2 = c("b", "a"))
  result <- oapply_cospans(w, list(sc1, sc2))
  apex <- cospan_apex(result)
  # Both a and b are shared → 2 vertices identified from 4
  expect_equal(nv(apex), 2)
  expect_equal(ne(apex), 2)
})

# ============================================================================
# Integration: Typed + Structured Cospans
# ============================================================================

test_that("typed product of open system components", {
  T <- Graph(); add_vertices(T, 2)  # 2 vertex types

  # Two typed graphs
  G1 <- Graph(); add_vertices(G1, 3)
  tG1 <- typed_acset(G1, T, V = c(1L, 2L, 1L), E = integer(0))

  G2 <- Graph(); add_vertices(G2, 2)
  tG2 <- typed_acset(G2, T, V = c(1L, 2L), E = integer(0))

  tp <- typed_product(tG1, tG2)
  # Pairs: (1,1),(3,1) have type 1×1, (2,2) has type 2×2 → 3 vertices
  expect_equal(nv(tp@acset), 3)
  # Types should be preserved
  expect_true(all(tp@typing@components$V %in% c(1L, 2L)))
})

cat("All typed ACSet and structured cospan tests passed!\n")
