library(testthat)
library(catlab)
library(acsets)

# === Graph tests ===========================================================

test_that("Graph constructor works", {
  g <- Graph(V = 4, E = 3, src = c(1L,2L,3L), tgt = c(2L,3L,4L))
  expect_equal(nv(g), 4L)
  expect_equal(ne(g), 3L)
  expect_equal(edge_src(g, 1L), 1L)
  expect_equal(edge_tgt(g, 3L), 4L)
})

test_that("Graph convenience functions work", {
  g <- Graph()
  v1 <- add_vertex(g)
  v2 <- add_vertex(g)
  v3 <- add_vertex(g)
  add_edge(g, v1, v2)
  add_edge(g, v2, v3)
  expect_equal(nv(g), 3L)
  expect_equal(ne(g), 2L)
  expect_equal(sort(neighbors(g, 2L)), c(1L, 3L))
})

test_that("path_graph works", {
  g <- path_graph(5)
  expect_equal(nv(g), 5L)
  expect_equal(ne(g), 4L)
  expect_equal(edge_src(g, 1L), 1L)
  expect_equal(edge_tgt(g, 4L), 5L)
})

test_that("cycle_graph works", {
  g <- cycle_graph(4)
  expect_equal(nv(g), 4L)
  expect_equal(ne(g), 4L)
  expect_equal(edge_tgt(g, 4L), 1L)
})

test_that("complete_graph works", {
  g <- complete_graph(4)
  expect_equal(nv(g), 4L)
  expect_equal(ne(g), 12L)  # 4*3 directed edges
})

test_that("WeightedGraph works", {
  g <- WeightedGraph(V = 3, E = 2, src = c(1L,2L), tgt = c(2L,3L),
                     weight = c(1.5, 2.5))
  expect_equal(subpart(g, 1L, "weight"), 1.5)
})

# === FinCat and ACSetTransformation tests ==================================

test_that("ACSetTransformation validates", {
  g1 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  g2 <- Graph(V = 3, E = 2, src = c(1L,2L), tgt = c(2L,3L))
  alpha <- ACSetTransformation(
    components = list(V = c(1L, 2L), E = c(1L)),
    dom_acset = g1, codom_acset = g2
  )
  expect_true(is_natural(alpha))
})

test_that("id_transformation is natural", {
  g <- Graph(V = 3, E = 2, src = c(1L,2L), tgt = c(2L,3L))
  id <- id_transformation(g)
  expect_true(is_natural(id))
})

test_that("compose_transformations works", {
  g1 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  g2 <- Graph(V = 3, E = 2, src = c(1L,2L), tgt = c(2L,3L))
  g3 <- Graph(V = 4, E = 3, src = c(1L,2L,3L), tgt = c(2L,3L,4L))

  alpha <- ACSetTransformation(
    components = list(V = c(1L, 2L), E = c(1L)),
    dom_acset = g1, codom_acset = g2
  )
  beta <- ACSetTransformation(
    components = list(V = c(1L, 2L, 3L), E = c(1L, 2L)),
    dom_acset = g2, codom_acset = g3
  )
  gamma <- compose_transformations(alpha, beta)
  expect_equal(gamma@components$V, c(1L, 2L))
  expect_equal(gamma@components$E, c(1L))
})

# === Coproduct and pushout tests ==========================================

test_that("coproduct works", {
  g1 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  g2 <- Graph(V = 3, E = 1, src = 1L, tgt = 2L)
  result <- coproduct(g1, g2)
  expect_equal(nv(result$coproduct), 5L)
  expect_equal(ne(result$coproduct), 2L)
  expect_true(is_natural(result$inj1))
  expect_true(is_natural(result$inj2))
})

test_that("pushout glues shared vertices", {
  # A = single vertex, B = edge 1→2, C = edge 1→2
  # f maps A to vertex 1 of B, g maps A to vertex 1 of C
  # Pushout should have 3 vertices (vertex 1 shared) and 2 edges
  A <- Graph(V = 1)
  B <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  C <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)

  f <- ACSetTransformation(
    components = list(V = 1L, E = integer(0)),
    dom_acset = A, codom_acset = B
  )
  g <- ACSetTransformation(
    components = list(V = 1L, E = integer(0)),
    dom_acset = A, codom_acset = C
  )

  result <- pushout(f, g)
  expect_equal(nv(result$pushout), 3L)  # 2+2-1 = 3
  expect_equal(ne(result$pushout), 2L)
})

# === UWD tests =============================================================

test_that("UWD construction works", {
  sir <- uwd(
    outer = c("s", "i", "r"),
    infection = c("s", "i"),
    recovery = c("i", "r")
  )
  expect_equal(nparts(sir, "Box"), 2L)
  expect_equal(nparts(sir, "Junction"), 3L)
  expect_equal(nparts(sir, "OuterPort"), 3L)
  expect_equal(nparts(sir, "Port"), 4L)
})

test_that("UWD junction names are correct", {
  sir <- uwd(
    outer = c("s", "i", "r"),
    infection = c("s", "i"),
    recovery = c("i", "r")
  )
  # Junction names
  names <- vapply(parts(sir, "Junction"), function(j) subpart(sir, j, "name"), character(1))
  expect_true("s" %in% names)
  expect_true("i" %in% names)
  expect_true("r" %in% names)
})

test_that("relation evaluates programmatic outer junction names", {
  s_name <- "s"
  r_name <- "r"
  rel <- relation(
    s = s_name,
    r = r_name,
    .boxes = list(
      box_spec("infection", s_name, "i"),
      box_spec("recovery", "i", r_name)
    )
  )

  names <- vapply(parts(rel, "Junction"), function(j) subpart(rel, j, "name"), character(1))
  expect_setequal(names, c("s", "i", "r"))
})

# === Graphviz tests ========================================================

test_that("to_dot generates valid DOT for graph", {
  g <- Graph(V = 3, E = 2, src = c(1L,2L), tgt = c(2L,3L))
  dot <- to_dot(g)
  expect_true(grepl("digraph", dot))
  expect_true(grepl("1 -> 2", dot))
  expect_true(grepl("2 -> 3", dot))
})

test_that("to_dot works with labelled graph", {
  g <- LabelledGraph(V = 2, E = 1, src = 1L, tgt = 2L,
                     vlabel = c("A", "B"), elabel = "edge1")
  dot <- to_dot(g, node_label = "vlabel", edge_label = "elabel")
  expect_true(grepl("A", dot))
  expect_true(grepl("B", dot))
})

test_that("petri_to_dot generates bipartite DOT", {
  SchLPN <- BasicSchema(
    obs = c("S", "T", "I", "O"),
    homs = list(hom("is", "I", "S"), hom("it", "I", "T"),
                hom("os", "O", "S"), hom("ot", "O", "T")),
    attrtypes = "Name",
    attrs = list(attr_spec("sname", "S", "Name"), attr_spec("tname", "T", "Name"))
  )
  LPN <- acset_type(SchLPN, index = c("is", "it", "os", "ot"))
  pn <- LPN()
  add_part(pn, "S", sname = "S")
  add_part(pn, "S", sname = "I")
  add_part(pn, "T", tname = "inf")
  add_part(pn, "I", is = 1L, it = 1L)
  add_part(pn, "O", os = 2L, ot = 1L)

  dot <- petri_to_dot(pn)
  expect_true(grepl("PetriNet", dot))
  expect_true(grepl("S_1", dot))
  expect_true(grepl("T_1", dot))
  expect_true(grepl("lightskyblue", dot))
  expect_true(grepl("lightsalmon", dot))
})

test_that("uwd_to_dot generates UWD diagram", {
  sir <- uwd(
    outer = c("s", "i", "r"),
    infection = c("s", "i"),
    recovery = c("i", "r")
  )
  dot <- uwd_to_dot(sir)
  expect_true(grepl("graph UWD", dot))
  expect_true(grepl("B_1", dot))
  expect_true(grepl("J_", dot))
})

# === Delta migration test ==================================================

test_that("delta_migrate works for graph reversal", {
  # Functor that swaps src and tgt (graph reversal)
  cat_graph <- FinCat(schema = SchGraph)

  F <- FinFunctor(
    ob_map = list(V = "V", E = "E"),
    hom_map = list(src = "tgt", tgt = "src"),
    dom = cat_graph,
    codom = cat_graph
  )

  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  g_rev <- delta_migrate(F, g, Graph)

  # Reversed graph: src and tgt swapped
  expect_equal(nv(g_rev), 3L)
  expect_equal(ne(g_rev), 2L)
  expect_equal(subpart(g_rev, 1L, "src"), 2L)
  expect_equal(subpart(g_rev, 1L, "tgt"), 1L)
})

test_that("FinFunctor requires a complete hom_map", {
  cat_graph <- FinCat(schema = SchGraph)

  expect_error(
    FinFunctor(
      ob_map = list(V = "V", E = "E"),
      hom_map = list(src = "src"),
      dom = cat_graph,
      codom = cat_graph
    ),
    "hom_map must map every domain morphism"
  )
})

cat("\nAll catlab tests passed!\n")
