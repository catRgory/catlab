# Graphviz output via DiagrammeR -------------------------------------------
# Generates DOT strings and optionally renders via DiagrammeR::grViz().

#' Convert an ACSet to DOT format string
#' @param x An ACSet
#' @param ... Additional arguments passed to format-specific methods
#' @examples
#' g <- path_graph(3)
#' cat(to_dot(g))
#' @export
to_dot <- function(x, ...) {
  UseMethod("to_dot")
}

#' @export
to_dot.default <- function(x, ...) {
  if (acsets::has_subpart(x, "src") && acsets::has_subpart(x, "tgt")) {
    return(graph_to_dot(x, ...))
  }
  # Petri net
  if (acsets::has_subpart(x, "is") && acsets::has_subpart(x, "it") &&
      acsets::has_subpart(x, "os") && acsets::has_subpart(x, "ot")) {
    return(petri_to_dot(x))
  }
  # UWD
  if (acsets::has_subpart(x, "junction") && acsets::has_subpart(x, "box") &&
      acsets::has_subpart(x, "outer_junction")) {
    return(uwd_to_dot(x))
  }
  generic_to_dot(x, ...)
}

#' Render an ACSet as an interactive diagram via DiagrammeR
#'
#' @param x An ACSet (graph, Petri net, UWD, etc.)
#' @param ... Passed to `to_dot()`
#' @returns A DiagrammeR `htmlwidget` (displays in RStudio Viewer or notebook)
#' @examples
#' g <- path_graph(3)
#' \donttest{
#' to_graphviz(g)
#' }
#' @export
to_graphviz <- function(x, ...) {
  if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg DiagrammeR} package is required for rendering.",
      i = "Install it with {.code install.packages('DiagrammeR')}."
    ))
  }
  dot <- to_dot(x, ...)
  DiagrammeR::grViz(dot)
}

#' Convert a graph ACSet to DOT format
#'
#' @param g A graph ACSet with V, E, src, tgt
#' @param node_label Optional attribute name to use as node labels
#' @param edge_label Optional attribute name to use as edge labels
#' @param directed Logical; if TRUE (default), produce a directed graph
#' @param graph_attrs Optional character vector of graph-level DOT attributes
#' @returns A DOT format string
#' @examples
#' g <- path_graph(3)
#' cat(graph_to_dot(g))
#' \donttest{
#' to_graphviz(g)
#' }
#' @export
graph_to_dot <- function(g, node_label = NULL, edge_label = NULL,
                         directed = TRUE, graph_attrs = NULL) {
  kw <- if (directed) "digraph" else "graph"
  edge_op <- if (directed) " -> " else " -- "

  lines <- c(paste0(kw, " G {"))
  if (!is.null(graph_attrs)) {
    lines <- c(lines, paste0("  ", graph_attrs, ";"))
  }

  n <- acsets::nparts(g, "V")
  for (v in seq_len(n)) {
    lbl_str <- ""
    if (!is.null(node_label) && acsets::has_subpart(g, node_label)) {
      lbl <- acsets::subpart(g, v, node_label)
      if (!is.na(lbl)) lbl_str <- sprintf(' [label="%s"]', lbl)
    }
    lines <- c(lines, sprintf("  %d%s;", v, lbl_str))
  }

  ne_count <- acsets::nparts(g, "E")
  for (e in seq_len(ne_count)) {
    s <- acsets::subpart(g, e, "src")
    t <- acsets::subpart(g, e, "tgt")
    lbl_str <- ""
    if (!is.null(edge_label) && acsets::has_subpart(g, edge_label)) {
      lbl <- acsets::subpart(g, e, edge_label)
      if (!is.na(lbl)) lbl_str <- sprintf(' [label="%s"]', lbl)
    }
    lines <- c(lines, sprintf("  %d%s%d%s;", s, edge_op, t, lbl_str))
  }

  lines <- c(lines, "}")
  paste(lines, collapse = "\n")
}

#' Convert an arbitrary ACSet to DOT format
#'
#' @param acs An ACSet
#' @param ... Additional arguments (currently unused)
#' @returns A DOT format string
#' @examples
#' g <- path_graph(3)
#' cat(generic_to_dot(g))
#' @export
generic_to_dot <- function(acs, ...) {
  schema <- acs@schema
  lines <- c("digraph G {", "  rankdir=LR;")

  for (ob in acsets::objects(schema)) {
    n <- acsets::nparts(acs, ob)
    for (i in seq_len(n)) {
      node_id <- paste0(ob, "_", i)
      label <- ob
      for (a in acsets::attrs(schema, from = ob)) {
        val <- acsets::subpart(acs, i, a$name)
        if (!is.na(val) && grepl("name", a$name, ignore.case = TRUE)) {
          label <- val
          break
        }
      }
      lines <- c(lines, sprintf('  %s [label="%s:%d" shape=box];', node_id, label, i))
    }
  }

  for (h in acsets::homs(schema)) {
    n <- acsets::nparts(acs, h$dom)
    for (i in seq_len(n)) {
      val <- acsets::subpart(acs, i, h$name)
      if (!is.na(val)) {
        from_id <- paste0(h$dom, "_", i)
        to_id <- paste0(h$codom, "_", val)
        lines <- c(lines, sprintf('  %s -> %s [label="%s"];', from_id, to_id, h$name))
      }
    }
  }

  lines <- c(lines, "}")
  paste(lines, collapse = "\n")
}

#' Render a Petri net as a bipartite DOT graph
#'
#' Species are circles, transitions are boxes. Input/output arcs
#' connect them. Uses DiagrammeR for rendering.
#' @param pn A Petri net ACSet
#' @examples
#' pn <- acsets::ACSet(acsets::BasicSchema(
#'   obs = c("S", "T", "I", "O"),
#'   homs = list(acsets::hom("is", "I", "S"), acsets::hom("it", "I", "T"),
#'              acsets::hom("os", "O", "S"), acsets::hom("ot", "O", "T"))))
#' acsets::add_parts(pn, "S", 2)
#' acsets::add_parts(pn, "T", 1)
#' acsets::add_part(pn, "I", is = 1L, it = 1L)
#' acsets::add_part(pn, "I", is = 2L, it = 1L)
#' acsets::add_part(pn, "O", os = 1L, ot = 1L)
#' cat(petri_to_dot(pn))
#' @export
petri_to_dot <- function(pn) {
  schema <- pn@schema
  lines <- c("digraph PetriNet {", "  rankdir=LR;")

  # Species nodes (circles)
  n_s <- acsets::nparts(pn, "S")
  for (i in seq_len(n_s)) {
    label <- if (acsets::has_subpart(pn, "sname")) {
      val <- acsets::subpart(pn, i, "sname")
      if (!is.na(val)) val else paste0("S", i)
    } else paste0("S", i)
    lines <- c(lines, sprintf('  S_%d [label="%s" shape=circle style=filled fillcolor=lightskyblue];', i, label))
  }

  # Transition nodes (boxes)
  n_t <- acsets::nparts(pn, "T")
  for (i in seq_len(n_t)) {
    label <- if (acsets::has_subpart(pn, "tname")) {
      val <- acsets::subpart(pn, i, "tname")
      if (!is.na(val)) val else paste0("T", i)
    } else paste0("T", i)
    lines <- c(lines, sprintf('  T_%d [label="%s" shape=box style=filled fillcolor=lightsalmon];', i, label))
  }

  # Input arcs (S → T)
  n_i <- acsets::nparts(pn, "I")
  for (i in seq_len(n_i)) {
    s <- acsets::subpart(pn, i, "is")
    t <- acsets::subpart(pn, i, "it")
    if (!is.na(s) && !is.na(t)) {
      lines <- c(lines, sprintf("  S_%d -> T_%d;", s, t))
    }
  }

  # Output arcs (T → S)
  n_o <- acsets::nparts(pn, "O")
  for (i in seq_len(n_o)) {
    s <- acsets::subpart(pn, i, "os")
    t <- acsets::subpart(pn, i, "ot")
    if (!is.na(s) && !is.na(t)) {
      lines <- c(lines, sprintf("  T_%d -> S_%d;", t, s))
    }
  }

  lines <- c(lines, "}")
  paste(lines, collapse = "\n")
}

#' Render a UWD as a DOT diagram
#'
#' Boxes are rectangles, junctions are small circles,
#' outer ports are shown at the boundary.
#' @param w A UWD ACSet
#' @examples
#' w <- uwd(c("s", "r"), c("s", "i"), c("i", "r"))
#' cat(uwd_to_dot(w))
#' \donttest{
#' to_graphviz(w)
#' }
#' @export
uwd_to_dot <- function(w) {
  lines <- c("graph UWD {", "  rankdir=LR;")

  # Junctions
  n_j <- acsets::nparts(w, "Junction")
  for (j in seq_len(n_j)) {
    label <- if (acsets::has_subpart(w, "name")) {
      val <- acsets::subpart(w, j, "name")
      if (!is.na(val)) val else paste0("J", j)
    } else paste0("J", j)
    lines <- c(lines, sprintf('  J_%d [label="%s" shape=circle width=0.3 style=filled fillcolor=gray90];', j, label))
  }

  # Boxes
  n_b <- acsets::nparts(w, "Box")
  for (b in seq_len(n_b)) {
    lines <- c(lines, sprintf('  B_%d [label="Box %d" shape=box style=filled fillcolor=lightyellow];', b, b))
  }

  # Outer ports (diamonds at the boundary)
  n_op <- acsets::nparts(w, "OuterPort")
  for (op in seq_len(n_op)) {
    oj <- acsets::subpart(w, op, "outer_junction")
    if (!is.na(oj)) {
      lines <- c(lines, sprintf('  OP_%d [label="" shape=diamond width=0.2 style=filled fillcolor=black];', op))
      lines <- c(lines, sprintf("  OP_%d -- J_%d;", op, oj))
    }
  }

  # Ports → Junction edges
  n_p <- acsets::nparts(w, "Port")
  for (p in seq_len(n_p)) {
    b <- acsets::subpart(w, p, "box")
    j <- acsets::subpart(w, p, "junction")
    if (!is.na(b) && !is.na(j)) {
      lines <- c(lines, sprintf("  B_%d -- J_%d;", b, j))
    }
  }

  lines <- c(lines, "}")
  paste(lines, collapse = "\n")
}
