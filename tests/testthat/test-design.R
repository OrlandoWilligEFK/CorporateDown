efk_path <- function() system.file("designs/efk.yml", package = "CorporateDown")

test_that("corporate_design loads and validates the shipped EFK design", {
  design <- corporate_design(efk_path())
  expect_s3_class(design, "corporate_design")
  expect_identical(design$meta$name, "EFK")
  expect_true(is_hex(design$colors$qualitative[[1]]))
  expect_identical(design$colors$qualitative[[1]], "#DC0018")
  expect_true(is.character(design$colors$qualitative))
})

test_that("a minimal design inherits defaults", {
  tmp <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: Mini"), tmp)
  design <- corporate_design(tmp)
  expect_identical(design$meta$name, "Mini")
  # Defaults filled in:
  expect_true(length(design$colors$qualitative) >= 1)
  expect_identical(design$geometry$legend_position, "top")
})

test_that("invalid hex colours are rejected", {
  tmp <- tempfile(fileext = ".yml")
  writeLines(c("meta:", "  name: Bad", "colors:",
               "  qualitative: [\"not-a-colour\"]"), tmp)
  expect_error(corporate_design(tmp), "Hex")
})
