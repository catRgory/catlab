# Typed ACSets ---------------------------------------------------------------
# A typed ACSet is an ACSet with a morphism (typing) to a "type system" ACSet.
# This generalizes typed Petri nets, property graphs, etc.

#' Typed ACSet: an ACSet with a typing morphism to a type system
#'
#' A TypedACSet pairs an ACSet X with a morphism phi: X -> T where T is the
#' "type system" (another ACSet on the same schema). Every element in X is
#' assigned a type by phi.
#'
#' @export
TypedACSet <- S7::new_class("TypedACSet",
  properties = list(
    acset = acsets::ACSet,
    type_system = acsets::ACSet,
    typing = ACSetTransformation
  ),
  validator = function(self) {
    if (!identical(self@acset, self@typing@dom_acset)) {
      return("typing morphism domain must equal the acset")
    }
    if (!identical(self@type_system, self@typing@codom_acset)) {
      return("typing morphism codomain must equal the type_system")
    }
    if (!is_natural(self@typing)) {
      return("typing morphism must be natural")
    }
    NULL
  }
)

#' Create a typed ACSet
#'
#' @param acset The concrete ACSet
#' @param type_system The type system ACSet
#' @param ... Named integer vectors: component mappings for the typing morphism
#' @return TypedACSet
#' @export
typed_acset <- function(acset, type_system, ...) {
  components <- list(...)
  typing <- ACSetTransformation(
    components = components,
    dom_acset = acset,
    codom_acset = type_system
  )
  TypedACSet(acset = acset, type_system = type_system, typing = typing)
}

#' Typed product of typed ACSets
#'
#' Given typed ACSets phi_1: X_1 -> T and phi_2: X_2 -> T (over the same type
#' system), compute their typed product via pullback over T.
#'
#' For each object ob, the product contains pairs (x1, x2) where
#' phi_1(x1) == phi_2(x2). This is the categorical pullback in the slice
#' category ACSet/T.
#'
#' @param tacs1 TypedACSet
#' @param tacs2 TypedACSet
#' @return TypedACSet (the product in ACSet/T)
#' @export
typed_product <- function(tacs1, tacs2) {
  if (!identical(tacs1@type_system, tacs2@type_system)) {
    stop("typed_product requires the same type system")
  }

  pb <- pullback(tacs1@typing, tacs2@typing)

  # The typing morphism for the pullback: proj1 ; phi_1 (or equivalently proj2 ; phi_2)
  typing <- compose_transformations(pb$proj1, tacs1@typing)

  TypedACSet(
    acset = pb$pullback,
    type_system = tacs1@type_system,
    typing = typing
  )
}

#' Typed coproduct of typed ACSets
#'
#' Given typed ACSets phi_1: X_1 -> T and phi_2: X_2 -> T, compute their
#' coproduct via pushout of the initial object. In practice this is the
#' disjoint union with combined typing.
#'
#' @param tacs1 TypedACSet
#' @param tacs2 TypedACSet
#' @return TypedACSet
#' @export
typed_coproduct <- function(tacs1, tacs2) {
  if (!identical(tacs1@type_system, tacs2@type_system)) {
    stop("typed_coproduct requires the same type system")
  }

  cop <- coproduct(tacs1@acset, tacs2@acset)

  # Build typing for the coproduct: concatenate typing components
  schema <- tacs1@acset@schema
  comp <- list()
  for (ob in acsets::objects(schema)) {
    comp[[ob]] <- c(tacs1@typing@components[[ob]],
                    tacs2@typing@components[[ob]])
  }

  typing <- ACSetTransformation(
    components = comp,
    dom_acset = cop$coproduct,
    codom_acset = tacs1@type_system
  )

  TypedACSet(
    acset = cop$coproduct,
    type_system = tacs1@type_system,
    typing = typing
  )
}

#' Flatten a typed ACSet (forget the typing)
#'
#' @param tacs TypedACSet
#' @return The underlying ACSet
#' @export
flatten_typed <- function(tacs) {
  tacs@acset
}

#' Check if a morphism between typed ACSets preserves typing
#'
#' Given typed ACSets phi_1: X_1 -> T and phi_2: X_2 -> T and a morphism
#' f: X_1 -> X_2, check that phi_2 . f = phi_1 (types are preserved).
#'
#' @param f ACSetTransformation from tacs1 to tacs2
#' @param tacs1 TypedACSet (domain)
#' @param tacs2 TypedACSet (codomain)
#' @return logical
#' @export
is_typed_morphism <- function(f, tacs1, tacs2) {
  schema <- tacs1@acset@schema
  for (ob in acsets::objects(schema)) {
    # phi_2(f(x)) should equal phi_1(x)
    lhs <- tacs2@typing@components[[ob]][f@components[[ob]]]
    rhs <- tacs1@typing@components[[ob]]
    if (!identical(as.integer(lhs), as.integer(rhs))) return(FALSE)
  }
  TRUE
}

#' Create a discrete typed ACSet from a type assignment
#'
#' Given a type system T and a named list of type assignments (one per object),
#' create a TypedACSet where each element is assigned its type.
#'
#' @param type_system ACSet (the type system)
#' @param ... Named integer vectors: for each object, which type each element has
#' @param schema BasicSchema (defaults to type_system's schema)
#' @return TypedACSet
#' @export
discrete_typed <- function(type_system, ..., schema = type_system@schema) {
  assignments <- list(...)
  acset <- acsets::ACSet(schema)
  comp <- list()

  for (ob in acsets::objects(schema)) {
    if (ob %in% names(assignments)) {
      n <- length(assignments[[ob]])
      if (n > 0L) acsets::add_parts(acset, ob, n)
      comp[[ob]] <- as.integer(assignments[[ob]])
    } else {
      comp[[ob]] <- integer(0)
    }
  }

  typing <- ACSetTransformation(
    components = comp,
    dom_acset = acset,
    codom_acset = type_system
  )

  TypedACSet(acset = acset, type_system = type_system, typing = typing)
}
