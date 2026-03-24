# Algebraic graph rewriting --------------------------------------------------
# DPO (Double Pushout), SPO (Single Pushout), SqPO (Sesqui-Pushout)

#' Rewriting rules
#'
#' A rule is a span L ← I → R where:
#' - L is the pattern (left-hand side)
#' - I is the interface (preserved structure)
#' - R is the replacement (right-hand side)
#'
#' `Rule` is the S7 class; `rule()` is a convenience constructor.
#'
#' @param l ACSetTransformation I → L (left leg, pattern embedding)
#' @param r ACSetTransformation I → R (right leg, replacement embedding)
#' @param monic Logical; require match to be injective (default TRUE)
#' @param semantics Rewriting semantics: "DPO", "SPO", or "SqPO" (default "DPO")
#' @returns A Rule object
#' @examples
#' # DPO rule: delete an edge (keep both vertices)
#' L <- path_graph(2)           # 1 -> 2  (pattern: an edge)
#' I <- Graph(V = 2)            # 1  2    (interface: two vertices, no edge)
#' R <- Graph(V = 2)            # 1  2    (replacement: same)
#' l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
#' r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
#' rl <- rule(l, r)
#' # Apply to a triangle (3-cycle)
#' tri <- cycle_graph(3)
#' result <- rewrite(rl, tri)
#' ne(result)  # 2 (one edge deleted)
#' @name Rule
#' @export
Rule <- S7::new_class("Rule",
  properties = list(
    l = ACSetTransformation,   # I → L
    r = ACSetTransformation,   # I → R
    monic = S7::class_logical,
    semantics = S7::class_character
  ),
  validator = function(self) {
    if (!identical(self@l@dom_acset@schema, self@r@dom_acset@schema))
      return("Left and right legs must have the same domain schema")
    if (!identical(self@l@dom_acset, self@r@dom_acset))
      return("Left and right legs must share the same interface (domain)")
    if (!(self@semantics %in% c("DPO", "SPO", "SqPO")))
      return("semantics must be 'DPO', 'SPO', or 'SqPO'")
    NULL
  }
)

# Convenience constructor for when L and R share a common subgraph I
# specified via explicit morphisms

#' @rdname Rule
#' @export
rule <- function(l, r, monic = TRUE, semantics = "DPO") {
  Rule(l = l, r = r, monic = monic, semantics = semantics)
}


# Pushout complement --------------------------------------------------------

#' Compute pushout complement (DPO step 1)
#'
#' Given l: I → L and m: L → G, find K and morphisms ik: I → K, kg: K → G
#' such that the square (l, m, ik, kg) is a pushout.
#'
#' Requires the gluing conditions:
#' 1. No dangling edges: deletion of a vertex doesn't orphan edges
#' 2. Identification: distinct deleted items aren't identified by match
#'
#' @param l ACSetTransformation I → L
#' @param m ACSetTransformation L → G (match morphism)
#' @returns List with \code{K} (ACSet), \code{ik} (I → K), \code{kg} (K → G),
#'   or signals an error if gluing conditions fail.
#' @export
pushout_complement <- function(l, m) {
  schema <- l@dom_acset@schema
  I <- l@dom_acset
  L <- l@codom_acset
  G <- m@codom_acset

  # Determine which parts of G to keep:
  # Keep = G \ (m(L) \ m(l(I)))
  # i.e., remove parts of G that are in the image of m but not in m(l(I))

  keep_G <- list()     # per object: logical vector of which G-parts to keep
  m_image <- list()    # per object: which G-parts are in image of m
  ml_image <- list()   # per object: which G-parts are in image of m∘l

  for (ob in acsets::objects(schema)) {
    n_G <- acsets::nparts(G, ob)
    n_L <- acsets::nparts(L, ob)
    n_I <- acsets::nparts(I, ob)

    m_img <- logical(n_G)
    ml_img <- logical(n_G)

    for (j in seq_len(n_L)) m_img[m@components[[ob]][j]] <- TRUE
    for (j in seq_len(n_I)) {
      l_j <- l@components[[ob]][j]
      ml_img[m@components[[ob]][l_j]] <- TRUE
    }

    # Parts to delete: in m(L) but not in m(l(I))
    to_delete <- m_img & !ml_img

    # Gluing condition 1: no dangling edges
    # For each hom h: A → B, if we delete a B-part, all A-parts mapping to it
    # must also be deleted
    for (h in acsets::homs(schema)) {
      if (h$codom == ob) {
        hvals <- acsets::subpart(G, NULL, h$name)
        for (i in seq_along(hvals)) {
          if (!is.na(hvals[i]) && to_delete[hvals[i]]) {
            # The source part i maps to a deleted target — is i also deleted?
            ob_from <- h$dom
            keep_from <- !logical(acsets::nparts(G, ob_from))  # temp
            m_from <- logical(acsets::nparts(G, ob_from))
            ml_from <- logical(acsets::nparts(G, ob_from))
            for (j in seq_len(acsets::nparts(L, ob_from)))
              m_from[m@components[[ob_from]][j]] <- TRUE
            for (j in seq_len(acsets::nparts(I, ob_from))) {
              lj <- l@components[[ob_from]][j]
              ml_from[m@components[[ob_from]][lj]] <- TRUE
            }
            del_from <- m_from & !ml_from
            if (!del_from[i]) {
              cli::cli_abort(c(
                "Gluing condition violated: dangling edge",
                "i" = "Part {i} of {ob_from} maps via {h$name} to deleted part {hvals[i]} of {ob}"
              ))
            }
          }
        }
      }
    }

    # Gluing condition 2: identification
    # Distinct parts of L not in l(I) that are identified by m
    l_image_parts <- integer(0)
    for (j in seq_len(n_I)) l_image_parts <- c(l_image_parts, l@components[[ob]][j])
    non_interface <- setdiff(seq_len(n_L), l_image_parts)
    if (length(non_interface) > 1L) {
      m_vals <- m@components[[ob]][non_interface]
      if (anyDuplicated(m_vals)) {
        cli::cli_abort(c(
          "Gluing condition violated: identification",
          "i" = "Distinct non-interface parts of L are identified by match in {ob}"
        ))
      }
    }

    keep_G[[ob]] <- !to_delete
    m_image[[ob]] <- m_img
    ml_image[[ob]] <- ml_img
  }

  # Build K: subgraph of G keeping only keep_G parts
  K <- acsets::ACSet(schema)
  g_to_k <- list()  # G-part → K-part mapping
  k_to_g <- list()  # K-part → G-part mapping

  for (ob in acsets::objects(schema)) {
    kept <- which(keep_G[[ob]])
    n_K <- length(kept)
    if (n_K > 0L) acsets::add_parts(K, ob, n_K)
    k_to_g[[ob]] <- kept
    g_to_k[[ob]] <- integer(acsets::nparts(G, ob))
    g_to_k[[ob]][kept] <- seq_len(n_K)
  }

  # Set homs in K
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n_K <- acsets::nparts(K, ob_from)
    if (n_K == 0L) next
    for (k in seq_len(n_K)) {
      g_part <- k_to_g[[ob_from]][k]
      g_val <- acsets::subpart(G, g_part, h$name)
      if (!is.na(g_val)) {
        k_val <- g_to_k[[ob_to]][g_val]
        acsets::set_subpart(K, k, h$name, k_val)
      }
    }
  }

  # Set attrs in K
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n_K <- acsets::nparts(K, ob_from)
    if (n_K == 0L) next
    for (k in seq_len(n_K)) {
      g_part <- k_to_g[[ob_from]][k]
      val <- acsets::subpart(G, g_part, a$name)
      if (!is.na(val)) acsets::set_subpart(K, k, a$name, val)
    }
  }

  # Build ik: I → K
  ik_comp <- list()
  for (ob in acsets::objects(schema)) {
    n_I <- acsets::nparts(I, ob)
    ik_comp[[ob]] <- integer(n_I)
    for (j in seq_len(n_I)) {
      l_j <- l@components[[ob]][j]
      g_j <- m@components[[ob]][l_j]
      ik_comp[[ob]][j] <- g_to_k[[ob]][g_j]
    }
  }

  # Build kg: K → G (inclusion)
  kg_comp <- list()
  for (ob in acsets::objects(schema)) {
    kg_comp[[ob]] <- k_to_g[[ob]]
  }

  list(
    K = K,
    ik = ACSetTransformation(ik_comp, I, K),
    kg = ACSetTransformation(kg_comp, K, G)
  )
}


# DPO rewrite with explicit match -------------------------------------------

#' Apply a rewrite rule at a specific match
#'
#' Dispatches on rule semantics: DPO (pushout complement + pushout),
#' SPO (cascading deletion + pushout), or SqPO (final pullback complement + pushout).
#'
#' @param rule A Rule object
#' @param match ACSetTransformation L → G
#' @returns List with \code{result} (ACSet H) and additional morphisms
#' @export
rewrite_match <- function(rule, match) {
  switch(rule@semantics,
    DPO = rewrite_match_dpo(rule, match),
    SPO = rewrite_match_spo(rule, match),
    SqPO = rewrite_match_sqpo(rule, match),
    cli::cli_abort("Unknown rewriting semantics: {rule@semantics}")
  )
}

# DPO rewrite
rewrite_match_dpo <- function(rule, match) {
  poc <- pushout_complement(rule@l, match)
  po <- pushout(rule@r, poc$ik)
  list(result = po$pushout, rh = po$inj1, kh = po$inj2)
}


# Find matches and rewrite --------------------------------------------------

#' Find all matches of a rule in a graph
#'
#' @param rule A Rule object
#' @param graph Target ACSet
#' @param limit Maximum matches to find
#' @returns List of ACSetTransformations (L → graph)
#' @export
get_matches <- function(rule, graph, limit = Inf) {
  L <- rule@l@codom_acset
  find_all_homomorphisms(L, graph, monic = rule@monic, limit = limit)
}

#' Apply a rule to a graph, finding the first valid match
#'
#' @param rule A Rule object
#' @param graph Target ACSet
#' @returns The rewritten ACSet, or NULL if no match found
#' @examples
#' # Delete an edge via DPO rewriting
#' L <- path_graph(2)
#' I <- Graph(V = 2)
#' R <- Graph(V = 2)
#' l <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, L)
#' r <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), I, R)
#' rl <- rule(l, r)
#' g <- path_graph(3)
#' result <- rewrite(rl, g)
#' ne(result) # 1 (one edge removed)
#' @export
rewrite <- function(rule, graph) {
  matches <- get_matches(rule, graph, limit = 1L)
  if (length(matches) == 0L) return(NULL)
  rewrite_match(rule, matches[[1L]])$result
}


# SPO (Single Pushout) rewriting --------------------------------------------
#
# More permissive than DPO: instead of requiring gluing conditions,
# SPO performs cascading deletion — elements whose targets are deleted
# are automatically removed.

#' Cascading deletion: compute subobject of G after removing matched elements
#'
#' Given l: I → L and m: L → G, remove m(L) \\ m(l(I)) from G,
#' cascading to remove any elements that reference deleted elements.
#'
#' @param l ACSetTransformation I → L
#' @param m ACSetTransformation L → G
#' @returns List with K (ACSet), ik (I → K), kg (K → G)
#' @export
cascading_complement <- function(l, m) {
  schema <- l@dom_acset@schema
  I <- l@dom_acset
  L <- l@codom_acset
  G <- m@codom_acset

  # Mark what to delete: m(L) \ m(l(I))
  to_delete <- list()
  for (ob in acsets::objects(schema)) {
    n_G <- acsets::nparts(G, ob)
    n_L <- acsets::nparts(L, ob)
    n_I <- acsets::nparts(I, ob)

    m_img <- logical(n_G)
    ml_img <- logical(n_G)

    for (j in seq_len(n_L)) m_img[m@components[[ob]][j]] <- TRUE
    for (j in seq_len(n_I)) {
      l_j <- l@components[[ob]][j]
      ml_img[m@components[[ob]][l_j]] <- TRUE
    }
    to_delete[[ob]] <- m_img & !ml_img
  }

  # Cascade: iteratively delete elements referencing deleted targets
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (h in acsets::homs(schema)) {
      ob_from <- h$dom
      ob_to <- h$codom
      hvals <- acsets::subpart(G, NULL, h$name)
      for (i in seq_along(hvals)) {
        if (!to_delete[[ob_from]][i] && !is.na(hvals[i]) && to_delete[[ob_to]][hvals[i]]) {
          to_delete[[ob_from]][i] <- TRUE
          changed <- TRUE
        }
      }
    }
  }

  # Build K: subobject of G keeping non-deleted parts
  K <- acsets::ACSet(schema)
  g_to_k <- list()
  k_to_g <- list()

  for (ob in acsets::objects(schema)) {
    kept <- which(!to_delete[[ob]])
    n_K <- length(kept)
    if (n_K > 0L) acsets::add_parts(K, ob, n_K)
    k_to_g[[ob]] <- kept
    g_to_k[[ob]] <- integer(acsets::nparts(G, ob))
    g_to_k[[ob]][kept] <- seq_len(n_K)
  }

  # Set homs in K
  for (h in acsets::homs(schema)) {
    ob_from <- h$dom
    ob_to <- h$codom
    n_K <- acsets::nparts(K, ob_from)
    if (n_K == 0L) next
    for (k in seq_len(n_K)) {
      g_part <- k_to_g[[ob_from]][k]
      g_val <- acsets::subpart(G, g_part, h$name)
      if (!is.na(g_val)) {
        k_val <- g_to_k[[ob_to]][g_val]
        if (k_val > 0L) acsets::set_subpart(K, k, h$name, k_val)
      }
    }
  }

  # Set attrs in K
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    n_K <- acsets::nparts(K, ob_from)
    if (n_K == 0L) next
    for (k in seq_len(n_K)) {
      g_part <- k_to_g[[ob_from]][k]
      val <- acsets::subpart(G, g_part, a$name)
      if (!is.na(val)) acsets::set_subpart(K, k, a$name, val)
    }
  }

  # Build ik: I → K
  ik_comp <- list()
  for (ob in acsets::objects(schema)) {
    n_I <- acsets::nparts(I, ob)
    ik_comp[[ob]] <- integer(n_I)
    for (j in seq_len(n_I)) {
      l_j <- l@components[[ob]][j]
      g_j <- m@components[[ob]][l_j]
      ik_comp[[ob]][j] <- g_to_k[[ob]][g_j]
    }
  }

  # Build kg: K → G (inclusion)
  kg_comp <- list()
  for (ob in acsets::objects(schema)) {
    kg_comp[[ob]] <- k_to_g[[ob]]
  }

  list(
    K = K,
    ik = ACSetTransformation(ik_comp, I, K),
    kg = ACSetTransformation(kg_comp, K, G)
  )
}

# SPO rewrite with explicit match
rewrite_match_spo <- function(rule, match) {
  # Step 1: Cascading complement (like pushout complement but with cascading deletion)
  cc <- cascading_complement(rule@l, match)

  # Step 2: Pushout of (r: I → R, ik: I → K) to get H
  po <- pushout(rule@r, cc$ik)

  list(result = po$pushout, rh = po$inj1, kh = po$inj2)
}


# SqPO (Sesqui-Pushout) rewriting ------------------------------------------
#
# More expressive than DPO: handles non-monic left legs (cloning).
# When l: I → L maps multiple interface elements to the same L element,
# the matched G element is cloned. Also performs cascading deletion
# like SPO for unmatched elements.

#' Compute the final pullback complement (FPC) for SqPO rewriting
#'
#' Given f: A → B and m: B → C, compute D and morphisms n: A → D, g: D → C
#' such that the square is a final pullback.
#'
#' For finite C-sets:
#' - Elements c in C not in m(B): kept (multiplied if hom targets are cloned)
#' - Elements c = m(b) where b in f(A): cloned (one copy per A-preimage)
#' - Elements c = m(b) where b not in f(A): deleted
#' - "Kept" elements whose hom targets were cloned are expanded (product rule)
#'
#' @param f ACSetTransformation A → B
#' @param m ACSetTransformation B → C
#' @returns List with D (ACSet), n (A → D), g (D → C)
#' @export
final_pullback_complement <- function(f, m) {
  schema <- f@dom_acset@schema
  A <- f@dom_acset
  B <- f@codom_acset
  C <- m@codom_acset
  obs <- acsets::objects(schema)
  hom_list <- acsets::homs(schema)

  # Phase 1: Compute multiplicity and classification per C-element
  # mult[ob][c] = number of D copies; 0 = deleted
  mult <- list()
  # clone_map[ob][c] = list of A-indices (for cloned elements)
  clone_map <- list()

  for (ob in obs) {
    n_A <- acsets::nparts(A, ob)
    n_B <- acsets::nparts(B, ob)
    n_C <- acsets::nparts(C, ob)

    f_comp <- if (n_A > 0L) f@components[[ob]] else integer(0)
    m_comp <- if (n_B > 0L) m@components[[ob]] else integer(0)

    # f_img[b] = TRUE if b in f(A)
    f_img <- logical(n_B)
    for (j in seq_len(n_A)) f_img[f_comp[j]] <- TRUE

    # m_img[c] = TRUE if c in m(B)
    m_img <- logical(n_C)
    for (j in seq_len(n_B)) m_img[m_comp[j]] <- TRUE

    mult[[ob]] <- integer(n_C)
    clone_map[[ob]] <- vector("list", n_C)

    for (c in seq_len(n_C)) {
      if (!m_img[c]) {
        # Kept — initially mult=1; may be expanded later
        mult[[ob]][c] <- 1L
        # clone_map[[ob]][[c]] stays NULL (already initialized)
      } else {
        # In m(B): find B preimages and check if any are in f(A)
        b_preimages <- which(m_comp == c)
        a_preimages <- integer(0)
        for (b in b_preimages) {
          if (f_img[b]) {
            a_preimages <- c(a_preimages, which(f_comp == b))
          }
        }
        if (length(a_preimages) > 0L) {
          # Cloned
          mult[[ob]][c] <- length(a_preimages)
          clone_map[[ob]][[c]] <- a_preimages
        } else {
          # Deleted — mult=0, clone_map stays NULL
          mult[[ob]][c] <- 0L
        }
      }
    }
  }

  # Phase 2: Propagate multiplicities for "kept" elements
  # A kept element with mult=1 whose hom target has mult>1 needs expansion.
  # A kept element with any hom target mult=0 gets deleted (cascade).
  # For elements with multiple homs, mult = product of target multiplicities.
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (ob in obs) {
      n_C <- length(mult[[ob]])
      for (c in seq_len(n_C)) {
        if (mult[[ob]][c] == 0L) next
        if (!is.null(clone_map[[ob]][[c]])) next  # cloned elements are fixed

        # Compute product of hom target multiplicities
        new_mult <- 1L
        for (h in hom_list) {
          if (h$dom != ob) next
          hval <- acsets::subpart(C, c, h$name)
          if (is.na(hval)) next
          target_mult <- mult[[h$codom]][hval]
          if (target_mult == 0L) {
            new_mult <- 0L
            break
          }
          new_mult <- new_mult * target_mult
        }
        if (new_mult != mult[[ob]][c]) {
          mult[[ob]][c] <- new_mult
          changed <- TRUE
        }
      }
    }
  }

  # Phase 3: Build D entries
  # Each entry: list(ob, c_idx, copy_idx, a_idx_or_NULL)
  # Also build: c_to_d_range[ob][c] = start:end indices of D copies
  d_count <- list()
  c_to_d_start <- list()
  for (ob in obs) {
    n_C <- length(mult[[ob]])
    d_count[[ob]] <- sum(mult[[ob]])
    starts <- integer(n_C)
    pos <- 1L
    for (c in seq_len(n_C)) {
      starts[c] <- pos
      pos <- pos + mult[[ob]][c]
    }
    c_to_d_start[[ob]] <- starts
  }

  # Create D ACSet
  D <- acsets::ACSet(schema)
  for (ob in obs) {
    if (d_count[[ob]] > 0L) acsets::add_parts(D, ob, d_count[[ob]])
  }

  # Build g: D → C
  g_comp <- list()
  for (ob in obs) {
    n_C <- length(mult[[ob]])
    g_comp[[ob]] <- integer(d_count[[ob]])
    for (c in seq_len(n_C)) {
      mc <- mult[[ob]][c]
      if (mc > 0L) {
        start <- c_to_d_start[[ob]][c]
        g_comp[[ob]][start:(start + mc - 1L)] <- c
      }
    }
  }

  # Build n: A → D
  n_comp <- list()
  for (ob in obs) {
    n_A <- acsets::nparts(A, ob)
    n_comp[[ob]] <- integer(n_A)
    n_C <- length(mult[[ob]])
    for (c in seq_len(n_C)) {
      a_indices <- clone_map[[ob]][[c]]
      if (is.null(a_indices)) next
      start <- c_to_d_start[[ob]][c]
      for (k in seq_along(a_indices)) {
        n_comp[[ob]][a_indices[k]] <- start + k - 1L
      }
    }
  }

  # Phase 4: Set hom values in D
  for (h in hom_list) {
    ob_from <- h$dom
    ob_to <- h$codom
    if (d_count[[ob_from]] == 0L) next

    n_C_from <- length(mult[[ob_from]])
    for (c in seq_len(n_C_from)) {
      m_from <- mult[[ob_from]][c]
      if (m_from == 0L) next

      hval_c <- acsets::subpart(C, c, h$name)
      if (is.na(hval_c)) next

      m_to <- mult[[ob_to]][hval_c]
      if (m_to == 0L) next

      start_from <- c_to_d_start[[ob_from]][c]
      start_to <- c_to_d_start[[ob_to]][hval_c]

      if (!is.null(clone_map[[ob_from]][[c]])) {
        # Cloned element: follow A's hom to determine target copy
        a_indices <- clone_map[[ob_from]][[c]]
        for (k in seq_along(a_indices)) {
          a_idx <- a_indices[k]
          a_hval <- acsets::subpart(A, a_idx, h$name)
          if (!is.na(a_hval)) {
            target_d <- n_comp[[ob_to]][a_hval]
            if (target_d > 0L) {
              acsets::set_subpart(D, start_from + k - 1L, h$name, target_d)
            }
          } else {
            # A doesn't have this hom; use first available target copy
            acsets::set_subpart(D, start_from + k - 1L, h$name, start_to)
          }
        }
      } else {
        # Kept element: expanded by product of target multiplicities
        # Need to enumerate combinations of hom target copies
        if (m_from == 1L && m_to == 1L) {
          # Simple case: 1-to-1
          acsets::set_subpart(D, start_from, h$name, start_to)
        } else {
          # Multi-copy: this h contributes m_to copies.
          # The expansion is a product over all homs. For this specific hom h,
          # each block of (total/m_to) consecutive copies maps to the same target copy.
          # The block structure: for hom h_j, copies cycle through h_j targets
          # with period = product of multiplicities of homs h_{j+1}...h_k.

          # Compute the stride for this hom in the product expansion
          homs_from <- list()
          for (hh in hom_list) {
            if (hh$dom == ob_from) {
              hv <- acsets::subpart(C, c, hh$name)
              if (!is.na(hv) && mult[[hh$codom]][hv] > 1L) {
                homs_from[[length(homs_from) + 1L]] <- list(
                  name = hh$name, codom = hh$codom, c_target = hv
                )
              }
            }
          }

          # For this specific hom: compute stride
          # stride = product of multiplicities of all subsequent homs
          h_idx <- which(vapply(homs_from, function(x) x$name, character(1)) == h$name)
          if (length(h_idx) > 0L) {
            h_idx <- h_idx[1L]
            stride <- 1L
            if (h_idx < length(homs_from)) {
              for (j in (h_idx + 1L):length(homs_from)) {
                stride <- stride * mult[[homs_from[[j]]$codom]][homs_from[[j]]$c_target]
              }
            }
            for (i in seq_len(m_from)) {
              # Which copy of the target does copy i use?
              target_copy <- ((i - 1L) %/% stride) %% m_to
              acsets::set_subpart(D, start_from + i - 1L, h$name,
                                 start_to + target_copy)
            }
          } else {
            # This hom's target has mult=1, just point all copies to it
            for (i in seq_len(m_from)) {
              acsets::set_subpart(D, start_from + i - 1L, h$name, start_to)
            }
          }
        }
      }
    }
  }

  # Set attrs in D from C
  for (a in acsets::attrs(schema)) {
    ob_from <- a$dom
    if (d_count[[ob_from]] == 0L) next
    n_C_from <- length(mult[[ob_from]])
    for (c in seq_len(n_C_from)) {
      m_from <- mult[[ob_from]][c]
      if (m_from == 0L) next
      val <- acsets::subpart(C, c, a$name)
      if (is.na(val)) next
      start <- c_to_d_start[[ob_from]][c]
      for (i in seq_len(m_from)) {
        acsets::set_subpart(D, start + i - 1L, a$name, val)
      }
    }
  }

  list(
    D = D,
    n = ACSetTransformation(n_comp, A, D),
    g = ACSetTransformation(g_comp, D, C)
  )
}

# SqPO rewrite with explicit match
rewrite_match_sqpo <- function(rule, match) {
  # Step 1: Final pullback complement of (l: I → L, m: L → G)
  fpc <- final_pullback_complement(rule@l, match)

  # Step 2: Pushout of (r: I → R, n: I → D) to get H
  po <- pushout(rule@r, fpc$n)

  list(result = po$pushout, rh = po$inj1, dh = po$inj2)
}
