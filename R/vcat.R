#' Tool: Verbosity Cat
#'
#' Function which returns information based on the verbosity setting
#'
#'
#' @param verbosity The lowest verbosity level for which this message should be
#' shown (verbosity = -1 means no information at all, 0 = only warnings, 1 =
#' warnings and execution information, 2 = full information). If the verbosity
#' is set to 0 the message is written as warning, if the verbosity is set
#' higher than 0 it is written as a normal cat message.
#' @param ... The message to be shown
#' @param level This argument allows to establish a hierarchy of print
#' statements. The hierarchy is preserved for the next vcat executions.
#' Currently this setting can have 4 states: NULL (nothing will be changed), 0
#' (reset hierarchies), "+" (increase hierarchy level by 1) and "-" (decrease
#' hierarchy level by 1).
#' @param fill a logical or (positive) numeric controlling how the output is
#' broken into successive lines. If FALSE (default), only newlines created
#' explicitly by "\\n" are printed. Otherwise, the output is broken into lines
#' with print width equal to the option width if fill is TRUE, or the value of
#' fill if this is numeric. Non-positive fill values are ignored, with a warning.
#' @param show_prefix a logical defining whether a content specific prefix (e.g. "NOTE")
#' should be shown in front of the message or not. If prefix is not shown it will also
#' not show up in official statistics.
#' @param logOnly option to only log warnings and error message without creating warnings
#' or errors (expert use only).
#' @export
#' @author Jan Philipp Dietrich
#' @seealso \code{\link{readSource}}
#' @examples
#' \dontrun{
#' vcat(2, "Hello world!")
#' }
#' @importFrom utils capture.output
vcat <- function(verbosity, ..., level = NULL, fill = TRUE,
                 show_prefix = TRUE, logOnly = FALSE) { # nolint
  # deparse lists to character to prevent `(type 'list') cannot be handled by 'cat'`
  messages <- lapply(list(...), function(x) if (is.list(x)) deparse(x) else x)
  messages <- as.character(messages)

  # make sure that vcat is not run from within another vcat
  if (isWrapperActive("vcat")) return()
  setWrapperActive("vcat")
  setWrapperInactive("wrapperChecks")

  if (!is.null(level)) {
    if (level == 0) {
      options(gdt_nestinglevel = NULL) # nolint
    } else if (level == "-") {
      # remove empty space
      options(gdt_nestinglevel = substring(getOption("gdt_nestinglevel"), 2)) # nolint
      if (getOption("gdt_nestinglevel") == "") options(gdt_nestinglevel = NULL) # nolint
    }
  }

  d <- getConfig("diagnostics")
  writelog <- is.character(d)
  if (writelog) {
    logfile <- paste0(getConfig("outputfolder"), "/", d, ".log")
    fulllogfile <- paste0(getConfig("outputfolder"), "/", d, "_full.log")
  }
  prefix <- c("", "ERROR: ", "WARNING: ", "NOTE: ", "MINOR NOTE: ")[min(verbosity, 2) + 3]
  if (prefix == "" || !show_prefix) prefix <- NULL
  if (writelog && dir.exists(dirname(fulllogfile))) {
    base::cat(c(prefix, messages), fill = fill, sep = "", labels = getOption("gdt_nestinglevel"),
              file = fulllogfile, append = TRUE)
  }
  if (getConfig("verbosity") >= verbosity) {
    if (writelog && dir.exists(dirname(logfile))) {
      base::cat(c(prefix, messages), fill = fill, sep = "", labels = getOption("gdt_nestinglevel"),
                file = logfile, append = TRUE)
    }
    if (verbosity == -1) {
      base::message(paste(capture.output(base::cat(c(prefix, messages),
                                                   fill = fill, sep = "",
                                                   labels = getOption("gdt_nestinglevel")
      )), collapse = "\n"))
      if (!logOnly) {
        base::stop(..., call. = FALSE)
      }
    } else if (verbosity == 0) {
      if (!logOnly) {
        base::warning(..., call. = FALSE)
      }
      base::message(paste(capture.output(base::cat(c(prefix, messages), fill = fill, sep = "",
                                                   labels = getOption("gdt_nestinglevel"))), collapse = "\n"))
      options(madratWarningsCounter = getOption("madratWarningsCounter", 0) + 1) # nolint
    } else {
      base::message(paste(capture.output(base::cat(c(prefix, messages), fill = fill, sep = "",
                                                   labels = getOption("gdt_nestinglevel"))), collapse = "\n"))
    }
  }

  if (identical(level, "+")) {
    options(gdt_nestinglevel = paste0("~", getOption("gdt_nestinglevel"))) # nolint
  }
}

# redirect standard messaging functions to vcat
cat     <- function(...) vcat(1, ...)
warning <- function(...) vcat(0, ...)
stop    <- function(...) vcat(-1, ...)
