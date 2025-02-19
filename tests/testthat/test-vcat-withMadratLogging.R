test_that("vcat redirect works", {
  localConfig(verbosity = 1, .verbose = FALSE)
  expect_message(madrat:::cat("blub"), "NOTE: blub")
  expect_message(suppressWarnings(madrat:::warning("blub")), "WARNING: blub")
})

test_that("vcat can handle lists", {
  expect_warning(vcat(0, list(a = 3, b = "blub")), "3blub")
})

# define shortcut for withMadratLogging and a
# repeated calling of the same function
wML1 <- madrat:::withMadratLogging
wML2 <- function(expr) wML1(wML1(expr))

test_that("withMadratLogging properly logs warnings", {
  p <- maxample("pop")
  wmMagExp <- "^WARNING: \n?You are trying to mbind an empty magclass object\\. Is that really intended\\?\n$"
  wMagExp <- "You are trying to mbind an empty magclass object\\. Is that really intended\\?$"
  w <- "This is a warning"
  wExp <- paste0("^", w, "$")
  wmExp <- paste0("^WARNING: ", w, "\n$")
  for (withMadratLoggingX in c(wML1, wML2)) {
    expect_warning(expect_message(withMadratLoggingX(base::warning(w)), wmExp), wExp)
    expect_warning(expect_message(withMadratLoggingX(warning(w)), wmExp), wExp)
    expect_warning(expect_message(withMadratLoggingX(vcat(0, w)), wmExp), wExp)
    expect_warning(expect_message(withMadratLoggingX(trash <- mbind(p[1:10, , , invert = TRUE], p)), wmMagExp), wMagExp)
  }
})

test_that("withMadratLogging properly logs messages", {
  m <- "This is a message"
  mExp <- paste0("^NOTE: ", m, "\n$")
  localConfig(verbosity = 2, .verbose = FALSE)
  for (withMadratLoggingX in c(wML1, wML2)) {
    expect_message(withMadratLoggingX(base::message(m)), mExp)
    expect_message(withMadratLoggingX(message(m)), mExp)
    expect_message(withMadratLoggingX(vcat(1, m)), mExp)
    expect_message(withMadratLoggingX(vcat(2, m)), paste0("^MINOR NOTE: ", m, "\n$"))
  }
})

test_that("withMadratLogging properly logs warnings", {
  p <- maxample("pop")
  emMagExp <- "^ERROR: \n?subscript out of bounds \\(\"BLA\"\\)\n$"
  eMagExp <- "subscript out of bounds \\(\"BLA\"\\)"
  e <- "This is an error"
  eExp <- paste0("^", e, "$")
  emExp <- paste0("^WARNING: ", e, "\n$")
  for (withMadratLoggingX in c(wML1, wML2)) {
    expect_error(expect_message(withMadratLoggingX(p["BLA", , ]), emMagExp), eMagExp)
    expect_error(expect_message(withMadratLoggingX(base::stop(e)), emExp), eExp)
    expect_error(expect_message(withMadratLoggingX(stop(e)), emExp), eExp)
    expect_error(expect_message(withMadratLoggingX(vcat(-1, e)), emExp), eExp)
  }
})
