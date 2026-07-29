# Geoms whose default colour/fill/font we override, and the aesthetic(s) to set.
cd_geom_targets <- function(design) {
  q1  <- design$colors$qualitative[[1]]
  txt <- design$colors$semantic$text
  fam <- resolve_family(design)
  list(
    bar     = list(fill = q1),
    col     = list(fill = q1),
    area    = list(fill = q1),
    line    = list(colour = q1),
    point   = list(colour = q1),
    text    = list(colour = txt, family = fam),
    label   = list(colour = txt, family = fam)
  )
}

#' Snapshot and apply geom defaults, returning the previous values
#' @keywords internal
#' @noRd
apply_geom_defaults <- function(targets) {
  old <- list()
  for (geom in names(targets)) {
    new <- targets[[geom]]
    Geom <- tryCatch(geom_obj(geom), error = function(e) NULL)
    if (is.null(Geom)) next
    old[[geom]] <- as.list(Geom$default_aes)[names(new)]
    ggplot2::update_geom_defaults(geom, new)
  }
  old
}

#' Activate a corporate design globally
#'
#' Registers the design across the idiomatic ggplot2 mechanisms so that
#' ordinary ggplot2 code renders in the corporate design without any further
#' theme or scale calls:
#'
#' * the theme via [ggplot2::theme_set()],
#' * default discrete and continuous colour/fill scales via `options()`
#'   (`ggplot2.discrete.colour`, `ggplot2.discrete.fill`,
#'   `ggplot2.continuous.colour`, `ggplot2.continuous.fill`),
#' * per-geom default colours and fonts via [ggplot2::update_geom_defaults()],
#' * fonts via [register_design_fonts()].
#'
#' The previous theme, options and geom defaults are stored so
#' [reset_corporate_design()] can restore them.
#'
#' @param design A `corporate_design` object, a path to a YAML file, or the
#'   name of a shipped design (e.g. `"efk"`).
#'
#' @return The activated design (invisibly).
#'
#' @examples
#' \dontrun{
#' set_corporate_design("efk")
#' library(ggplot2)
#' ggplot(mpg, aes(class, fill = drv)) + geom_bar()  # in the corporate design
#' reset_corporate_design()
#' }
#'
#' @export
set_corporate_design <- function(design) {
  design <- as_design(design)
  register_design_fonts(design)

  opt_names <- c(
    "ggplot2.discrete.colour", "ggplot2.discrete.fill",
    "ggplot2.continuous.colour", "ggplot2.continuous.fill"
  )

  # Snapshot the pre-existing state once, so nested calls don't lose it.
  # getOption() preserves NULLs (unset options) with their names, which
  # subsetting the options() list would drop.
  if (is.null(.cd_state$active)) {
    .cd_state$old_theme <- ggplot2::theme_get()
    old_opts <- lapply(opt_names, getOption)
    names(old_opts) <- opt_names
    .cd_state$old_options <- old_opts
    .cd_state$old_geoms <- apply_geom_defaults(cd_geom_targets(design))
  } else {
    apply_geom_defaults(cd_geom_targets(design))
  }

  .cd_state$design <- design
  .cd_state$active <- TRUE

  ggplot2::theme_set(theme_corporate(design))

  # Discrete defaults: a plain colour vector is the documented, version-stable
  # form ggplot2 accepts for these options. Continuous defaults: a function
  # that ggplot2 calls to build the scale.
  seqp <- corporate_pal(design, "sequential")
  options(
    ggplot2.discrete.colour = design$colors$qualitative,
    ggplot2.discrete.fill   = design$colors$qualitative,
    ggplot2.continuous.colour = function(...) {
      ggplot2::scale_colour_gradientn(colours = seqp(256), ...)
    },
    ggplot2.continuous.fill = function(...) {
      ggplot2::scale_fill_gradientn(colours = seqp(256), ...)
    }
  )

  invisible(design)
}

#' Reset the global corporate design
#'
#' Restores the theme, ggplot2 scale options and geom defaults that were in
#' place before the first [set_corporate_design()] call. Safe to call when no
#' design is active.
#'
#' @return `NULL` (invisibly).
#' @export
reset_corporate_design <- function() {
  if (is.null(.cd_state$active)) {
    cli::cli_inform("Kein Corporate Design aktiv \u2013 nichts zur\u00fcckzusetzen.")
    return(invisible(NULL))
  }

  ggplot2::theme_set(.cd_state$old_theme)
  options(.cd_state$old_options)
  for (geom in names(.cd_state$old_geoms)) {
    ggplot2::update_geom_defaults(geom, .cd_state$old_geoms[[geom]])
  }

  .cd_state$design <- NULL
  .cd_state$active <- NULL
  .cd_state$old_theme <- NULL
  .cd_state$old_options <- NULL
  .cd_state$old_geoms <- NULL
  invisible(NULL)
}
