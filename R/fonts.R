#' Resolve the font family to actually use for a design
#'
#' Returns the design's CD font if it is installed, otherwise the first
#' available fallback, otherwise `""` (which makes ggplot2 use the graphics
#' device default). This never errors, so plotting always works.
#'
#' @param design A `corporate_design` object.
#' @return A single font-family string (possibly `""`).
#' @keywords internal
#' @noRd
resolve_family <- function(design) {
  tp <- design$typography
  fam <- tp$family %||% ""
  candidates <- c(fam, tp$family_fallback, "Liberation Sans", "Arial")
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  if (!length(candidates)) return("")

  available <- tryCatch(systemfonts::system_fonts()$family,
                        error = function(e) character())
  hit <- candidates[tolower(candidates) %in% tolower(available)]
  if (length(hit)) hit[[1]] else ""
}

#' Register the fonts for a design and warn about fallbacks
#'
#' Checks whether the design's corporate font is installed. If it is not, a
#' warning is emitted and the resolved fallback is reported. Font resolution is
#' handled by `systemfonts` together with the `ragg` graphics device.
#'
#' @param design A `corporate_design` object.
#' @return The resolved font family (invisibly).
#' @export
register_design_fonts <- function(design) {
  fam <- design$typography$family %||% ""
  resolved <- resolve_family(design)

  if (nzchar(fam) && !identical(tolower(resolved), tolower(fam))) {
    shown <- if (nzchar(resolved)) resolved else "Geräte-Standard"
    cli::cli_warn(c(
      "!" = "Schrift {.val {fam}} nicht gefunden.",
      "i" = "Nutze Ersatzschrift {.val {shown}}. Für die volle CD-Wirkung {fam} installieren."
    ))
  }
  invisible(resolved)
}
