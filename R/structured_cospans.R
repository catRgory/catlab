# Structured Cospans ----------------------------------------------------------
# A structured cospan is a cospan in a category of structured objects (ACSets)
# with feet in a simpler category (FinSet, represented as discrete ACSets).
#
# An open system has:
#   - An apex (the full system, e.g. a Petri net)
#   - Legs (morphisms from discrete "feet" into the apex)
#   - Feet represent the exposed interface (e.g. which species are ports)
#
# Composition glues two open systems at a shared foot via pushout.
# Monoidal product places two open systems side-by-side via coproduct.

#' Structured multicospan (open system with multiple legs/feet)
#'
#' Represents an open ACSet: an apex with multiple legs mapping discrete
#' feet into the apex. Each leg identifies which parts of the apex are
#' "exposed" at that interface.
#'
#' @export
StructuredCospan <- S7::new_class("StructuredCospan",
  properties = list(
    apex = acsets::ACSet,
    legs = S7::class_list,  # list of ACSetTransformations: feet_i -> apex
    interface_ob = S7::class_character  # which object type forms the interface
  ),
  validator = function(self) {
    for (i in seq_along(self@legs)) {
      leg <- self@legs[[i]]
      if (!identical(leg@codom_acset, self@apex)) {
        return(sprintf("Leg %d codomain must equal apex", i))
      }
    }
    NULL
  }
)

#' Create a structured cospan (open system)
#'
#' @param apex ACSet (the full system)
#' @param legs List of ACSetTransformations from feet into apex
#' @param interface_ob Character: which object type forms the interface
#' @return StructuredCospan
#' @export
structured_cospan <- function(apex, legs, interface_ob) {
  StructuredCospan(
    apex = apex,
    legs = legs,
    interface_ob = interface_ob
  )
}

#' Create a discrete (empty) ACSet with n parts in a given object
#'
#' The L functor: FinSet -> ACSet maps a finite set of size n to an ACSet
#' with n parts in the interface object and nothing else.
#'
#' @param schema BasicSchema
#' @param ob Character: which object to populate
#' @param n Integer: how many parts
#' @return ACSet
#' @export
discrete_acset <- function(schema, ob, n) {
  acs <- acsets::ACSet(schema)
  if (n > 0L) acsets::add_parts(acs, ob, n)
  acs
}

#' Create a leg morphism from a discrete foot into an apex
#'
#' @param schema BasicSchema
#' @param interface_ob Character: which object type
#' @param indices Integer vector: which apex parts this foot maps to
#' @param apex ACSet: the target
#' @return ACSetTransformation
#' @export
make_leg <- function(schema, interface_ob, indices, apex) {
  n <- length(indices)
  foot <- discrete_acset(schema, interface_ob, n)

  # Build components: interface_ob gets indices, all others empty
  comp <- list()
  for (ob in acsets::objects(schema)) {
    if (ob == interface_ob) {
      comp[[ob]] <- as.integer(indices)
    } else {
      comp[[ob]] <- integer(0)
    }
  }

  ACSetTransformation(
    components = comp,
    dom_acset = foot,
    codom_acset = apex
  )
}

#' Open an ACSet by specifying interface legs
#'
#' Create a structured cospan from an ACSet and leg specifications.
#' Each leg is an integer vector of part indices in the interface object.
#'
#' @param apex ACSet
#' @param interface_ob Character: which object type forms the interface
#' @param ... Integer vectors: each argument is a leg (indices into interface_ob)
#' @return StructuredCospan
#' @export
open_acset <- function(apex, interface_ob, ...) {
  leg_specs <- list(...)
  schema <- apex@schema
  legs <- lapply(leg_specs, function(indices) {
    make_leg(schema, interface_ob, indices, apex)
  })
  structured_cospan(apex, legs, interface_ob)
}

#' Compose two structured cospans along a shared foot
#'
#' Given M: A -> X <- B and N: B -> Y <- C (where B is the shared foot),
#' compute the composite M;N: A -> Z <- C via pushout of X and Y over B.
#'
#' @param M StructuredCospan with at least 2 legs (left=first, right=last)
#' @param N StructuredCospan with at least 2 legs (left=first, right=last)
#' @return StructuredCospan with 2 legs: left from M, right from N
#' @export
compose_cospans <- function(M, N) {
  if (!identical(M@interface_ob, N@interface_ob)) {
    stop("Cannot compose cospans with different interface objects")
  }

  # Right leg of M and left leg of N share a foot
  right_M <- M@legs[[length(M@legs)]]
  left_N <- N@legs[[1]]

  # Check feet are compatible (same number of interface parts)
  n_right <- acsets::nparts(right_M@dom_acset, M@interface_ob)
  n_left <- acsets::nparts(left_N@dom_acset, N@interface_ob)
  if (n_right != n_left) {
    stop(sprintf("Shared foot mismatch: right leg has %d, left leg has %d parts",
                 n_right, n_left))
  }

  # Build the shared foot B as a discrete ACSet
  schema <- M@apex@schema
  B <- discrete_acset(schema, M@interface_ob, n_right)

  # Build morphisms B -> X (apex of M) and B -> Y (apex of N)
  # from the right leg of M and left leg of N
  comp_BX <- list()
  comp_BY <- list()
  for (ob in acsets::objects(schema)) {
    if (ob == M@interface_ob) {
      comp_BX[[ob]] <- right_M@components[[ob]]
      comp_BY[[ob]] <- left_N@components[[ob]]
    } else {
      comp_BX[[ob]] <- integer(0)
      comp_BY[[ob]] <- integer(0)
    }
  }

  f <- ACSetTransformation(components = comp_BX, dom_acset = B, codom_acset = M@apex)
  g <- ACSetTransformation(components = comp_BY, dom_acset = B, codom_acset = N@apex)

  # Pushout of f and g gives the composed apex
  po <- pushout(f, g)

  # Build new legs: left legs of M through inj1, right legs of N through inj2
  new_legs <- list()

  # Left legs of M (all except the last)
  for (i in seq_len(max(1, length(M@legs) - 1))) {
    if (i <= length(M@legs) - 1 || length(M@legs) == 1) {
      new_legs[[length(new_legs) + 1L]] <- compose_transformations(
        M@legs[[i]], po$inj1
      )
    }
  }

  # Right legs of N (all except the first)
  for (i in seq.int(min(2, length(N@legs)), length(N@legs))) {
    if (i >= 2 || length(N@legs) == 1) {
      new_legs[[length(new_legs) + 1L]] <- compose_transformations(
        N@legs[[i]], po$inj2
      )
    }
  }

  structured_cospan(po$pushout, new_legs, M@interface_ob)
}

#' Monoidal product of two structured cospans (side-by-side)
#'
#' Places M and N side by side via coproduct. No identification.
#'
#' @param M StructuredCospan
#' @param N StructuredCospan
#' @return StructuredCospan
#' @export
otimes_cospans <- function(M, N) {
  if (!identical(M@interface_ob, N@interface_ob)) {
    stop("Cannot tensor cospans with different interface objects")
  }

  cop <- coproduct(M@apex, N@apex)

  # Compose each leg with the appropriate injection
  new_legs <- list()
  for (leg in M@legs) {
    new_legs[[length(new_legs) + 1L]] <- compose_transformations(leg, cop$inj1)
  }
  for (leg in N@legs) {
    new_legs[[length(new_legs) + 1L]] <- compose_transformations(leg, cop$inj2)
  }

  structured_cospan(cop$coproduct, new_legs, M@interface_ob)
}

#' Compose a list of structured cospans via a UWD
#'
#' Given a UWD (undirected wiring diagram) and a list of structured cospans
#' (one per box), compose them by identifying legs at shared junctions.
#'
#' This is the general oapply for structured cospans: it takes the coproduct
#' of all apexes, then uses the UWD's wiring to build a pushout that
#' identifies interface parts at shared junctions.
#'
#' @param w UWD (an ACSet on SchUWD)
#' @param cospans List of StructuredCospan objects (one per box)
#' @return StructuredCospan with legs from outer ports
#' @export
oapply_cospans <- function(w, cospans) {
  n_boxes <- acsets::nparts(w, "Box")
  if (length(cospans) != n_boxes) {
    stop(sprintf("Expected %d cospans (one per box), got %d", n_boxes, length(cospans)))
  }

  if (n_boxes == 0L) {
    # Empty UWD: return empty cospan
    schema <- cospans[[1]]@apex@schema
    interface_ob <- cospans[[1]]@interface_ob
    empty <- acsets::ACSet(schema)
    return(structured_cospan(empty, list(), interface_ob))
  }

  schema <- cospans[[1]]@apex@schema
  interface_ob <- cospans[[1]]@interface_ob
  n_junctions <- acsets::nparts(w, "Junction")

  # Step 1: Coproduct of all apexes
  result_apex <- cospans[[1]]@apex
  injections <- list()
  injections[[1]] <- id_transformation(result_apex)

  for (i in seq.int(2, n_boxes)) {
    cop <- coproduct(result_apex, cospans[[i]]@apex)
    # Update previous injections through the new coproduct
    for (j in seq_len(i - 1L)) {
      injections[[j]] <- compose_transformations(injections[[j]], cop$inj1)
    }
    injections[[i]] <- cop$inj2
    result_apex <- cop$coproduct
  }

  # Step 2: Build junction → apex parts mapping
  # For each port, find which box it belongs to, which cospan leg it corresponds to,
  # and what apex parts it maps to (after injection)
  n_ports <- acsets::nparts(w, "Port")
  junction_parts <- vector("list", n_junctions)
  for (j in seq_len(n_junctions)) junction_parts[[j]] <- integer(0)

  # Track port → leg assignment per box
  box_port_count <- integer(n_boxes)
  for (p in seq_len(n_ports)) {
    box_idx <- acsets::subpart(w, p, "box")
    junc_idx <- acsets::subpart(w, p, "junction")
    box_port_count[box_idx] <- box_port_count[box_idx] + 1L
    leg_idx <- box_port_count[box_idx]

    # Get the parts from this cospan's leg, mapped through injection
    cospan <- cospans[[box_idx]]
    if (leg_idx <= length(cospan@legs)) {
      leg <- cospan@legs[[leg_idx]]
      inj <- injections[[box_idx]]
      # The leg maps foot parts to apex parts; compose with injection
      mapped <- inj@components[[interface_ob]][leg@components[[interface_ob]]]
      junction_parts[[junc_idx]] <- c(junction_parts[[junc_idx]], mapped)
    }
  }

  # Step 3: Build equivalence classes via union-find for shared junctions
  n_result <- acsets::nparts(result_apex, interface_ob)
  parent <- seq_len(n_result)
  find <- function(x) {
    while (parent[x] != x) { parent[x] <<- parent[parent[x]]; x <- parent[x] }
    x
  }
  union <- function(a, b) {
    ra <- find(a); rb <- find(b)
    if (ra != rb) parent[rb] <<- ra
  }

  # Union all parts at same junction
  for (j in seq_len(n_junctions)) {
    parts <- junction_parts[[j]]
    if (length(parts) >= 2L) {
      for (k in seq.int(2, length(parts))) {
        union(parts[1], parts[k])
      }
    }
  }

  # Step 4: Compute quotient (only on the interface object)
  # Build canonical representative map
  roots <- integer(n_result)
  for (i in seq_len(n_result)) roots[i] <- find(i)
  unique_roots <- unique(roots)
  quotient_map <- integer(n_result)
  for (i in seq_along(unique_roots)) quotient_map[roots == unique_roots[i]] <- i

  # Build the quotient ACSet via coequalizer-like construction
  # Create morphisms that identify the equivalence classes
  # Simple approach: build the full pushout from the junction constraints
  if (length(unique_roots) < n_result) {
    # There are identifications to make
    # Build source and target for the identifying morphisms
    # For each junction with multiple parts: create equations
    eq_src <- integer(0)
    eq_tgt <- integer(0)
    for (j in seq_len(n_junctions)) {
      parts <- junction_parts[[j]]
      if (length(parts) >= 2L) {
        for (k in seq.int(2, length(parts))) {
          eq_src <- c(eq_src, parts[1])
          eq_tgt <- c(eq_tgt, parts[k])
        }
      }
    }

    if (length(eq_src) > 0L) {
      # Build a pair of morphisms for the coequalizer
      n_eq <- length(eq_src)
      eq_acset <- discrete_acset(schema, interface_ob, n_eq)
      comp_f <- list()
      comp_g <- list()
      for (ob in acsets::objects(schema)) {
        if (ob == interface_ob) {
          comp_f[[ob]] <- eq_src
          comp_g[[ob]] <- eq_tgt
        } else {
          comp_f[[ob]] <- integer(0)
          comp_g[[ob]] <- integer(0)
        }
      }
      f_eq <- ACSetTransformation(comp_f, eq_acset, result_apex)
      g_eq <- ACSetTransformation(comp_g, eq_acset, result_apex)
      ceq <- coequalizer(f_eq, g_eq)
      result_apex <- ceq$coequalizer
      proj <- ceq$proj

      # Update injections through the coequalizer projection
      for (i in seq_len(n_boxes)) {
        injections[[i]] <- compose_transformations(injections[[i]], proj)
      }
    }
  }

  # Step 5: Build outer port legs
  n_outer <- acsets::nparts(w, "OuterPort")
  outer_legs <- list()
  if (n_outer > 0L) {
    # Group outer ports by their junction, preserving order
    outer_indices <- integer(n_outer)
    for (op in seq_len(n_outer)) {
      junc_idx <- acsets::subpart(w, op, "outer_junction")
      # Find a representative part at this junction
      parts <- junction_parts[[junc_idx]]
      if (length(parts) > 0L) {
        # Map through the final injection/projection
        # The first part at this junction, mapped through the composition
        # Find which box contributed the first part
        outer_indices[op] <- parts[1]
      }
    }

    # Map through the final quotient if there was a coequalizer
    if (exists("proj", inherits = FALSE)) {
      outer_indices <- proj@components[[interface_ob]][outer_indices]
    }

    # Create single leg for all outer ports
    outer_legs[[1]] <- make_leg(schema, interface_ob, outer_indices, result_apex)
  }

  structured_cospan(result_apex, outer_legs, interface_ob)
}

#' Extract the apex from a structured cospan
#'
#' @param sc StructuredCospan
#' @return ACSet
#' @export
cospan_apex <- function(sc) {
  sc@apex
}

#' Get the number of legs (feet) of a structured cospan
#'
#' @param sc StructuredCospan
#' @return integer
#' @export
nlegs <- function(sc) {
  length(sc@legs)
}

#' Get the foot sizes of a structured cospan
#'
#' @param sc StructuredCospan
#' @return integer vector
#' @export
foot_sizes <- function(sc) {
  vapply(sc@legs, function(leg) {
    acsets::nparts(leg@dom_acset, sc@interface_ob)
  }, integer(1))
}
