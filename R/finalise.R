#' Resolve a logo path from an explicit argument or the design
#'
#' Returns an existing file path or `NULL`. A relative path in the design is
#' resolved against the design's directory, then against the package's
#' `inst/logos`.
#' @keywords internal
#' @noRd
resolve_logo <- function(logo, design) {
  path <- logo %||% design$logo$path
  if (is.null(path) || !nzchar(path)) return(NULL)

  candidates <- path
  if (!is.null(design$paths$base_dir)) {
    candidates <- c(candidates, file.path(design$paths$base_dir, path))
  }
  pkg_logo <- system.file(file.path("logos", basename(path)), package = "CorporateDown")
  if (nzchar(pkg_logo)) candidates <- c(candidates, pkg_logo)

  hit <- candidates[file.exists(candidates)]
  if (length(hit)) return(hit[[1]])

  cli::cli_inform(c(
    "i" = "Logo {.path {path}} nicht gefunden \u2013 Abbildung wird ohne Logo erstellt."
  ))
  NULL
}

#' Inset coordinates (left, bottom, right, top) for a corner position
#' @keywords internal
#' @noRd
logo_coords <- function(position, width) {
  position <- match.arg(position,
    c("bottom-right", "bottom-left", "top-right", "top-left"))
  w <- width
  pad <- 0.01
  switch(position,
    "bottom-right" = list(left = 1 - pad - w, bottom = pad,        right = 1 - pad, top = pad + w),
    "bottom-left"  = list(left = pad,         bottom = pad,        right = pad + w, top = pad + w),
    "top-right"    = list(left = 1 - pad - w, bottom = 1 - pad - w, right = 1 - pad, top = 1 - pad),
    "top-left"     = list(left = pad,         bottom = 1 - pad - w, right = pad + w, top = 1 - pad)
  )
}

#' Place a logo onto a plot
#'
#' Overlays a logo image in a corner of a ggplot using
#' [patchwork::inset_element()]. The image aspect ratio is preserved. Requires
#' the suggested packages **patchwork** and **magick**; if either is missing a
#' warning is emitted and the plot is returned unchanged.
#'
#' @param plot A ggplot object.
#' @param logo Path to a logo image. Defaults to the design's `logo$path`.
#' @param position One of `"bottom-right"`, `"bottom-left"`, `"top-right"`,
#'   `"top-left"`. Defaults to the design's `logo$position`.
#' @param width Logo width as a fraction of the plot width. Defaults to the
#'   design's `logo$width`.
#' @param design A `corporate_design` object. Defaults to the active design.
#'
#' @return A ggplot / patchwork object.
#' @export
add_logo <- function(plot, logo = NULL, position = NULL, width = NULL,
                     design = NULL) {
  design <- design %||% active_design()
  path <- resolve_logo(logo, design)
  if (is.null(path)) return(plot)

  if (!requireNamespace("patchwork", quietly = TRUE) ||
      !requireNamespace("magick", quietly = TRUE)) {
    cli::cli_warn(c(
      "!" = "F\u00fcr {.fn add_logo} werden {.pkg patchwork} und {.pkg magick} ben\u00f6tigt.",
      "i" = "Abbildung wird ohne Logo zur\u00fcckgegeben."
    ))
    return(plot)
  }

  position <- position %||% design$logo$position %||% "bottom-right"
  width    <- width %||% design$logo$width %||% 0.12

  img  <- magick::image_read(path)
  grob <- grid::rasterGrob(grDevices::as.raster(img), width = grid::unit(1, "npc"))
  co   <- logo_coords(position, width)

  plot +
    patchwork::inset_element(
      grob, left = co$left, bottom = co$bottom, right = co$right, top = co$top,
      align_to = "full"
    )
}

#' Finalise and export a figure in the corporate design
#'
#' Adds an optional title, subtitle and source line, optionally places the
#' logo (see [add_logo()]) and, if `save_path` is given, writes the figure with
#' the `ragg` PNG device at the requested size and resolution. The background
#' colour is taken from the design.
#'
#' @param plot A ggplot object.
#' @param title,subtitle Optional title / subtitle overrides.
#' @param source Optional source line, placed as the plot caption.
#' @param logo Optional path to a logo. Set to `NULL` to skip; defaults to the
#'   design's logo when one is configured and found.
#' @param save_path Optional output path (`.png`). If `NULL`, the annotated
#'   plot object is returned instead of being written.
#' @param width,height Output size in inches.
#' @param dpi Output resolution.
#' @param place_logo Whether to place the logo. Defaults to `TRUE`.
#' @param design A `corporate_design` object. Defaults to the active design.
#'
#' @return The `save_path` (invisibly) when writing, otherwise the annotated
#'   plot object.
#'
#' @examples
#' \dontrun{
#' set_corporate_design("efk")
#' library(ggplot2)
#' p <- ggplot(mpg, aes(class, fill = drv)) + geom_bar()
#' finalise_plot(p, source = "Quelle: EFK", save_path = "figure.png")
#' }
#'
#' @export
finalise_plot <- function(plot, title = NULL, subtitle = NULL, source = NULL,
                          logo = NULL, save_path = NULL,
                          width = 8, height = 5, dpi = 300,
                          place_logo = TRUE, design = NULL) {
  design <- design %||% active_design()

  labs <- list()
  if (!is.null(title))    labs$title <- title
  if (!is.null(subtitle)) labs$subtitle <- subtitle
  if (!is.null(source))   labs$caption <- source
  if (length(labs)) plot <- plot + do.call(ggplot2::labs, labs)

  if (isTRUE(place_logo)) {
    plot <- add_logo(plot, logo = logo, design = design)
  }

  if (is.null(save_path)) return(plot)

  bg <- design$colors$semantic$background %||% "white"
  ragg::agg_png(save_path, width = width, height = height, units = "in",
                res = dpi, background = bg)
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)

  invisible(save_path)
}
