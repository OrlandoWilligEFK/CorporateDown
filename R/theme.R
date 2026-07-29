#' Build a grid-line element from the design
#' @keywords internal
#' @noRd
grid_line <- function(on, colour, width) {
  if (isTRUE(on)) {
    ggplot2::element_line(colour = colour, linewidth = width %||% 0.5)
  } else {
    ggplot2::element_blank()
  }
}

#' A ggplot2 theme from a corporate design
#'
#' Builds a complete [ggplot2::theme()] from the design's typography, semantic
#' colours and geometry tokens. Used on its own for a single figure, or set as
#' the global default by [set_corporate_design()].
#'
#' @param design A `corporate_design` object.
#' @param base_size Optional base font size in points. Defaults to the design's
#'   axis size.
#'
#' @return A ggplot2 theme object.
#'
#' @examples
#' design <- corporate_design(
#'   system.file("designs/efk.yml", package = "CorporateDown")
#' )
#' library(ggplot2)
#' p <- ggplot(mpg, aes(displ, hwy)) +
#'   geom_point() +
#'   theme_corporate(design)
#' # print(p) on a ragg device to render the corporate design
#'
#' @export
theme_corporate <- function(design, base_size = NULL) {
  if (!inherits(design, "corporate_design")) {
    cli::cli_abort("{.arg design} muss ein {.cls corporate_design}-Objekt sein.")
  }
  tp  <- design$typography
  sem <- design$colors$semantic
  geo <- design$geometry
  sizes <- tp$sizes
  fam <- resolve_family(design)

  base <- base_size %||% sizes$axis %||% 10

  ggplot2::theme_minimal(base_size = base, base_family = fam) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = sem$background, colour = NA),
      panel.background = ggplot2::element_rect(fill = sem$background, colour = NA),
      plot.title    = ggplot2::element_text(
        family = fam, size = sizes$title,
        face = tp$weights$title %||% "bold", colour = sem$text
      ),
      plot.subtitle = ggplot2::element_text(size = sizes$subtitle, colour = sem$text),
      plot.caption  = ggplot2::element_text(size = sizes$caption, colour = sem$muted, hjust = 0),
      axis.title    = ggplot2::element_text(size = sizes$axis, colour = sem$text),
      axis.text     = ggplot2::element_text(size = sizes$axis, colour = sem$axis),
      legend.title  = ggplot2::element_text(size = sizes$legend, colour = sem$text),
      legend.text   = ggplot2::element_text(size = sizes$legend, colour = sem$text),
      legend.position = geo$legend_position %||% "top",
      panel.grid.major.x = grid_line(geo$grid$major_x, sem$grid, geo$line_width),
      panel.grid.major.y = grid_line(geo$grid$major_y, sem$grid, geo$line_width),
      panel.grid.minor   = grid_line(geo$grid$minor,   sem$grid, geo$line_width),
      plot.margin = ggplot2::margin(
        geo$margin$t, geo$margin$r, geo$margin$b, geo$margin$l
      )
    )
}
