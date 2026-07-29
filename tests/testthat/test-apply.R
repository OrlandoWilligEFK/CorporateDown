design <- corporate_design(system.file("designs/efk.yml", package = "CorporateDown"))

test_that("theme_corporate returns a ggplot2 theme", {
  th <- theme_corporate(design)
  expect_s3_class(th, "theme")
})

test_that("set/reset restores theme, options and geom defaults", {
  old_theme <- ggplot2::theme_get()
  old_fill  <- ggplot2::GeomBar$default_aes$fill

  # Font fallback (e.g. when Frutiger is absent) is expected here.
  suppressWarnings(set_corporate_design(design))

  # Discrete default scales are installed as a colour vector.
  expect_identical(getOption("ggplot2.discrete.fill"), design$colors$qualitative)
  # Continuous default scales are installed as a scale-building function.
  expect_true(is.function(getOption("ggplot2.continuous.fill")))
  # Geom default fill is now the corporate red.
  expect_identical(ggplot2::GeomBar$default_aes$fill, "#DC0018")
  # Active design is retrievable.
  expect_s3_class(active_design(), "corporate_design")

  reset_corporate_design()

  expect_null(getOption("ggplot2.discrete.fill"))
  expect_identical(ggplot2::GeomBar$default_aes$fill, old_fill)
  expect_identical(ggplot2::theme_get(), old_theme)
})
