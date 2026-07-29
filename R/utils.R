#' Internal package state
#'
#' Holds the currently active design plus the theme, options and geom
#' defaults that were in place before `set_corporate_design()` ran, so that
#' `reset_corporate_design()` can restore them.
#' @keywords internal
#' @noRd
.cd_state <- new.env(parent = emptyenv())

#' Null-coalescing operator
#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Is `x` a valid hex colour code (`#RGB` or `#RRGGBB`)?
#' @keywords internal
#' @noRd
is_hex <- function(x) {
  is.character(x) & grepl("^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$", x)
}

#' Recursively merge `user` tokens over `defaults`
#'
#' Lists are merged element-wise; every other value in `user` overrides the
#' corresponding default. Used to let a minimal YAML file inherit sensible
#' defaults.
#' @keywords internal
#' @noRd
merge_tokens <- function(defaults, user) {
  if (is.null(user)) return(defaults)
  for (nm in names(user)) {
    if (is.list(defaults[[nm]]) && is.list(user[[nm]])) {
      defaults[[nm]] <- merge_tokens(defaults[[nm]], user[[nm]])
    } else {
      defaults[[nm]] <- user[[nm]]
    }
  }
  defaults
}

#' Get the ggplot2 `Geom*` object for a geom name (e.g. `"col"` -> `GeomCol`)
#' @keywords internal
#' @noRd
geom_obj <- function(geom) {
  cls <- paste0("Geom", toupper(substring(geom, 1, 1)), substring(geom, 2))
  utils::getFromNamespace(cls, "ggplot2")
}
