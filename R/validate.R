# Input validation -------------------------------------------------------------
#
# The package never converts invalid input into a valid-looking result: missing
# values, observations outside the declared bounds, non-positive subgroup sizes
# and updates after an alarm are errors, not silent fixes.

check_number <- function(x, arg, lower = -Inf, upper = Inf, allow_null = FALSE,
                         call = rlang::caller_env()) {
  if (is.null(x) && allow_null) return(invisible(NULL))
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    cli::cli_abort("{.arg {arg}} must be a single finite number.", call = call)
  }
  if (x < lower || x > upper) {
    cli::cli_abort("{.arg {arg}} must be between {lower} and {upper}, not {x}.", call = call)
  }
  invisible(x)
}

check_count <- function(x, arg, lower = 1L, call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x != round(x) || x < lower) {
    cli::cli_abort("{.arg {arg}} must be a whole number of at least {lower}.", call = call)
  }
  invisible(as.integer(x))
}

check_observations <- function(x, design, n = NULL, call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) == 0L) {
    cli::cli_abort("{.arg x} must be a non-empty numeric vector.", call = call)
  }
  if (anyNA(x) || any(!is.finite(x))) {
    bad <- which(is.na(x) | !is.finite(x))
    cli::cli_abort(c(
      "{.arg x} has {cli::qty(length(bad))}{length(bad)} missing or non-finite value{?s} (position{?s} {head(bad, 5)}).",
      "i" = "edetect does not impute or drop observations; decide what a missing observation means before updating."),
      call = call)
  }
  cls <- design$class
  if (cls %in% c("bernoulli", "poisson")) {
    if (is.null(n)) {
      cli::cli_abort("{.arg n} (subgroup size or area of opportunity) is required for the {.val {cls}} class.",
                     call = call)
    }
    if (length(n) == 1L) n <- rep(n, length(x))
    if (length(n) != length(x)) {
      cli::cli_abort("{.arg n} must have length 1 or the length of {.arg x}.", call = call)
    }
    if (!is.numeric(n) || anyNA(n) || any(n <= 0)) {
      cli::cli_abort("{.arg n} must be positive and non-missing.", call = call)
    }
    if (any(x < 0)) {
      cli::cli_abort("Counts in {.arg x} must be non-negative.", call = call)
    }
    if (cls == "bernoulli" && any(x > n)) {
      cli::cli_abort("Counts in {.arg x} cannot exceed the subgroup size {.arg n}.", call = call)
    }
  } else {
    if (!is.null(n)) {
      cli::cli_abort("{.arg n} is only used by the {.val bernoulli} and {.val poisson} classes.", call = call)
    }
    n <- rep(1, length(x))
  }
  if (cls == "bounded") {
    b <- design$bounds
    out <- which(x < b[1] | x > b[2])
    if (length(out)) {
      cli::cli_abort(c(
        "{cli::qty(length(out))}{length(out)} observation{?s} fall{?s/} outside the declared bounds [{b[1]}, {b[2]}] (position{?s} {head(out, 5)}).",
        "i" = "Observations are never clipped. Fix the data or declare wider bounds in {.fn edetect_design}."),
        call = call)
    }
  }
  list(x = as.numeric(x), n = as.numeric(n))
}

assert_design <- function(design, call = rlang::caller_env()) {
  if (!inherits(design, "edetect_design")) {
    cli::cli_abort("{.arg design} must be created by {.fn edetect_design}.", call = call)
  }
  invisible(design)
}

assert_chart <- function(x, call = rlang::caller_env()) {
  if (!inherits(x, "edetect_chart")) {
    cli::cli_abort("{.arg state} must be an {.cls edetect_chart} from {.fn edetect_init}.", call = call)
  }
  invisible(x)
}
