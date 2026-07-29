#' A palette function from a corporate design
#'
#' Returns a function of `n` that produces `n` colours from the requested
#' palette. Qualitative palettes return the design colours directly (and
#' interpolate only if more colours than defined are requested); sequential and
#' diverging palettes interpolate between the design's endpoints.
#'
#' @param design A `corporate_design` object.
#' @param type One of `"qualitative"`, `"sequential"` or `"diverging"`.
#'
#' @return A function `function(n)` returning a character vector of colours.
#'
#' @examples
#' design <- corporate_design(
#'   system.file("designs/efk.yml", package = "CorporateDown")
#' )
#' corporate_pal(design, "qualitative")(3)
#'
#' @export
corporate_pal <- function(design, type = c("qualitative", "sequential", "diverging")) {
  type <- match.arg(type)
  cols <- design$colors
  switch(type,
    qualitative = function(n) {
      pal <- cols$qualitative
      if (n <= length(pal)) pal[seq_len(n)]
      else grDevices::colorRampPalette(pal)(n)
    },
    sequential = function(n) grDevices::colorRampPalette(cols$sequential)(n),
    diverging = function(n) {
      dv <- cols$diverging
      grDevices::colorRampPalette(c(dv$low, dv$mid, dv$high))(n)
    }
  )
}

#' Corporate colour and fill scales
#'
#' Discrete or continuous ggplot2 scales driven by the design palettes. With
#' `discrete = TRUE` the qualitative palette is used; with `discrete = FALSE`
#' a continuous gradient is built from the sequential (or diverging) palette.
#'
#' These are the explicit counterparts to the global defaults installed by
#' [set_corporate_design()]; use them to colour a single figure.
#'
#' @param ... Passed on to the underlying ggplot2 scale.
#' @param type Palette type: `"qualitative"`, `"sequential"` or `"diverging"`.
#' @param discrete Whether to build a discrete (`TRUE`) or continuous (`FALSE`)
#'   scale.
#' @param design A `corporate_design` object. Defaults to the active design set
#'   by [set_corporate_design()].
#'
#' @return A ggplot2 scale object.
#'
#' @examples
#' design <- corporate_design(
#'   system.file("designs/efk.yml", package = "CorporateDown")
#' )
#' library(ggplot2)
#' ggplot(mpg, aes(class, fill = drv)) +
#'   geom_bar() +
#'   scale_fill_corporate(design = design)
#'
#' @name scale_corporate
NULL

#' @rdname scale_corporate
#' @export
scale_colour_corporate <- function(..., type = "qualitative", discrete = TRUE,
                                    design = NULL) {
  design <- design %||% active_design()
  if (discrete) {
    ggplot2::discrete_scale("colour", palette = corporate_pal(design, type), ...)
  } else {
    ggplot2::scale_colour_gradientn(colours = corporate_pal(design, type)(256), ...)
  }
}

#' @rdname scale_corporate
#' @export
scale_color_corporate <- scale_colour_corporate

#' @rdname scale_corporate
#' @export
scale_fill_corporate <- function(..., type = "qualitative", discrete = TRUE,
                                  design = NULL) {
  design <- design %||% active_design()
  if (discrete) {
    ggplot2::discrete_scale("fill", palette = corporate_pal(design, type), ...)
  } else {
    ggplot2::scale_fill_gradientn(colours = corporate_pal(design, type)(256), ...)
  }
}
