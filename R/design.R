# Design of an e-detector ------------------------------------------------------

#' Pre-change classes
#'
#' The classes of pre-change distributions for which `edetect` builds e-values.
#' Each class is a statement about the observations *before* a change; the
#' average run length guarantee holds for every distribution in the class.
#'
#' * `"bounded"`: observations in known bounds `[a, b]` with mean at most (direction
#'   `"up"`), at least (`"down"`) or equal to (`"both"`) `center`. Nothing else is
#'   assumed. E-values: `"betting"` (tight, default) or `"hoeffding"` (sub-Bernoulli).
#' * `"subgaussian"`: observations with mean `center` and sub-Gaussian tails with
#'   declared scale `sigma`. Gaussian data with standard deviation `sigma` is the
#'   boundary case; heavier tails violate the class.
#' * `"bernoulli"`: counts of successes in subgroups of size `n`, each trial with
#'   success probability at most/at least/equal to `center`; any dependence within
#'   a subgroup is allowed. This is the p chart.
#' * `"poisson"`: counts with exposure `n` whose moment generating function is at
#'   most that of a Poisson with rate `center` per unit exposure (Poisson and
#'   underdispersed counts; overdispersed counts violate the class). These are the
#'   c (`n = 1`) and u charts.
#'
#' @return A character vector of class names.
#' @export
#' @examples
#' edetect_classes()
edetect_classes <- function() c("bounded", "subgaussian", "bernoulli", "poisson")

#' Design an e-detector
#'
#' Fixes, before any Phase II observation is seen, everything the detector needs:
#' the pre-change class and its parameters, the direction of the change to
#' detect, the detector type (Shiryaev--Roberts or CUSUM), the family of
#' e-values and the mixture over post-change alternatives, and the target
#' average run length (ARL) to a false alarm.
#'
#' The guarantee is distribution-free within the class: for every pre-change
#' distribution in it, the expected time to a false alarm is at least `arl`
#' (Shin, Ramdas and Rinaldo, 2024). The price is paid in detection delay,
#' which depends on the alternatives the mixture covers.
#'
#' @param arl Target average run length to a false alarm. The alarm threshold
#'   is `arl` on the e-detector scale (equivalently `alpha = 1 / arl`).
#' @param class Pre-change class, see [edetect_classes()].
#' @param center Pre-change mean (`"bounded"`, `"subgaussian"`), success
#'   probability (`"bernoulli"`) or rate per unit exposure (`"poisson"`). May be
#'   omitted when `phase1` is supplied.
#' @param bounds Known bounds `c(a, b)` of the observations (`"bounded"` only).
#' @param sigma Declared sub-Gaussian scale (`"subgaussian"` only). May be
#'   omitted when `phase1` is supplied, in which case the Phase I standard
#'   deviation is used and recorded as an assumption.
#' @param direction Change to detect: an increase (`"up"`), a decrease
#'   (`"down"`) or either (`"both"`, a half-and-half mixture of the two).
#' @param type `"sr"` (Shiryaev--Roberts type, a sum of e-processes started at
#'   every time) or `"cusum"` (CUSUM type, a maximum). Both are e-detectors;
#'   `"sr"` is the default.
#' @param evalue E-value family for the `"bounded"` class: `"betting"`
#'   (`1 + lambda (x - center)`, tight for bounded data) or `"hoeffding"`
#'   (sub-Bernoulli exponential). Ignored by the other classes, which use their
#'   natural exponential e-values.
#' @param delta Post-change shifts the mixture covers, in the units of the
#'   observations (positive numbers; the sign follows `direction`). Each shift
#'   is mapped to the bet `lambda` that is optimal for it in the class. The
#'   default is a geometric grid spanning small to large shifts.
#' @param weights Mixture weights over `delta`, normalised internally. Default
#'   uniform.
#' @param phase1 Optional Phase I (in-control) data: a numeric vector for the
#'   `"bounded"` and `"subgaussian"` classes, or a data frame with columns `x`
#'   (counts) and `n` for `"bernoulli"` and `"poisson"`. Used to set `center`
#'   (and `sigma`) when they are not declared; the source is recorded in the
#'   design and in every report.
#'
#' @return An object of class `edetect_design`.
#' @references Shin, J., Ramdas, A. and Rinaldo, A. (2024). E-detectors: a
#'   nonparametric framework for sequential change detection. *The New England
#'   Journal of Statistics in Data Science*, 2(2), 229--260.
#' @export
#' @examples
#' edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
#' edetect_design(arl = 500, class = "bernoulli", center = 0.02, direction = "up")
#' edetect_design(arl = 370, class = "subgaussian", phase1 = rnorm(100), direction = "both")
edetect_design <- function(arl = 370, class = edetect_classes(), center = NULL,
                           bounds = NULL, sigma = NULL,
                           direction = c("up", "down", "both"),
                           type = c("sr", "cusum"),
                           evalue = c("betting", "hoeffding"),
                           delta = NULL, weights = NULL, phase1 = NULL) {
  class <- rlang::arg_match(class)
  direction <- rlang::arg_match(direction)
  type <- rlang::arg_match(type)
  evalue <- rlang::arg_match(evalue)
  check_number(arl, "arl", lower = 1)

  center_source <- "declared"
  p1 <- summarise_phase1(phase1, class)
  if (is.null(center)) {
    if (is.null(p1)) {
      cli::cli_abort("Either {.arg center} or {.arg phase1} must be supplied.")
    }
    center <- p1$center
    center_source <- "phase1"
  }
  if (class == "subgaussian" && is.null(sigma)) {
    if (is.null(p1)) cli::cli_abort("{.arg sigma} is required for the {.val subgaussian} class (or supply {.arg phase1}).")
    sigma <- p1$sigma
  }

  if (class == "bounded") {
    if (is.null(bounds)) cli::cli_abort("{.arg bounds} are required for the {.val bounded} class.")
    if (!is.numeric(bounds) || length(bounds) != 2L || any(!is.finite(bounds)) || bounds[1] >= bounds[2]) {
      cli::cli_abort("{.arg bounds} must be two finite numbers {.code c(a, b)} with {.code a < b}.")
    }
    check_number(center, "center", lower = bounds[1], upper = bounds[2])
    if ((center == bounds[1] && direction != "up") || (center == bounds[2] && direction != "down")) {
      cli::cli_abort("{.arg center} sits on a bound: no change in that direction is possible.")
    }
  } else {
    bounds <- NULL
    if (class == "bernoulli") check_number(center, "center", lower = 0, upper = 1)
    if (class == "poisson") check_number(center, "center", lower = 0)
    if (class == "subgaussian") check_number(center, "center")
    if (class == "bernoulli" && ((center == 0 && direction != "up") || (center == 1 && direction != "down"))) {
      cli::cli_abort("{.arg center} of 0 or 1 leaves no room for a change in that direction.")
    }
    if (class == "poisson" && center == 0 && direction != "up") {
      cli::cli_abort("A zero {.arg center} leaves no room for a decrease.")
    }
    if (class == "subgaussian") {
      check_number(sigma, "sigma")
      if (sigma <= 0) cli::cli_abort("{.arg sigma} must be positive.")
    }
  }
  if (class != "bounded") evalue <- "exponential"

  mix <- build_mixture(class, center, bounds, sigma, direction, evalue, delta, weights)

  structure(list(
    arl = arl, alpha = 1 / arl, class = class, center = center,
    center_source = center_source, n_phase1 = if (is.null(p1)) 0L else p1$n,
    bounds = bounds, sigma = sigma, direction = direction, type = type,
    evalue = evalue, delta = mix$delta, lambda = mix$lambda, weights = mix$weights,
    created = Sys.time(), version = as.character(utils::packageVersion("edetect"))
  ), class = "edetect_design")
}

summarise_phase1 <- function(phase1, class) {
  if (is.null(phase1)) return(NULL)
  if (class %in% c("bernoulli", "poisson")) {
    if (!is.data.frame(phase1) || !all(c("x", "n") %in% names(phase1))) {
      cli::cli_abort("{.arg phase1} must be a data frame with columns {.field x} and {.field n} for the {.val {class}} class.")
    }
    if (anyNA(phase1$x) || anyNA(phase1$n) || any(phase1$n <= 0) || any(phase1$x < 0)) {
      cli::cli_abort("{.arg phase1} has missing, negative or zero-size rows.")
    }
    list(center = sum(phase1$x) / sum(phase1$n), sigma = NULL, n = nrow(phase1))
  } else {
    if (!is.numeric(phase1) || length(phase1) < 2L || anyNA(phase1)) {
      cli::cli_abort("{.arg phase1} must be a numeric vector of at least two non-missing values.")
    }
    list(center = mean(phase1), sigma = stats::sd(phase1), n = length(phase1))
  }
}

# Map post-change shifts to bets. Returns delta (signed), lambda (signed) and
# normalised weights. For direction "both" the grid is mirrored and the weights
# split in half. Betting e-values 1 + lambda (z - m0) on [0, 1] need
# lambda <= 1 / m0 (increase) or |lambda| <= 1 / (1 - m0) (decrease) to stay
# non-negative; a shift d is bet with the fraction d / room of that cap, where
# room is how far the mean can move in that direction.
build_mixture <- function(class, center, bounds, sigma, direction, evalue, delta, weights) {
  fractions <- c(0.05, 0.1, 0.2, 0.35, 0.5, 0.7, 0.9)
  if (!is.null(delta) && (!is.numeric(delta) || any(!is.finite(delta)) || any(delta <= 0))) {
    cli::cli_abort("{.arg delta} must be positive finite shifts; the sign follows {.arg direction}.")
  }
  one_side <- function(sign) {
    if (class == "bounded") {
      a <- bounds[1]; b <- bounds[2]
      m0 <- (center - a) / (b - a)
      room <- if (sign > 0) 1 - m0 else m0            # how far the mean can move
      cap <- if (sign > 0) 1 / m0 else 1 / (1 - m0)   # largest admissible |lambda| for betting
      d01 <- if (is.null(delta)) fractions * room else pmin(delta / (b - a), 0.999 * room)
      lam <- if (evalue == "betting") sign * pmin(d01 / room, 1) * cap
             else lr_lambda_bernoulli(m0, sign * d01)
      list(delta = sign * d01 * (b - a), lambda = lam)
    } else if (class == "bernoulli") {
      room <- if (sign > 0) 1 - center else center
      d <- if (is.null(delta)) fractions * room else pmin(delta, 0.999 * room)
      list(delta = sign * d, lambda = lr_lambda_bernoulli(center, sign * d))
    } else if (class == "poisson") {
      d <- if (is.null(delta)) sqrt(center) * c(0.25, 0.5, 1, 1.5, 2, 3) else delta
      if (sign < 0) d <- pmin(d, 0.999 * center)
      list(delta = sign * d, lambda = log((center + sign * d) / center))
    } else {
      d <- if (is.null(delta)) sigma * c(0.25, 0.5, 1, 1.5, 2, 3) else delta
      list(delta = sign * d, lambda = sign * d / sigma^2)
    }
  }
  sides <- switch(direction, up = list(one_side(1)), down = list(one_side(-1)),
                  both = list(one_side(1), one_side(-1)))
  d <- unlist(lapply(sides, `[[`, "delta")); lam <- unlist(lapply(sides, `[[`, "lambda"))
  if (is.null(weights)) {
    w <- unlist(lapply(sides, function(s) rep(1 / length(s$delta), length(s$delta)))) / length(sides)
  } else {
    if (length(weights) != length(sides[[1]]$delta) || any(weights < 0) || sum(weights) <= 0) {
      cli::cli_abort("{.arg weights} must be non-negative, with one weight per value of {.arg delta}.")
    }
    w <- rep(weights / sum(weights), length(sides)) / length(sides)
  }
  list(delta = unname(d), lambda = unname(lam), weights = unname(w))
}

# The log-likelihood-ratio bet of a Bernoulli mean shift from m0 to m0 + d,
# which is the optimal lambda of the sub-Bernoulli e-value for that shift.
lr_lambda_bernoulli <- function(m0, d) {
  m1 <- m0 + d
  log(m1 * (1 - m0) / (m0 * (1 - m1)))
}

#' @export
print.edetect_design <- function(x, ...) {
  cli::cli_h1("e-detector design")
  cli::cli_text("Pre-change class: {.val {x$class}}; centre {signif(x$center, 4)} ({x$center_source}{if (x$n_phase1 > 0) paste0(', n = ', x$n_phase1) else ''})")
  if (!is.null(x$bounds)) cli::cli_text("Bounds: [{x$bounds[1]}, {x$bounds[2]}]; e-values: {.val {x$evalue}}")
  if (!is.null(x$sigma)) cli::cli_text("Sub-Gaussian scale: {signif(x$sigma, 4)}")
  cli::cli_text("Direction: {.val {x$direction}}; type: {.val {x$type}}; target ARL {x$arl} (threshold {x$arl} on the e-detector scale)")
  cli::cli_text("Mixture over {length(x$delta)} shift{?s}: {paste(signif(x$delta, 3), collapse = ', ')}")
  invisible(x)
}
