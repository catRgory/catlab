# Homomorphism finding for ACSets -------------------------------------------
# Backtracking search for ACSet morphisms (natural transformations).

#' Find a homomorphism between two ACSets
#'
#' Uses backtracking search to find an ACSetTransformation from \code{pattern}
#' to \code{target}. Returns \code{NULL} if no homomorphism exists.
#'
#' @param pattern Source ACSet (typically small)
#' @param target Target ACSet (typically larger)
#' @param monic Logical; if TRUE, require injective components (monomorphism)
#' @param initial Optional named list of partial assignments to seed the search
#' @returns An ACSetTransformation, or NULL if none exists
#' @export
find_homomorphism <- function(pattern, target, monic = FALSE, initial = NULL) {
  result <- backtrack_search(pattern, target, monic = monic,
                             initial = initial, find_all = FALSE)
  if (length(result) == 0L) NULL else result[[1L]]
}

#' Find all homomorphisms between two ACSets
#'
#' @inheritParams find_homomorphism
#' @param limit Maximum number of homomorphisms to find (default: Inf)
#' @returns List of ACSetTransformations
#' @export
find_all_homomorphisms <- function(pattern, target, monic = FALSE,
                                   initial = NULL, limit = Inf) {
  backtrack_search(pattern, target, monic = monic,
                   initial = initial, find_all = TRUE, limit = limit)
}

#' Check if a homomorphism exists
#' @inheritParams find_homomorphism
#' @returns Logical
#' @export
is_homomorphic <- function(pattern, target, monic = FALSE) {
  !is.null(find_homomorphism(pattern, target, monic = monic))
}


# Internal backtracking search engine ----------------------------------------

backtrack_search <- function(pattern, target, monic = FALSE,
                             initial = NULL, find_all = FALSE, limit = Inf) {
  schema <- pattern@schema
  obs <- acsets::objects(schema)

  # Build assignment structure: list of (ob, part_id) to assign
  assignments <- list()
  for (ob in obs) {
    for (p in acsets::parts(pattern, ob)) {
      assignments[[length(assignments) + 1L]] <- list(ob = ob, part = p)
    }
  }

  n_assign <- length(assignments)
  if (n_assign == 0L) {
    # Empty pattern maps to anything
    comp <- list()
    for (ob in obs) comp[[ob]] <- integer(0)
    return(list(ACSetTransformation(comp, pattern, target)))
  }

  # Precompute hom constraints: for each assignment, which homs constrain it
  hom_constraints <- vector("list", n_assign)
  for (i in seq_len(n_assign)) {
    ob_i <- assignments[[i]]$ob
    p_i <- assignments[[i]]$part
    constraints <- list()
    for (h in acsets::homs(schema)) {
      if (h$dom == ob_i) {
        # Forward: if we assign pattern part p_i to target part t,
        # then h(t) must equal the assignment of h(p_i)
        h_val <- acsets::subpart(pattern, p_i, h$name)
        if (!is.na(h_val)) {
          constraints[[length(constraints) + 1L]] <- list(
            type = "forward", hom = h$name, codom_ob = h$codom, val = h_val
          )
        }
      }
      if (h$codom == ob_i) {
        # Backward: if we assign pattern part p_i, check that any already-assigned
        # part in h$dom that maps to p_i is consistent
        # (handled during candidate filtering)
      }
    }
    hom_constraints[[i]] <- constraints
  }

  # Current state
  state <- new.env(hash = TRUE, parent = emptyenv())
  state$mapping <- list()  # ob → (pattern_part → target_part)
  for (ob in obs) state$mapping[[ob]] <- integer(0)

  # Initialize with provided assignments
  if (!is.null(initial)) {
    for (ob in names(initial)) {
      state$mapping[[ob]] <- initial[[ob]]
    }
  }

  # Track used target parts per object (for monic constraint)
  state$used <- list()
  for (ob in obs) {
    state$used[[ob]] <- logical(acsets::nparts(target, ob))
    for (v in state$mapping[[ob]]) {
      if (v > 0L) state$used[[ob]][v] <- TRUE
    }
  }

  results <- list()

  # Get candidate target parts for assignment i
  get_candidates <- function(i) {
    ob <- assignments[[i]]$ob
    p <- assignments[[i]]$part
    n_target <- acsets::nparts(target, ob)
    if (n_target == 0L) return(integer(0))

    candidates <- seq_len(n_target)

    # Filter by monic constraint
    if (monic) {
      candidates <- candidates[!state$used[[ob]][candidates]]
    }

    # Filter by hom constraints (forward)
    for (con in hom_constraints[[i]]) {
      if (con$type == "forward") {
        # h(p) = con$val in pattern; need h(t) = mapping[con$codom_ob][con$val]
        assigned_to <- state$mapping[[con$codom_ob]]
        if (con$val <= length(assigned_to) && assigned_to[con$val] > 0L) {
          required <- assigned_to[con$val]
          ok <- vapply(candidates, function(t) {
            h_t <- acsets::subpart(target, t, con$hom)
            !is.na(h_t) && h_t == required
          }, logical(1))
          candidates <- candidates[ok]
        }
      }
    }

    # Filter by backward constraints: for any hom h with h$codom == ob,
    # if some already-assigned part q in h$dom has h(q) == p in pattern,
    # then h(mapping[h$dom][q]) must equal our candidate t
    for (h in acsets::homs(schema)) {
      if (h$dom == ob) {
        # Check that h maps candidate consistently
        h_p <- acsets::subpart(pattern, p, h$name)
        if (!is.na(h_p)) {
          assigned_codom <- state$mapping[[h$codom]]
          if (h_p <= length(assigned_codom) && assigned_codom[h_p] > 0L) {
            required <- assigned_codom[h_p]
            ok <- vapply(candidates, function(t) {
              acsets::subpart(target, t, h$name) == required
            }, logical(1))
            candidates <- candidates[ok]
          }
        }
      }
      if (h$codom == ob) {
        # For assigned parts in h$dom, check consistency
        assigned_dom <- state$mapping[[h$dom]]
        n_dom <- acsets::nparts(pattern, h$dom)
        for (q in seq_len(n_dom)) {
          if (q <= length(assigned_dom) && assigned_dom[q] > 0L) {
            h_q <- acsets::subpart(pattern, q, h$name)
            if (!is.na(h_q) && h_q == p) {
              # h(mapping[q]) must equal candidate
              required <- acsets::subpart(target, assigned_dom[q], h$name)
              candidates <- candidates[candidates == required]
            }
          }
        }
      }
    }

    candidates
  }

  # Recursive backtracking
  solve <- function(depth) {
    if (length(results) >= limit) return()

    if (depth > n_assign) {
      # All assigned — build transformation
      comp <- list()
      for (ob in obs) {
        comp[[ob]] <- state$mapping[[ob]]
      }
      results[[length(results) + 1L]] <<- ACSetTransformation(comp, pattern, target)
      return()
    }

    # Skip if already assigned (from initial)
    ob <- assignments[[depth]]$ob
    p <- assignments[[depth]]$part
    if (p <= length(state$mapping[[ob]]) && state$mapping[[ob]][p] > 0L) {
      solve(depth + 1L)
      return()
    }

    candidates <- get_candidates(depth)
    for (t in candidates) {
      # Assign
      old_len <- length(state$mapping[[ob]])
      if (p > old_len) {
        state$mapping[[ob]] <- c(state$mapping[[ob]], rep(0L, p - old_len))
      }
      state$mapping[[ob]][p] <- t
      state$used[[ob]][t] <- TRUE

      solve(depth + 1L)
      if (!find_all && length(results) > 0L) return()

      # Unassign
      state$mapping[[ob]][p] <- 0L
      state$used[[ob]][t] <- FALSE
    }
  }

  solve(1L)
  results
}
