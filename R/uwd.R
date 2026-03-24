# Undirected Wiring Diagrams -----------------------------------------------
# UWDs represent how open systems compose by connecting junctions.

#' UWD Schema
#' @export
SchUWD <- acsets::BasicSchema(
  obs = c("Box", "Port", "OuterPort", "Junction"),
  homs = list(
    acsets::hom("box", "Port", "Box"),
    acsets::hom("junction", "Port", "Junction"),
    acsets::hom("outer_junction", "OuterPort", "Junction")
  ),
  attrtypes = "Name",
  attrs = list(
    acsets::attr_spec("name", "Junction", "Name")
  )
)

#' Undirected wiring diagrams
#'
#' `UWD` is the ACSet type constructor for undirected wiring diagrams.
#' `uwd()` is a convenience constructor using concise syntax.
#'
#' @param outer Character vector of outer junction names
#' @param ... For `uwd()`: box specifications as named character vectors.
#'   `infection = c("s", "i")` creates a box "infection" with ports connected
#'   to junctions "s" and "i".
#' @returns A UWD ACSet
#' @name UWD
#' @export
UWD <- acsets::acset_type(SchUWD, name = "UWD",
                           index = c("box", "junction", "outer_junction"))

#' Create a wiring diagram using relation-style DSL
#'
#' @param ... Named outer port variables (junction names exposed to outside)
#' @param .boxes A list of box specifications, each a named list with
#'   `name` and junction variable references
#' @returns A UWD ACSet
#' @export
relation <- function(..., .boxes = list()) {
  # Capture outer port junction names from ... arguments
  args <- as.list(match.call())[-1]
  args$.boxes <- NULL

  # Collect all junction names
  outer_names <- vapply(args, as.character, character(1))
  all_junctions <- unique(c(outer_names, unlist(lapply(.boxes, function(b) b$ports))))

  uwd <- UWD()

  # Add junctions
  junc_ids <- list()
  for (jn in all_junctions) {
    junc_ids[[jn]] <- acsets::add_part(uwd, "Junction", name = jn)
  }

  # Add outer ports
  for (jn in outer_names) {
    acsets::add_part(uwd, "OuterPort", outer_junction = junc_ids[[jn]])
  }

  # Add boxes and ports
  for (b in .boxes) {
    box_id <- acsets::add_part(uwd, "Box")
    for (jn in b$ports) {
      acsets::add_part(uwd, "Port", box = box_id, junction = junc_ids[[jn]])
    }
  }

  uwd
}

#' Shorthand for creating a relation box spec
#' @param name Box name
#' @param ... Junction names for the box ports
#' @export
box_spec <- function(name, ...) {
  list(name = name, ports = c(...))
}

#' @rdname UWD
#' @export
uwd <- function(outer, ...) {
  boxes <- list(...)
  all_junctions <- unique(c(outer, unlist(boxes)))

  result <- UWD()

  # Add junctions
  junc_ids <- list()
  for (jn in all_junctions) {
    junc_ids[[jn]] <- acsets::add_part(result, "Junction", name = jn)
  }

  # Add outer ports
  for (jn in outer) {
    acsets::add_part(result, "OuterPort", outer_junction = junc_ids[[jn]])
  }

  # Add boxes and ports
  for (i in seq_along(boxes)) {
    box_id <- acsets::add_part(result, "Box")
    for (jn in boxes[[i]]) {
      acsets::add_part(result, "Port", box = box_id, junction = junc_ids[[jn]])
    }
  }

  result
}
