#' Default design tokens
#'
#' A complete set of tokens a user YAML file is merged over, so a minimal file
#' still yields a valid design. The defaults deliberately mirror the EFK / CD
#' Bund look (federal red `#DC0018`).
#' @keywords internal
#' @noRd
default_tokens <- function() {
  list(
    meta = list(name = "Unnamed", version = "0.0.0"),
    colors = list(
      qualitative = c("#DC0018", "#4D4D4D", "#7A9CC6", "#E8A33D", "#5C8A5C", "#8C6BB1"),
      sequential  = c("#FDE5E7", "#DC0018"),
      diverging   = list(low = "#4D6FA9", mid = "#F2F2F2", high = "#DC0018"),
      semantic    = list(
        background = "#FFFFFF", text = "#1A1A1A", grid = "#E6E6E6",
        axis = "#4D4D4D", muted = "#8C8C8C", highlight = "#DC0018"
      )
    ),
    typography = list(
      family = "", family_fallback = "Liberation Sans",
      sizes = list(title = 16, subtitle = 12, axis = 10, legend = 10, caption = 8),
      weights = list(title = "bold", body = "regular")
    ),
    geometry = list(
      margin = list(t = 10, r = 15, b = 10, l = 10),
      grid = list(major_x = FALSE, major_y = TRUE, minor = FALSE),
      legend_position = "top", line_width = 0.5
    ),
    logo = list(path = NULL, position = "bottom-right", width = 0.12)
  )
}

#' Create a corporate design from a YAML file
#'
#' Reads a declarative YAML file of design tokens, merges it over sensible
#' defaults, validates it and returns a `corporate_design` object. This object
#' is the single source of truth from which the theme, colour scales and geom
#' defaults are derived.
#'
#' See the shipped reference design at
#' `system.file("designs/efk.yml", package = "CorporateDown")` for the full
#' token structure.
#'
#' @param path Path to a YAML design file.
#'
#' @return An object of class `corporate_design`: a named list with elements
#'   `meta`, `colors`, `typography`, `geometry`, `logo` and `paths`.
#'
#' @examples
#' path <- system.file("designs/efk.yml", package = "CorporateDown")
#' design <- corporate_design(path)
#' design
#'
#' @export
corporate_design <- function(path) {
  if (!is.character(path) || length(path) != 1 || !file.exists(path)) {
    cli::cli_abort("{.arg path} muss auf eine bestehende YAML-Datei zeigen.")
  }
  raw <- yaml::read_yaml(path)
  design <- merge_tokens(default_tokens(), raw)

  # Normalise colour sequences to plain character vectors.
  design$colors$qualitative <- unlist(design$colors$qualitative, use.names = FALSE)
  design$colors$sequential  <- unlist(design$colors$sequential, use.names = FALSE)

  design$paths <- list(base_dir = dirname(normalizePath(path)))
  design <- structure(design, class = "corporate_design")
  validate_design(design)
  design
}

#' Validate a corporate design
#' @param design A `corporate_design` object.
#' @keywords internal
#' @noRd
validate_design <- function(design) {
  err <- character()

  if (!nzchar(design$meta$name %||% "")) {
    err <- c(err, "Feld {.field meta$name} fehlt oder ist leer.")
  }

  qual <- design$colors$qualitative
  if (length(qual) < 1) {
    err <- c(err, "{.field colors$qualitative} braucht mindestens eine Farbe.")
  }

  all_cols <- c(
    qual, design$colors$sequential,
    unlist(design$colors$diverging, use.names = FALSE),
    unlist(design$colors$semantic, use.names = FALSE)
  )
  bad <- all_cols[!is_hex(all_cols)]
  if (length(bad)) {
    err <- c(err, "Ungültige Hex-Farbwerte: {.val {bad}}.")
  }

  if (length(err)) {
    names(err) <- rep("x", length(err))
    cli::cli_abort(c("Ungültiges Corporate Design:", err))
  }
  invisible(design)
}

#' Coerce a design object or a path/name to a `corporate_design`
#' @keywords internal
#' @noRd
as_design <- function(x) {
  if (inherits(x, "corporate_design")) return(x)
  if (is.character(x) && length(x) == 1) {
    if (file.exists(x)) return(corporate_design(x))
    builtin <- system.file(file.path("designs", paste0(x, ".yml")),
                           package = "CorporateDown")
    if (nzchar(builtin)) return(corporate_design(builtin))
  }
  cli::cli_abort(
    "{.arg design} muss ein {.cls corporate_design}-Objekt, ein Dateipfad oder ein mitgelieferter Name (z. B. {.val efk}) sein."
  )
}

#' The currently active design, or an error if none is set
#' @keywords internal
#' @noRd
active_design <- function() {
  d <- .cd_state$design
  if (is.null(d)) {
    cli::cli_abort(c(
      "Kein Corporate Design aktiv.",
      "i" = "Rufe zuerst {.fn set_corporate_design} auf oder übergib {.arg design}."
    ))
  }
  d
}

#' @export
print.corporate_design <- function(x, ...) {
  cli::cli_h1("Corporate Design: {x$meta$name}")
  cli::cli_text("Version: {x$meta$version}")
  cli::cli_text("Qualitative Palette ({length(x$colors$qualitative)}): {.val {x$colors$qualitative}}")
  fam <- x$typography$family
  cli::cli_text("Schrift: {if (nzchar(fam %||% '')) fam else 'Geräte-Standard'}")
  invisible(x)
}
