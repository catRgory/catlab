# Finite categories and functors -------------------------------------------

#' Finite category (presented by an ACSet schema)
#' @export
FinCat <- S7::new_class("FinCat",
  properties = list(
    schema = acsets::BasicSchema
  )
)

#' Functor between finite categories (schema morphism)
#' @export
FinFunctor <- S7::new_class("FinFunctor",
  properties = list(
    ob_map = S7::class_list,
    hom_map = S7::class_list,
    dom = FinCat,
    codom = FinCat
  ),
  validator = function(self) {
    # Check that ob_map covers all objects in domain
    dom_obs <- acsets::objects(self@dom@schema)
    if (!all(dom_obs %in% names(self@ob_map))) {
      return("ob_map must map every domain object")
    }
    # Check that mapped objects exist in codomain
    codom_obs <- acsets::objects(self@codom@schema)
    for (nm in names(self@ob_map)) {
      if (!(self@ob_map[[nm]] %in% codom_obs)) {
        return(sprintf("ob_map['%s'] = '%s' not in codomain", nm, self@ob_map[[nm]]))
      }
    }
    NULL
  }
)

#' ACSet transformation (natural transformation between ACSets)
#' @export
ACSetTransformation <- S7::new_class("ACSetTransformation",
  properties = list(
    components = S7::class_list,
    dom_acset = acsets::ACSet,
    codom_acset = acsets::ACSet
  ),
  validator = function(self) {
    schema <- self@dom_acset@schema
    if (!identical(schema, self@codom_acset@schema)) {
      return("Domain and codomain ACSets must have the same schema")
    }
    for (ob in acsets::objects(schema)) {
      if (!(ob %in% names(self@components))) {
        return(sprintf("Missing component for object '%s'", ob))
      }
      comp <- self@components[[ob]]
      n_dom <- acsets::nparts(self@dom_acset, ob)
      if (length(comp) != n_dom) {
        return(sprintf("Component for '%s' has wrong length (%d vs %d)", ob, length(comp), n_dom))
      }
      # Check values are valid part IDs in codomain
      n_codom <- acsets::nparts(self@codom_acset, ob)
      if (any(comp < 1L | comp > n_codom, na.rm = TRUE)) {
        return(sprintf("Component for '%s' has out-of-range values", ob))
      }
    }
    NULL
  }
)

#' Check naturality of an ACSet transformation
#' @export
is_natural <- function(alpha) {
  schema <- alpha@dom_acset@schema
  for (h in acsets::homs(schema)) {
    dom_vals <- acsets::subpart(alpha@dom_acset, NULL, h$name)
    codom_vals <- acsets::subpart(alpha@codom_acset, NULL, h$name)
    # For each part in domain: alpha_codom(h(part)) == h(alpha_dom(part))
    comp_dom <- alpha@components[[h$dom]]
    comp_codom <- alpha@components[[h$codom]]
    for (i in seq_along(comp_dom)) {
      lhs <- codom_vals[comp_dom[i]]       # h in codomain applied to mapped part
      rhs <- comp_codom[dom_vals[i]]        # map of h applied in domain
      if (!is.na(lhs) && !is.na(rhs) && lhs != rhs) return(FALSE)
    }
  }
  TRUE
}

#' Identity transformation
#' @export
id_transformation <- function(acs) {
  schema <- acs@schema
  components <- list()
  for (ob in acsets::objects(schema)) {
    components[[ob]] <- acsets::parts(acs, ob)
  }
  ACSetTransformation(components = components, dom_acset = acs, codom_acset = acs)
}

#' Compose two ACSet transformations
#' @export
compose_transformations <- function(alpha, beta) {
  schema <- alpha@dom_acset@schema
  components <- list()
  for (ob in acsets::objects(schema)) {
    components[[ob]] <- beta@components[[ob]][alpha@components[[ob]]]
  }
  ACSetTransformation(components = components,
                      dom_acset = alpha@dom_acset,
                      codom_acset = beta@codom_acset)
}
