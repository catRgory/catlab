# Graph schemas and constructors -------------------------------------------
# Pre-built schemas and convenience constructors for common graph types.

#' Directed graph schema: V (vertices), E (edges), src, tgt
#' @export
SchGraph <- acsets::BasicSchema(
  obs = c("V", "E"),
  homs = list(acsets::hom("src", "E", "V"), acsets::hom("tgt", "E", "V"))
)

#' Symmetric graph schema: adds inv : E → E (edge involution)
#' @export
SchSymmetricGraph <- acsets::BasicSchema(
  obs = c("V", "E"),
  homs = list(
    acsets::hom("src", "E", "V"),
    acsets::hom("tgt", "E", "V"),
    acsets::hom("inv", "E", "E")
  )
)

#' Reflexive graph schema: adds refl : V → E
#' @export
SchReflexiveGraph <- acsets::BasicSchema(
  obs = c("V", "E"),
  homs = list(
    acsets::hom("src", "E", "V"),
    acsets::hom("tgt", "E", "V"),
    acsets::hom("refl", "V", "E")
  )
)

#' Weighted graph schema
#' @export
SchWeightedGraph <- acsets::BasicSchema(
  obs = c("V", "E"),
  homs = list(acsets::hom("src", "E", "V"), acsets::hom("tgt", "E", "V")),
  attrtypes = "Weight",
  attrs = list(acsets::attr_spec("weight", "E", "Weight"))
)

#' Labelled graph schema (vertex and edge labels)
#' @export
SchLabelledGraph <- acsets::BasicSchema(
  obs = c("V", "E"),
  homs = list(acsets::hom("src", "E", "V"), acsets::hom("tgt", "E", "V")),
  attrtypes = "Label",
  attrs = list(
    acsets::attr_spec("vlabel", "V", "Label"),
    acsets::attr_spec("elabel", "E", "Label")
  )
)

# Constructors

#' Create a directed graph
#' @param ... Arguments passed to the ACSet constructor
#' @examples
#' g <- Graph()
#' add_vertices(g, 3)
#' add_edge(g, 1, 2)
#' add_edge(g, 2, 3)
#' nv(g) # 3
#' ne(g) # 2
#' @export
Graph <- acsets::acset_type(SchGraph, name = "Graph", index = c("src", "tgt"))

#' Create a weighted graph
#' @param ... Arguments passed to the ACSet constructor
#' @export
WeightedGraph <- acsets::acset_type(SchWeightedGraph, name = "WeightedGraph",
                                     index = c("src", "tgt"))

#' Create a labelled graph
#' @param ... Arguments passed to the ACSet constructor
#' @export
LabelledGraph <- acsets::acset_type(SchLabelledGraph, name = "LabelledGraph",
                                     index = c("src", "tgt"))

# Convenience functions

#' Number of vertices
#' @param g A graph ACSet
#' @export
nv <- function(g) acsets::nparts(g, "V")

#' Number of edges
#' @param g A graph ACSet
#' @export
ne <- function(g) acsets::nparts(g, "E")

#' Source of edge(s)
#' @param g A graph ACSet
#' @param e Edge index (or NULL for all edges)
#' @export
edge_src <- function(g, e = NULL) acsets::subpart(g, e, "src")

#' Target of edge(s)
#' @param g A graph ACSet
#' @param e Edge index (or NULL for all edges)
#' @export
edge_tgt <- function(g, e = NULL) acsets::subpart(g, e, "tgt")

#' Neighbors of vertex v
#' @param g A graph ACSet
#' @param v Vertex index
#' @export
neighbors <- function(g, v) {
  out_edges <- acsets::incident(g, v, "src")
  in_edges <- acsets::incident(g, v, "tgt")
  unique(c(
    acsets::subpart(g, out_edges, "tgt"),
    acsets::subpart(g, in_edges, "src")
  ))
}

#' Add a vertex, returning its ID
#' @param g A graph ACSet
#' @param ... Additional attributes
#' @examples
#' g <- Graph()
#' v1 <- add_vertex(g)
#' v2 <- add_vertex(g)
#' nv(g) # 2
#' @export
add_vertex <- function(g, ...) acsets::add_part(g, "V", ...)

#' Add multiple vertices
#' @param g A graph ACSet
#' @param n Number of vertices to add
#' @param ... Additional attributes
#' @examples
#' g <- Graph()
#' add_vertices(g, 4)
#' nv(g) # 4
#' @export
add_vertices <- function(g, n, ...) acsets::add_parts(g, "V", n, ...)

#' Add an edge from s to t
#' @param g A graph ACSet
#' @param s Source vertex index
#' @param t Target vertex index
#' @param ... Additional attributes
#' @examples
#' g <- Graph()
#' add_vertices(g, 2)
#' add_edge(g, 1, 2)
#' edge_src(g, 1) # 1
#' edge_tgt(g, 1) # 2
#' @export
add_edge <- function(g, s, t, ...) acsets::add_part(g, "E", src = s, tgt = t, ...)

# Graph generators

#' Path graph: 1 → 2 → ... → n
#' @param n Number of vertices
#' @examples
#' g <- path_graph(4)
#' nv(g) # 4
#' ne(g) # 3
#' @export
path_graph <- function(n) {
  g <- Graph(V = n, E = n - 1L,
             src = seq_len(n - 1L),
             tgt = seq.int(2L, n))
  g
}

#' Cycle graph: 1 → 2 → ... → n → 1
#' @param n Number of vertices
#' @export
cycle_graph <- function(n) {
  g <- Graph(V = n, E = n,
             src = seq_len(n),
             tgt = c(seq.int(2L, n), 1L))
  g
}

#' Complete graph on n vertices
#' @param n Number of vertices
#' @export
complete_graph <- function(n) {
  edges <- expand.grid(src = seq_len(n), tgt = seq_len(n))
  edges <- edges[edges$src != edges$tgt, ]
  g <- Graph(V = n, E = nrow(edges),
             src = edges$src, tgt = edges$tgt)
  g
}
