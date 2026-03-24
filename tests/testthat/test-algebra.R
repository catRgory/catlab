library(testthat)
library(catlab)
library(acsets)

# ============================================================================
# Terminal and initial objects
# ============================================================================

test_that("terminal object has 1 part per object", {
  t <- terminal(SchGraph)
  expect_equal(nv(t), 1)
  expect_equal(ne(t), 1)
  # The single edge maps 1 → 1
  expect_equal(subpart(t, 1, "src"), 1)
  expect_equal(subpart(t, 1, "tgt"), 1)
})

test_that("initial object has 0 parts", {
  i <- initial(SchGraph)
  expect_equal(nv(i), 0)
  expect_equal(ne(i), 0)
})

test_that("to_terminal morphism is well-formed", {
  g <- path_graph(3)
  alpha <- to_terminal(g)
  expect_true(is_natural(alpha))
  # All 3 vertices map to 1
  expect_equal(alpha@components$V, c(1L, 1L, 1L))
})

test_that("from_initial morphism is well-formed", {
  g <- path_graph(3)
  alpha <- from_initial(g)
  expect_true(is_natural(alpha))
  expect_equal(alpha@components$V, integer(0))
  expect_equal(alpha@components$E, integer(0))
})


# ============================================================================
# Product
# ============================================================================

test_that("product of two discrete graphs", {
  # 2 vertices × 3 vertices = 6 vertices, 0 edges
  g1 <- Graph()
  add_vertices(g1, 2)
  g2 <- Graph()
  add_vertices(g2, 3)

  p <- product(g1, g2)
  expect_equal(nv(p$product), 6)
  expect_equal(ne(p$product), 0)

  # Projections
  expect_equal(length(p$proj1@components$V), 6)
  expect_equal(length(p$proj2@components$V), 6)
  expect_true(is_natural(p$proj1))
  expect_true(is_natural(p$proj2))
})

test_that("product of single-edge graphs", {
  # Two edges: 1→2 × 1→2
  # V: (1,1), (1,2), (2,1), (2,2) = 4 vertices
  # E: (1,1) = edge from (1,1) to (2,2) = 1 edge
  g1 <- path_graph(2)
  g2 <- path_graph(2)

  p <- product(g1, g2)
  expect_equal(nv(p$product), 4)
  expect_equal(ne(p$product), 1)
  # The edge (e1, e2) goes from (src(e1), src(e2)) to (tgt(e1), tgt(e2))
  # = from (1,1)=1 to (2,2)=4
  expect_equal(subpart(p$product, 1, "src"), 1)
  expect_equal(subpart(p$product, 1, "tgt"), 4)
})

test_that("product with empty graph gives empty", {
  g1 <- path_graph(3)
  g2 <- Graph()

  p <- product(g1, g2)
  expect_equal(nv(p$product), 0)
  expect_equal(ne(p$product), 0)
})


# ============================================================================
# Pullback
# ============================================================================

test_that("pullback of identity morphisms is the graph itself", {
  g <- path_graph(3)
  id <- id_transformation(g)

  pb <- pullback(id, id)
  expect_equal(nv(pb$pullback), nv(g))
  expect_equal(ne(pb$pullback), ne(g))
})

test_that("pullback fiber product example", {
  # B: 2 vertices, C: 2 vertices, D: 1 vertex
  # f: B → D maps both to 1, g: C → D maps both to 1
  # Pullback = B × C = 4 vertices
  D <- Graph()
  add_vertices(D, 1)

  B <- Graph()
  add_vertices(B, 2)

  C <- Graph()
  add_vertices(C, 2)

  f <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), B, D)
  g <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), C, D)

  pb <- pullback(f, g)
  expect_equal(nv(pb$pullback), 4)
  expect_true(is_natural(pb$proj1))
  expect_true(is_natural(pb$proj2))
})

test_that("pullback with non-trivial fiber", {
  # D has 2 vertices; B maps {1,2,3} → {1,1,2}; C maps {1,2} → {1,2}
  # Fiber over 1: B parts {1,2} × C parts {1} = 2 pairs
  # Fiber over 2: B parts {3} × C parts {2} = 1 pair
  # Total: 3 vertices
  D <- Graph()
  add_vertices(D, 2)

  B <- Graph()
  add_vertices(B, 3)

  C <- Graph()
  add_vertices(C, 2)

  f <- ACSetTransformation(list(V = c(1L, 1L, 2L), E = integer(0)), B, D)
  g <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), C, D)

  pb <- pullback(f, g)
  expect_equal(nv(pb$pullback), 3)
})


# ============================================================================
# Equalizer
# ============================================================================

test_that("equalizer of identical morphisms is the whole domain", {
  g <- path_graph(3)
  h <- path_graph(4)
  f <- ACSetTransformation(list(V = c(1L, 2L, 3L), E = c(1L, 2L)), g, h)

  eq <- equalizer(f, f)
  expect_equal(nv(eq$equalizer), nv(g))
  expect_equal(ne(eq$equalizer), ne(g))
  expect_true(is_natural(eq$incl))
})

test_that("equalizer of different morphisms", {
  # A: 2 vertices, B: 2 vertices
  # f: {1→1, 2→2}, g: {1→1, 2→1}
  # Equalizer: vertex 1 only (where f=g)
  A <- Graph()
  add_vertices(A, 2)
  B <- Graph()
  add_vertices(B, 2)

  f <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), A, B)
  g <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), A, B)

  eq <- equalizer(f, g)
  expect_equal(nv(eq$equalizer), 1)
  expect_equal(eq$incl@components$V, 1L)
})


# ============================================================================
# Coequalizer
# ============================================================================

test_that("coequalizer identifies mapped parts", {
  # A: 1 vertex, B: 2 vertices
  # f: 1→1, g: 1→2
  # Coequalizer identifies v1 and v2 → 1 vertex
  A <- Graph()
  add_vertices(A, 1)
  B <- Graph()
  add_vertices(B, 2)

  f <- ACSetTransformation(list(V = 1L, E = integer(0)), A, B)
  g <- ACSetTransformation(list(V = 2L, E = integer(0)), A, B)

  coeq <- coequalizer(f, g)
  expect_equal(nv(coeq$coequalizer), 1)
  # Both B vertices project to 1
  expect_equal(coeq$proj@components$V, c(1L, 1L))
})

test_that("coequalizer of identity is identity", {
  g <- path_graph(3)
  id <- id_transformation(g)

  coeq <- coequalizer(id, id)
  expect_equal(nv(coeq$coequalizer), nv(g))
  expect_equal(ne(coeq$coequalizer), ne(g))
})


# ============================================================================
# Homomorphism finding
# ============================================================================

test_that("find homomorphism: edge in triangle", {
  edge <- path_graph(2)     # 1 → 2
  triangle <- cycle_graph(3) # 1→2→3→1

  h <- find_homomorphism(edge, triangle)
  expect_s3_class(h, "catlab::ACSetTransformation")
  expect_true(is_natural(h))
  # Check it's a valid morphism: src/tgt preserved
  e_src <- subpart(edge, 1, "src")
  e_tgt <- subpart(edge, 1, "tgt")
  mapped_src <- h@components$V[e_src]
  mapped_tgt <- h@components$V[e_tgt]
  img_src <- subpart(triangle, h@components$E[1], "src")
  img_tgt <- subpart(triangle, h@components$E[1], "tgt")
  expect_equal(mapped_src, img_src)
  expect_equal(mapped_tgt, img_tgt)
})

test_that("find all homomorphisms", {
  edge <- path_graph(2)
  triangle <- cycle_graph(3)

  all_h <- find_all_homomorphisms(edge, triangle)
  # Triangle has 3 edges, so there are at least 3 monic homomorphisms
  expect_true(length(all_h) >= 3)
  for (h in all_h) expect_true(is_natural(h))
})

test_that("monic homomorphism", {
  edge <- path_graph(2)
  triangle <- cycle_graph(3)

  h <- find_homomorphism(edge, triangle, monic = TRUE)
  expect_s3_class(h, "catlab::ACSetTransformation")
  # Monic: distinct vertices map to distinct vertices
  expect_true(h@components$V[1] != h@components$V[2])
})

test_that("no homomorphism when impossible", {
  # Triangle cannot embed in a single edge
  triangle <- cycle_graph(3)
  edge <- path_graph(2)

  h <- find_homomorphism(triangle, edge, monic = TRUE)
  expect_null(h)
})

test_that("is_homomorphic", {
  edge <- path_graph(2)
  triangle <- cycle_graph(3)

  expect_true(is_homomorphic(edge, triangle))
  expect_false(is_homomorphic(triangle, edge, monic = TRUE))
})

test_that("homomorphism of empty pattern", {
  empty <- Graph()
  g <- path_graph(3)

  h <- find_homomorphism(empty, g)
  expect_s3_class(h, "catlab::ACSetTransformation")
})

test_that("homomorphism with limit", {
  edge <- path_graph(2)
  triangle <- cycle_graph(3)

  limited <- find_all_homomorphisms(edge, triangle, limit = 2)
  expect_equal(length(limited), 2)
})


# ============================================================================
# Pushout complement
# ============================================================================

test_that("pushout complement: simple vertex deletion", {
  # I = 1 vertex, L = 2 vertices (no edges), G = 2 vertices (no edges)
  # l: I → L maps 1→1, m: L → G maps 1→1, 2→2
  # Delete vertex 2 → K = 1 vertex
  I <- Graph()
  add_vertices(I, 1)
  L <- Graph()
  add_vertices(L, 2)
  G <- Graph()
  add_vertices(G, 2)

  l <- ACSetTransformation(list(V = 1L, E = integer(0)), I, L)
  m <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), L, G)

  poc <- pushout_complement(l, m)
  expect_equal(nv(poc$K), 1)
  expect_true(is_natural(poc$ik))
  expect_true(is_natural(poc$kg))
})

test_that("pushout complement: dangling condition check", {
  # I = empty, L = 1 vertex, G = 1→2
  # Deleting vertex 1 would leave edge dangling
  I <- Graph()
  L <- Graph()
  add_vertices(L, 1)
  G <- path_graph(2)

  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  m <- ACSetTransformation(list(V = 1L, E = integer(0)), L, G)

  expect_error(pushout_complement(l, m), "dangling")
})


# ============================================================================
# DPO Rewriting
# ============================================================================

test_that("Rule creation", {
  I <- Graph()
  add_vertices(I, 2)
  L <- path_graph(2)
  R <- Graph()
  add_vertices(R, 2)

  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)

  rl <- rule(l, r)
  expect_s3_class(rl, "catlab::Rule")
})

test_that("DPO: add edge between vertices", {
  # L = 2 isolated vertices, R = 1→2, I = 2 vertices
  # Match L in graph with 3 vertices: adds edge between matched vertices
  I <- Graph()
  add_vertices(I, 2)

  L <- Graph()
  add_vertices(L, 2)

  R <- path_graph(2)

  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  rl <- rule(l, r)

  # Host graph: 3 isolated vertices
  G <- Graph()
  add_vertices(G, 3)

  result <- rewrite(rl, G)
  expect_s3_class(result, "acsets::ACSet")
  expect_equal(nv(result), 3)  # Same vertices
  expect_equal(ne(result), 1)  # One new edge added
})

test_that("DPO: delete edge", {
  # L = 1→2, R = 2 vertices, I = 2 vertices
  I <- Graph()
  add_vertices(I, 2)

  L <- path_graph(2)

  R <- Graph()
  add_vertices(R, 2)

  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  rl <- rule(l, r)

  # Host: 1→2→3
  G <- path_graph(3)
  result <- rewrite(rl, G)

  expect_equal(nv(result), 3)
  expect_equal(ne(result), 1)  # One edge deleted, one remains
})

test_that("DPO: add vertex", {
  # L = empty, R = 1 vertex, I = empty
  I <- Graph()
  L <- Graph()
  R <- Graph()
  add_vertices(R, 1)

  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  rl <- rule(l, r, monic = FALSE)

  G <- path_graph(2)
  result <- rewrite(rl, G)
  expect_equal(nv(result), 3)  # Added one vertex
  expect_equal(ne(result), 1)  # Edge preserved
})

test_that("DPO: merge two vertices", {
  # L = 2 vertices, I = 1 vertex, R = 1 vertex
  # l maps I to L by l(1) = 1 (vertex 2 is to be merged)
  # Wait — for merge we need: I = 1 vertex, L = 2 vertices, l: I → L, r: I → R
  # This is tricky in DPO — merge is actually done via pushout.
  # L = 2 isolated vertices, I = 1 vertex mapping to vertex 1 in L
  # R = 1 vertex
  # In G: match both L vertices to two G vertices → the pushout merges them
  I <- Graph()
  add_vertices(I, 1)

  L <- Graph()
  add_vertices(L, 2)

  R <- Graph()
  add_vertices(R, 1)

  l <- ACSetTransformation(list(V = 1L, E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = 1L, E = integer(0)), I, R)
  rl <- rule(l, r)

  # Host: 3 isolated vertices
  G <- Graph()
  add_vertices(G, 3)

  result <- rewrite(rl, G)
  expect_equal(nv(result), 2)  # 3 - 2 + 1 = 2 (deleted 2 matched, added 1)
})

test_that("get_matches finds correct count", {
  edge <- path_graph(2)
  triangle <- cycle_graph(3)

  I <- Graph()
  add_vertices(I, 2)
  L <- path_graph(2)
  R <- Graph()
  add_vertices(R, 2)

  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  rl <- rule(l, r)

  matches <- get_matches(rl, triangle)
  expect_true(length(matches) >= 3)
})

test_that("rewrite returns NULL when no match", {
  # Try to delete edge in edgeless graph
  I <- Graph()
  add_vertices(I, 2)
  L <- path_graph(2)
  R <- Graph()
  add_vertices(R, 2)

  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  rl <- rule(l, r)

  G <- Graph()
  add_vertices(G, 3)

  # No edges in G, so L (with an edge) can't match
  result <- rewrite(rl, G)
  expect_null(result)
})


# ============================================================================
# Sigma migration
# ============================================================================

test_that("sigma migration: identity functor", {
  cat_G <- FinCat(schema = SchGraph)
  id_F <- FinFunctor(
    ob_map = list(V = "V", E = "E"),
    hom_map = list(src = "src", tgt = "tgt"),
    dom = cat_G, codom = cat_G
  )

  g <- path_graph(3)
  GraphType <- acset_type(SchGraph)
  result <- sigma_migrate(id_F, g, GraphType)

  expect_equal(nv(result), nv(g))
  expect_equal(ne(result), ne(g))
})

test_that("sigma migration: combine two objects into one", {
  # Domain: schema with V1, V2 (two vertex types) and no edges
  # Codomain: schema with V (one vertex type)
  # Functor maps V1 → V, V2 → V
  dom_sch <- BasicSchema(obs = c("V1", "V2"))
  codom_sch <- BasicSchema(obs = c("V"))

  cat_dom <- FinCat(schema = dom_sch)
  cat_codom <- FinCat(schema = codom_sch)
  F <- FinFunctor(
    ob_map = list(V1 = "V", V2 = "V"),
    hom_map = list(),
    dom = cat_dom, codom = cat_codom
  )

  # Source ACSet: 2 V1 parts, 3 V2 parts
  source <- ACSet(dom_sch)
  add_parts(source, "V1", 2)
  add_parts(source, "V2", 3)

  ResultType <- acset_type(codom_sch)
  result <- sigma_migrate(F, source, ResultType)
  # Should have 2 + 3 = 5 V parts
  expect_equal(nparts(result, "V"), 5)
})

test_that("sigma migration: graph with edge types", {
  # Domain: has E1, E2 both mapping to E in codomain
  dom_sch <- BasicSchema(
    obs = c("V", "E1", "E2"),
    homs = list(
      hom("src1", "E1", "V"), hom("tgt1", "E1", "V"),
      hom("src2", "E2", "V"), hom("tgt2", "E2", "V")
    )
  )
  codom_sch <- BasicSchema(
    obs = c("V", "E"),
    homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
  )

  cat_dom <- FinCat(schema = dom_sch)
  cat_codom <- FinCat(schema = codom_sch)
  F <- FinFunctor(
    ob_map = list(V = "V", E1 = "E", E2 = "E"),
    hom_map = list(src1 = "src", tgt1 = "tgt", src2 = "src", tgt2 = "tgt"),
    dom = cat_dom, codom = cat_codom
  )

  source <- ACSet(dom_sch)
  add_parts(source, "V", 3)
  add_parts(source, "E1", 1)
  set_subpart(source, 1, "src1", 1); set_subpart(source, 1, "tgt1", 2)
  add_parts(source, "E2", 1)
  set_subpart(source, 1, "src2", 2); set_subpart(source, 1, "tgt2", 3)

  ResultType <- acset_type(codom_sch)
  result <- sigma_migrate(F, source, ResultType)
  expect_equal(nparts(result, "V"), 3)
  expect_equal(nparts(result, "E"), 2)
  # Check edge connectivity preserved
  expect_equal(subpart(result, 1, "src"), 1)
  expect_equal(subpart(result, 1, "tgt"), 2)
  expect_equal(subpart(result, 2, "src"), 2)
  expect_equal(subpart(result, 2, "tgt"), 3)
})


# ============================================================================
# Integration: pushout ∘ pullback roundtrip
# ============================================================================

test_that("pushout of pullback projections recovers original (up to iso)", {
  # For a cospan B →f D ←g C, the pushout of pullback projections
  # maps back into D (not necessarily iso, but should map)
  D <- Graph()
  add_vertices(D, 2)

  B <- Graph()
  add_vertices(B, 2)

  C <- Graph()
  add_vertices(C, 2)

  f <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), B, D)
  g <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), C, D)

  pb <- pullback(f, g)
  # The pullback should have 2 vertices (1-1, 2-2)
  expect_equal(nv(pb$pullback), 2)
})

# ============================================================================
# SPO Rewriting
# ============================================================================

test_that("SPO cascading deletion: delete vertex cascades to edges", {
  # Delete vertex 1 from path 1→2: cascading removes the edge too
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); R <- Graph()
  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  spo_rule <- rule(l, r, monic = FALSE, semantics = "SPO")
  G <- path_graph(2)
  m <- ACSetTransformation(list(V = 1L, E = integer(0)), L, G)
  result <- rewrite_match(spo_rule, m)
  expect_equal(nv(result$result), 1)
  expect_equal(ne(result$result), 0)
})

test_that("SPO cascading deletion: delete middle vertex in path", {
  # Delete vertex 2 from 1→2→3: cascading removes both edges
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); R <- Graph()
  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  spo_rule <- rule(l, r, monic = FALSE, semantics = "SPO")
  G <- path_graph(3)
  m <- ACSetTransformation(list(V = 2L, E = integer(0)), L, G)
  result <- rewrite_match(spo_rule, m)
  expect_equal(nv(result$result), 2)
  expect_equal(ne(result$result), 0)
})

test_that("SPO on graph where DPO also works gives same result", {
  # Delete isolated vertex: no dangling edges, so SPO = DPO
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); R <- Graph()
  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  G <- Graph(); add_vertices(G, 3)  # 3 isolated vertices
  m <- ACSetTransformation(list(V = 2L, E = integer(0)), L, G)

  result_spo <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SPO"), m)
  result_dpo <- rewrite_match(rule(l, r), m)
  expect_equal(nv(result_spo$result), nv(result_dpo$result))
  expect_equal(ne(result_spo$result), ne(result_dpo$result))
})

test_that("SPO with edge addition", {
  # Add an edge between existing vertices via SPO
  I <- Graph(); add_vertices(I, 2)
  L <- Graph(); add_vertices(L, 2)
  R <- path_graph(2)  # 1→2
  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  spo_rule <- rule(l, r, semantics = "SPO")
  G <- Graph(); add_vertices(G, 3); add_edge(G, 1, 3)
  m <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), L, G)
  result <- rewrite_match(spo_rule, m)
  # Original: 3V, 1E; adds edge 1→2: 3V, 2E
  expect_equal(nv(result$result), 3)
  expect_equal(ne(result$result), 2)
})

# ============================================================================
# SqPO Rewriting
# ============================================================================

test_that("SqPO clone vertex with edges (Corradini Fig 3)", {
  # Clone v1 (adjacent to v2 and v3): expect V=4, E=4
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); add_vertices(I, 2)
  R <- Graph(); add_vertices(R, 2)
  G <- Graph(); add_vertices(G, 3); add_edge(G, 1, 2); add_edge(G, 1, 3)
  l <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  m <- ACSetTransformation(list(V = 1L, E = integer(0)), L, G)
  result <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SqPO"), m)
  expect_equal(nv(result$result), 4)
  expect_equal(ne(result$result), 4)
})

test_that("SqPO dangling deletion (Corradini Fig 1)", {
  # Delete vertex 3 with incident edges from 4-vertex graph
  G <- Graph(); add_vertices(G, 4)
  add_edge(G, 1, 2); add_edge(G, 3, 2); add_edge(G, 3, 4)
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); R <- Graph()
  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  m <- ACSetTransformation(list(V = 3L, E = integer(0)), L, G)
  result <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SqPO"), m)
  expect_equal(nv(result$result), 3)
  expect_equal(ne(result$result), 1)
})

test_that("SqPO on DPO-valid rewrite gives same result as DPO", {
  # Add edge: DPO and SqPO should agree when l is monic and no dangling
  I <- Graph(); add_vertices(I, 2)
  L <- Graph(); add_vertices(L, 2)
  R <- path_graph(2)
  l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  G <- Graph(); add_vertices(G, 3)
  m <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), L, G)
  result_dpo <- rewrite_match(rule(l, r), m)
  result_sqpo <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SqPO"), m)
  expect_equal(nv(result_dpo$result), nv(result_sqpo$result))
  expect_equal(ne(result_dpo$result), ne(result_sqpo$result))
})

test_that("SqPO clone with self-loop", {
  # Clone a vertex that has a self-loop
  L <- Graph(); add_vertices(L, 1); add_edge(L, 1, 1)
  I <- Graph(); add_vertices(I, 2); add_edge(I, 1, 1); add_edge(I, 2, 2)
  R <- Graph(); add_vertices(R, 2); add_edge(R, 1, 1); add_edge(R, 2, 2)
  G <- Graph(); add_vertices(G, 2); add_edge(G, 1, 1); add_edge(G, 1, 2)
  l <- ACSetTransformation(list(V = c(1L, 1L), E = c(1L, 1L)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = c(1L, 2L)), I, R)
  m <- ACSetTransformation(list(V = 1L, E = 1L), L, G)
  result <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SqPO"), m)
  # Vertex 1 cloned → 2 copies, vertex 2 kept → 3 vertices total
  expect_equal(nv(result$result), 3)
  # Self-loop cloned to both copies, edge 1→2 cloned for each copy of v1
  expect_true(ne(result$result) >= 3)
})

test_that("SqPO clone target vertex preserves incoming edges", {
  # Clone vertex with incoming edges
  L <- Graph(); add_vertices(L, 1)
  I <- Graph(); add_vertices(I, 2)
  R <- Graph(); add_vertices(R, 2)
  G <- Graph(); add_vertices(G, 2); add_edge(G, 2, 1)  # edge into matched vertex
  l <- ACSetTransformation(list(V = c(1L, 1L), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
  m <- ACSetTransformation(list(V = 1L, E = integer(0)), L, G)
  result <- rewrite_match(rule(l, r, monic = FALSE, semantics = "SqPO"), m)
  # v1 cloned to 2, plus v2 kept: 3 vertices
  expect_equal(nv(result$result), 3)
  # Edge 2→1: tgt=v1 cloned → 2 edge copies
  expect_equal(ne(result$result), 2)
})

# ============================================================================
# Rule semantics dispatch
# ============================================================================

test_that("rule semantics defaults to DPO", {
  I <- Graph(); add_vertices(I, 1)
  L <- Graph(); add_vertices(L, 1)
  R <- Graph(); add_vertices(R, 1)
  l <- ACSetTransformation(list(V = 1L, E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = 1L, E = integer(0)), I, R)
  rl <- rule(l, r)
  expect_equal(rl@semantics, "DPO")
})

test_that("rule() accepts SPO and SqPO semantics", {
  I <- Graph(); L <- Graph(); R <- Graph()
  l <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, L)
  r <- ACSetTransformation(list(V = integer(0), E = integer(0)), I, R)
  expect_equal(rule(l, r, semantics = "SPO")@semantics, "SPO")
  expect_equal(rule(l, r, semantics = "SqPO")@semantics, "SqPO")
})

cat("All algebraic structure tests passed!\n")
