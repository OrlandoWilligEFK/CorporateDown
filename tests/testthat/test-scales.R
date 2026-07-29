design <- corporate_design(system.file("designs/efk.yml", package = "CorporateDown"))

test_that("corporate_pal returns the requested number of colours", {
  qual <- corporate_pal(design, "qualitative")
  expect_length(qual(3), 3)
  expect_identical(qual(1), "#DC0018")
  # More colours than defined -> interpolation, still correct length.
  expect_length(qual(20), 20)

  expect_length(corporate_pal(design, "sequential")(5), 5)
  expect_length(corporate_pal(design, "diverging")(7), 7)
})

test_that("scales return ggplot2 scale objects", {
  expect_s3_class(scale_fill_corporate(design = design), "Scale")
  expect_s3_class(scale_colour_corporate(design = design), "Scale")
  expect_s3_class(
    scale_fill_corporate(discrete = FALSE, type = "sequential", design = design),
    "Scale"
  )
})
