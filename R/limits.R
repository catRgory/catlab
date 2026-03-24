# Limits and colimits of ACSets --------------------------------------------
# Limits: product, pullback, equalizer, terminal
# Colimits: coproduct, pushout, coequalizer, initial

#' Coproduct (disjoint union) with injection morphisms
#' @param acs1 First ACSet
#' @param acs2 Second ACSet
#' @export
coproduct <- function(acs1, acs2) {
  result <- acsets::disjoint_union(acs1, acs2)
  schema <- acs1@schema

  # Build injection morphisms
  inj1_comp <- list()
  inj2_comp <- list()
  for (ob in acsets::objects(schema)) {
    n1 <- acsets::nparts(acs1, ob)
    n2 <- acsets::nparts(acs2, ob)
    inj1_comp[[ob]] <- if (n1 > 0L) seq_len(n1) else integer(0)
    inj2_comp[[ob]] <- if (n2 > 0L) seq.int(n1 + 1L, n1 + n2) else integer(0)
  }

  list(
    coproduct = result,
    inj1 = ACSetTransformation(inj1_comp, acs1, result),
    inj2 = ACSetTransformation(inj2_comp, acs2, result)
  )
}

#' Pushout of ACSets along two morphisms from a common apex
#'
#' Given f: A → B and g: A → C, compute the pushout B +_A C.
#' @param f ACSetTransformation A → B
#' @param g ACSetTransformation A → C
#' @export
pushout <- function(f, g) {
  schema <- f@dom_acset@schema
  B <- f@codom_acset
  C <- g@codom_acset

  # Start with coproduct B + C
  coprod <- coproduct(B, C)
  result <- coprod$coproduct

  # Build equivalence classes: for each part in A, merge f(a) in B with g(a) in C
  # Use union-find per object type
  for (ob in acsets::objects(schema)) {
    n_B <- acsets::nparts(B, ob)
    n_C <- acsets::nparts(C, ob)
    n_total <- n_B + n_C
    if (n_total == 0L) next

    # Simple union-find
    parent <- seq_len(n_total)
    find <- function(x) {
      while (parent[x] != x) {
        parent[x] <<- parent[parent[x]]
        x <- parent[x]
      }
      x
    }
    union <- function(x, y) {
      rx <- find(x)
      ry <- find(y)
      if (rx != ry) parent[rx] <<- ry
    }

    # For each a in A: union(inj1(f(a)), inj2(g(a)))
    n_A <- acsets::nparts(f@dom_acset, ob)
    for (a in seq_len(n_A)) {
      b_id <- f@components[[ob]][a]           # in B, 1-indexed
      c_id <- g@components[[ob]][a] + n_B     # in B+C, offset
      union(b_id, c_id)
    }

    # Compute canonical representatives
    reps <- vapply(seq_len(n_total), find, integer(1))
    unique_reps <- unique(reps)
    new_id_map <- integer(n_total)
    for (i in seq_along(unique_reps)) {
      new_id_map[reps == unique_reps[i]] <- i
    }

    # Build quotient: create new ACSet parts and remap
    # Store the mapping for later hom remapping
    coprod$inj1@components[[ob]] <- if (n_B > 0L) new_id_map[seq_len(n_B)] else integer(0)
    coprod$inj2@components[[ob]] <- if (n_C > 0L) new_id_map[seq.int(n_B + 1L, n_B + n_C)] else integer(0)
  }

  # Rebuild the result ACSet using the quotient mapping
  n_parts_new <- list()
  for (ob in acsets::objects(schema)) {
    n_parts_new[[ob]] <- max(c(coprod$inj1@components[[ob]], coprod$inj2@components[[ob]], 0L))
  }

  # Create fresh result
  idx <- names(which(vapply(result@.data$index_config, function(ic) ic != "none", logical(1))))
  quotient <- acsets::ACSet(schema, index = idx)
  for (ob in acsets::objects(schema)) {
    if (n_parts_new[[ob]] > 0L) acsets::add_parts(quotient, ob, n_parts_new[[ob]])
  }

  # Set homs: prefer B's values, then C's
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    # From B
    n_B <- acsets::nparts(B, ob_from)
    for (i in seq_len(n_B)) {
      val <- acsets::subpart(B, i, h$name)
      if (!is.na(val)) {
        new_from <- coprod$inj1@components[[ob_from]][i]
        new_to <- coprod$inj1@components[[ob_to]][val]
        acsets::set_subpart(quotient, new_from, h$name, new_to)
      }
    }
    # From C
    n_C <- acsets::nparts(C, ob_from)
    for (i in seq_len(n_C)) {
      val <- acsets::subpart(C, i, h$name)
      if (!is.na(val)) {
        new_from <- coprod$inj2@components[[ob_from]][i]
        new_to <- coprod$inj2@components[[ob_to]][val]
        acsets::set_subpart(quotient, new_from, h$name, new_to)
      }
    }
  }

  # Set attrs similarly
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n_B <- acsets::nparts(B, ob_from)
    for (i in seq_len(n_B)) {
      val <- acsets::subpart(B, i, a$name)
      if (!is.na(val)) {
        new_from <- coprod$inj1@components[[ob_from]][i]
        acsets::set_subpart(quotient, new_from, a$name, val)
      }
    }
    n_C <- acsets::nparts(C, ob_from)
    for (i in seq_len(n_C)) {
      val <- acsets::subpart(C, i, a$name)
      if (!is.na(val)) {
        new_from <- coprod$inj2@components[[ob_from]][i]
        acsets::set_subpart(quotient, new_from, a$name, val)
      }
    }
  }

  # Update injection morphisms to point to quotient
  coprod$inj1@codom_acset <- quotient
  coprod$inj2@codom_acset <- quotient

  list(
    pushout = quotient,
    inj1 = coprod$inj1,
    inj2 = coprod$inj2
  )
}


# Product (cartesian product) -----------------------------------------------

#' Product (categorical product) of two ACSets
#'
#' Computes the categorical product A × B with projection morphisms.
#' For each object type, parts are all pairs (a, b). Homs and attrs
#' are paired componentwise.
#'
#' @param acs1 First ACSet
#' @param acs2 Second ACSet
#' @returns List with \code{product}, \code{proj1}, \code{proj2}
#' @export
product <- function(acs1, acs2) {
  schema <- acs1@schema

  # Compute product sizes and build pair indices per object
  pair_info <- list()
  for (ob in acsets::objects(schema)) {
    n1 <- acsets::nparts(acs1, ob)
    n2 <- acsets::nparts(acs2, ob)
    if (n1 == 0L || n2 == 0L) {
      pair_info[[ob]] <- list(n = 0L, idx1 = integer(0), idx2 = integer(0))
    } else {
      # All pairs (i, j) for i in 1:n1, j in 1:n2
      grid <- expand.grid(a = seq_len(n1), b = seq_len(n2))
      pair_info[[ob]] <- list(
        n = nrow(grid),
        idx1 = grid$a,
        idx2 = grid$b
      )
    }
  }

  # Create result ACSet
  result <- acsets::ACSet(schema)
  for (ob in acsets::objects(schema)) {
    if (pair_info[[ob]]$n > 0L)
      acsets::add_parts(result, ob, pair_info[[ob]]$n)
  }

  # Set homs: for pair (a, b) in dom, hom maps to pair (h1(a), h2(b)) in codom
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n <- pair_info[[ob_from]]$n
    if (n == 0L) next

    vals1 <- acsets::subpart(acs1, pair_info[[ob_from]]$idx1, h$name)
    vals2 <- acsets::subpart(acs2, pair_info[[ob_from]]$idx2, h$name)

    # Map (h1(a), h2(b)) to the product index in codom
    n2_codom <- acsets::nparts(acs2, ob_to)
    if (n2_codom == 0L) next
    mapped <- (vals1 - 1L) * n2_codom + vals2
    acsets::set_subpart(result, seq_len(n), h$name, mapped)
  }

  # Set attrs: must agree; use acs1's value (product attr is same on both)
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n <- pair_info[[ob_from]]$n
    if (n == 0L) next
    vals <- acsets::subpart(acs1, pair_info[[ob_from]]$idx1, a$name)
    acsets::set_subpart(result, seq_len(n), a$name, vals)
  }

  # Build projection morphisms
  proj1_comp <- list()
  proj2_comp <- list()
  for (ob in acsets::objects(schema)) {
    proj1_comp[[ob]] <- pair_info[[ob]]$idx1
    proj2_comp[[ob]] <- pair_info[[ob]]$idx2
  }

  list(
    product = result,
    proj1 = ACSetTransformation(proj1_comp, result, acs1),
    proj2 = ACSetTransformation(proj2_comp, result, acs2)
  )
}


# Pullback (fiber product) -------------------------------------------------

#' Pullback of ACSets along a cospan
#'
#' Given f: B → D and g: C → D, compute the pullback B ×_D C, consisting
#' of pairs (b, c) where f(b) = g(c) for every object type.
#'
#' @param f ACSetTransformation B → D
#' @param g ACSetTransformation C → D
#' @returns List with \code{pullback}, \code{proj1}, \code{proj2}
#' @export
pullback <- function(f, g) {
  schema <- f@dom_acset@schema
  B <- f@dom_acset
  C <- g@dom_acset

  # For each object type, find pairs (b, c) where f(b) = g(c)
  pair_info <- list()
  for (ob in acsets::objects(schema)) {
    n_B <- acsets::nparts(B, ob)
    n_C <- acsets::nparts(C, ob)
    if (n_B == 0L || n_C == 0L) {
      pair_info[[ob]] <- list(n = 0L, idx_B = integer(0), idx_C = integer(0))
      next
    }
    f_comp <- f@components[[ob]]
    g_comp <- g@components[[ob]]

    # Find all pairs where f(b) = g(c)
    idx_B <- integer(0)
    idx_C <- integer(0)
    # Build index: d → list of c with g(c) = d
    g_inv <- split(seq_len(n_C), g_comp)
    for (b in seq_len(n_B)) {
      d <- as.character(f_comp[b])
      cs <- g_inv[[d]]
      if (length(cs) > 0L) {
        idx_B <- c(idx_B, rep(b, length(cs)))
        idx_C <- c(idx_C, cs)
      }
    }
    pair_info[[ob]] <- list(n = length(idx_B), idx_B = idx_B, idx_C = idx_C)
  }

  # Create result ACSet
  result <- acsets::ACSet(schema)
  for (ob in acsets::objects(schema)) {
    if (pair_info[[ob]]$n > 0L)
      acsets::add_parts(result, ob, pair_info[[ob]]$n)
  }

  # Set homs: for pair (b, c) in dom, h maps to pair (h_B(b), h_C(c)) in codom
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n <- pair_info[[ob_from]]$n
    if (n == 0L) next

    hvals_B <- acsets::subpart(B, pair_info[[ob_from]]$idx_B, h$name)
    hvals_C <- acsets::subpart(C, pair_info[[ob_from]]$idx_C, h$name)

    # Map (h_B(b), h_C(c)) to the pullback index in codom
    # Build lookup: (b_idx, c_idx) → pullback part id for codom
    codom_pairs <- pair_info[[ob_to]]
    if (codom_pairs$n == 0L) next

    lookup <- new.env(hash = TRUE, parent = emptyenv())
    for (k in seq_len(codom_pairs$n)) {
      key <- paste0(codom_pairs$idx_B[k], "_", codom_pairs$idx_C[k])
      assign(key, k, envir = lookup)
    }

    mapped <- integer(n)
    for (i in seq_len(n)) {
      key <- paste0(hvals_B[i], "_", hvals_C[i])
      mapped[i] <- get(key, envir = lookup)
    }
    acsets::set_subpart(result, seq_len(n), h$name, mapped)
  }

  # Set attrs from B (pullback inherits attrs from first component)
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n <- pair_info[[ob_from]]$n
    if (n == 0L) next
    vals <- acsets::subpart(B, pair_info[[ob_from]]$idx_B, a$name)
    acsets::set_subpart(result, seq_len(n), a$name, vals)
  }

  # Build projections
  proj1_comp <- list()
  proj2_comp <- list()
  for (ob in acsets::objects(schema)) {
    proj1_comp[[ob]] <- pair_info[[ob]]$idx_B
    proj2_comp[[ob]] <- pair_info[[ob]]$idx_C
  }

  list(
    pullback = result,
    proj1 = ACSetTransformation(proj1_comp, result, B),
    proj2 = ACSetTransformation(proj2_comp, result, C)
  )
}


# Equalizer -----------------------------------------------------------------

#' Equalizer of two parallel ACSet transformations
#'
#' Given f, g: A → B, compute the subobject of A where f and g agree.
#'
#' @param f ACSetTransformation A → B
#' @param g ACSetTransformation A → B
#' @returns List with \code{equalizer} (ACSet) and \code{incl} (inclusion morphism)
#' @export
equalizer <- function(f, g) {
  schema <- f@dom_acset@schema
  A <- f@dom_acset

  # For each object type, find parts where f(a) = g(a)
  keep <- list()
  for (ob in acsets::objects(schema)) {
    f_comp <- f@components[[ob]]
    g_comp <- g@components[[ob]]
    keep[[ob]] <- which(f_comp == g_comp)
  }

  # Create subobject ACSet
  result <- acsets::ACSet(schema)
  id_map <- list()  # old id → new id
  for (ob in acsets::objects(schema)) {
    n <- length(keep[[ob]])
    if (n > 0L) acsets::add_parts(result, ob, n)
    id_map[[ob]] <- integer(acsets::nparts(A, ob))
    id_map[[ob]][keep[[ob]]] <- seq_len(n)
  }

  # Set homs
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n <- length(keep[[ob_from]])
    if (n == 0L) next
    old_vals <- acsets::subpart(A, keep[[ob_from]], h$name)
    new_vals <- id_map[[ob_to]][old_vals]
    acsets::set_subpart(result, seq_len(n), h$name, new_vals)
  }

  # Set attrs
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n <- length(keep[[ob_from]])
    if (n == 0L) next
    vals <- acsets::subpart(A, keep[[ob_from]], a$name)
    acsets::set_subpart(result, seq_len(n), a$name, vals)
  }

  # Inclusion morphism
  incl_comp <- list()
  for (ob in acsets::objects(schema)) {
    incl_comp[[ob]] <- keep[[ob]]
  }

  list(
    equalizer = result,
    incl = ACSetTransformation(incl_comp, result, A)
  )
}


# Coequalizer ---------------------------------------------------------------

#' Coequalizer of two parallel ACSet transformations
#'
#' Given f, g: A → B, identify f(a) with g(a) for all a.
#'
#' @param f ACSetTransformation A → B
#' @param g ACSetTransformation A → B
#' @returns List with \code{coequalizer} (ACSet) and \code{proj} (projection morphism)
#' @export
coequalizer <- function(f, g) {
  schema <- f@dom_acset@schema
  B <- f@codom_acset

  # For each object, build equivalence classes identifying f(a) ~ g(a)
  quotient_map <- list()
  n_new <- list()

  for (ob in acsets::objects(schema)) {
    n <- acsets::nparts(B, ob)
    if (n == 0L) {
      quotient_map[[ob]] <- integer(0)
      n_new[[ob]] <- 0L
      next
    }
    parent <- seq_len(n)
    find <- function(x) {
      while (parent[x] != x) { parent[x] <<- parent[parent[x]]; x <- parent[x] }
      x
    }
    union <- function(x, y) {
      rx <- find(x); ry <- find(y)
      if (rx != ry) parent[rx] <<- ry
    }

    n_A <- acsets::nparts(f@dom_acset, ob)
    for (a in seq_len(n_A)) {
      union(f@components[[ob]][a], g@components[[ob]][a])
    }

    reps <- vapply(seq_len(n), find, integer(1))
    unique_reps <- unique(reps)
    qmap <- integer(n)
    for (i in seq_along(unique_reps)) qmap[reps == unique_reps[i]] <- i
    quotient_map[[ob]] <- qmap
    n_new[[ob]] <- length(unique_reps)
  }

  # Create quotient ACSet
  result <- acsets::ACSet(schema)
  for (ob in acsets::objects(schema)) {
    if (n_new[[ob]] > 0L) acsets::add_parts(result, ob, n_new[[ob]])
  }

  # Set homs via B's values remapped through quotient
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n <- acsets::nparts(B, ob_from)
    if (n == 0L) next
    old_vals <- acsets::subpart(B, NULL, h$name)
    # For each equivalence class, take value from any representative
    new_n <- n_new[[ob_from]]
    new_vals <- integer(new_n)
    for (i in seq_len(n)) {
      qi <- quotient_map[[ob_from]][i]
      if (new_vals[qi] == 0L && !is.na(old_vals[i])) {
        new_vals[qi] <- quotient_map[[ob_to]][old_vals[i]]
      }
    }
    acsets::set_subpart(result, seq_len(new_n), h$name, new_vals)
  }

  # Set attrs
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n <- acsets::nparts(B, ob_from)
    if (n == 0L) next
    old_vals <- acsets::subpart(B, NULL, a$name)
    new_n <- n_new[[ob_from]]
    new_vals <- vector("list", new_n)
    for (i in seq_len(n)) {
      qi <- quotient_map[[ob_from]][i]
      if (is.null(new_vals[[qi]]) && !is.na(old_vals[i])) {
        new_vals[[qi]] <- old_vals[i]
      }
    }
    vals <- unlist(new_vals)
    if (length(vals) == new_n)
      acsets::set_subpart(result, seq_len(new_n), a$name, vals)
  }

  # Projection morphism
  proj_comp <- list()
  for (ob in acsets::objects(schema)) {
    proj_comp[[ob]] <- quotient_map[[ob]]
  }

  list(
    coequalizer = result,
    proj = ACSetTransformation(proj_comp, B, result)
  )
}


# Terminal and initial objects -----------------------------------------------

#' Terminal object: exactly one part per object type
#' @param schema A BasicSchema
#' @returns An ACSet with 1 part per object
#' @export
terminal <- function(schema) {
  result <- acsets::ACSet(schema)
  for (ob in acsets::objects(schema)) {
    acsets::add_parts(result, ob, 1L)
  }
  # All homs must map 1 → 1

  for (h in acsets::homs(schema)) {
    acsets::set_subpart(result, 1L, h$name, 1L)
  }
  result
}

#' Initial object: zero parts
#' @param schema A BasicSchema
#' @returns An ACSet with 0 parts
#' @export
initial <- function(schema) {
  acsets::ACSet(schema)
}

#' Unique morphism to terminal object
#' @param acs An ACSet
#' @returns ACSetTransformation to terminal(acs@@schema)
#' @export
to_terminal <- function(acs) {
  schema <- acs@schema
  term <- terminal(schema)
  comp <- list()
  for (ob in acsets::objects(schema)) {
    comp[[ob]] <- rep(1L, acsets::nparts(acs, ob))
  }
  ACSetTransformation(comp, acs, term)
}

#' Unique morphism from initial object
#' @param acs An ACSet
#' @returns ACSetTransformation from initial(acs@@schema)
#' @export
from_initial <- function(acs) {
  schema <- acs@schema
  init <- initial(schema)
  comp <- list()
  for (ob in acsets::objects(schema)) {
    comp[[ob]] <- integer(0)
  }
  ACSetTransformation(comp, init, acs)
}
