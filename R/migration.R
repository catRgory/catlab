# Delta migration ----------------------------------------------------------
# Pullback of an ACSet along a schema functor F: C → D.

#' Perform delta (pullback) migration
#'
#' Given a functor F: C → D (as a FinFunctor) and a D-set (ACSet on schema D),
#' produce a C-set by pulling back along F.
#'
#' @param functor A FinFunctor from source schema to target schema
#' @param source An ACSet on the target (codomain) schema
#' @param result_type An acset_constructor for the result (source domain schema)
#' @returns An ACSet on the source (domain) schema
#' @export
delta_migrate <- function(functor, source, result_type) {
  dom_schema <- functor@dom@schema
  codom_schema <- functor@codom@schema

  result <- result_type()

  # For each object in domain schema, add the same number of parts
  # as the mapped object in the source
  for (ob in acsets::objects(dom_schema)) {
    mapped_ob <- functor@ob_map[[ob]]
    n <- acsets::nparts(source, mapped_ob)
    if (n > 0L) acsets::add_parts(result, ob, n)
  }

  # For each hom in domain schema, copy the mapped hom's values
  for (h in acsets::homs(dom_schema)) {
    mapped_hom <- functor@hom_map[[h$name]]
    if (is.null(mapped_hom)) next
    ob <- h$dom
    mapped_ob <- functor@ob_map[[ob]]
    ids <- acsets::parts(result, ob)
    if (length(ids) == 0L) next

    if (is.character(mapped_hom) && length(mapped_hom) == 1L) {
      vals <- acsets::subpart(source, ids, mapped_hom)
    } else {
      # Composed path
      vals <- acsets::subpart(source, ids, mapped_hom)
    }
    acsets::set_subpart(result, ids, h$name, vals)
  }

  # For each attr in domain schema, copy the mapped attr's values
  for (a in acsets::attrs(dom_schema)) {
    mapped_attr <- functor@hom_map[[a$name]]
    if (is.null(mapped_attr)) next
    ob <- a$dom
    ids <- acsets::parts(result, ob)
    if (length(ids) == 0L) next
    vals <- acsets::subpart(source, ids, mapped_attr)
    acsets::set_subpart(result, ids, a$name, vals)
  }

  result
}


# Sigma migration (left Kan extension) --------------------------------------

#' Sigma (left pushforward) migration
#'
#' Given a functor F: C → D and a C-set X, compute Σ_F(X) — a D-set.
#' This is the left Kan extension of X along F, computed via colimits.
#'
#' For each object d in D, Σ_F(X)(d) = Σ_{c: F(c)=d} X(c).
#' Parts from different C-objects mapping to the same D-object are combined.
#'
#' @param functor A FinFunctor from source to target schema
#' @param source An ACSet on the source (domain) schema
#' @param result_type An acset_constructor for the result (codomain schema)
#' @returns An ACSet on the target (codomain) schema
#' @export
sigma_migrate <- function(functor, source, result_type) {
  dom_schema <- functor@dom@schema
  codom_schema <- functor@codom@schema

  result <- result_type()

  # For each object d in codomain: collect parts from all c with F(c) = d
  # Track origin mapping for hom remapping
  part_map <- list()   # dom_ob → (source_part → result_part)

  for (d in acsets::objects(codom_schema)) {
    # Find all domain objects mapping to d
    contributing <- character(0)
    for (c_ob in acsets::objects(dom_schema)) {
      if (functor@ob_map[[c_ob]] == d) {
        contributing <- c(contributing, c_ob)
      }
    }

    # Add parts from each contributing domain object
    for (c_ob in contributing) {
      n <- acsets::nparts(source, c_ob)
      if (n == 0L) next
      start <- acsets::nparts(result, d)
      acsets::add_parts(result, d, n)
      part_map[[c_ob]] <- setNames(seq.int(start + 1L, start + n), seq_len(n))
    }
    # Handle domain objects with no parts
    for (c_ob in contributing) {
      if (is.null(part_map[[c_ob]])) {
        part_map[[c_ob]] <- integer(0)
      }
    }
  }

  # Set homs: for each hom h in codom, find contributing domain homs
  for (h in acsets::homs(codom_schema)) {
    target_from <- h$dom
    target_to <- h$codom

    # Find domain homs that map to h
    for (dh in acsets::homs(dom_schema)) {
      mapped_hom <- functor@hom_map[[dh$name]]
      if (is.null(mapped_hom) || mapped_hom != h$name) next

      c_from <- dh$dom
      c_to <- dh$codom
      n <- acsets::nparts(source, c_from)
      if (n == 0L) next

      vals <- acsets::subpart(source, seq_len(n), dh$name)
      # Remap through part_map
      new_from <- part_map[[c_from]][seq_len(n)]
      new_to <- part_map[[c_to]][vals]
      for (i in seq_len(n)) {
        if (!is.na(new_to[i]))
          acsets::set_subpart(result, new_from[i], h$name, new_to[i])
      }
    }
  }

  # Set attrs: for each attr in codom, find contributing domain attrs
  for (a in acsets::attrs(codom_schema)) {
    target_from <- a$dom

    for (da in acsets::attrs(dom_schema)) {
      mapped_attr <- functor@hom_map[[da$name]]
      if (is.null(mapped_attr) || mapped_attr != a$name) next

      c_from <- da$dom
      n <- acsets::nparts(source, c_from)
      if (n == 0L) next

      vals <- acsets::subpart(source, seq_len(n), da$name)
      new_from <- part_map[[c_from]][seq_len(n)]
      for (i in seq_len(n)) {
        if (!is.na(vals[i]))
          acsets::set_subpart(result, new_from[i], a$name, vals[i])
      }
    }
  }

  result
}
