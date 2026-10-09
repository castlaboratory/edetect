# Chart wrappers ---------------------------------------------------------------
#
# One call from data to a monitored chart: build the design, initialise the
# detector and feed the Phase II observations.

#' Individual-observation chart for bounded data
#'
#' @param x Phase II observations.
#' @param bounds Known bounds of the observations.
#' @param center Pre-change mean; omit to estimate it from `phase1`.
#' @param phase1 Optional Phase I observations.
#' @param ... Passed to [edetect_design()] (`arl`, `direction`, `type`,
#'   `evalue`, `delta`, `weights`).
#' @return An `edetect_chart`.
#' @export
#' @examples
#' set.seed(2)
#' x <- c(runif(40, 0.3, 0.7), runif(40, 0.5, 0.9))
#' chart <- edetect_x(x, bounds = c(0, 1), center = 0.5, arl = 200)
#' edetect_alarm(chart)
edetect_x <- function(x, bounds, center = NULL, phase1 = NULL, ...) {
  design <- edetect_design(class = "bounded", center = center, bounds = bounds, phase1 = phase1, ...)
  edetect_update(edetect_init(design), x)
}

#' p chart: proportion of nonconforming units
#'
#' @param x Counts of nonconforming units per subgroup.
#' @param n Subgroup sizes (one per subgroup or a single value).
#' @param center Pre-change proportion; omit to estimate it from `phase1`.
#' @param phase1 Optional Phase I data frame with columns `x` and `n`.
#' @inheritParams edetect_x
#' @return An `edetect_chart`.
#' @export
#' @examples
#' chart <- edetect_p(x = c(1, 0, 2, 1, 3, 4, 5, 6), n = 100, center = 0.01, arl = 100)
#' edetect_alarm(chart)
edetect_p <- function(x, n, center = NULL, phase1 = NULL, ...) {
  design <- edetect_design(class = "bernoulli", center = center, phase1 = phase1, ...)
  edetect_update(edetect_init(design), x, n = n)
}

#' c chart: counts of nonconformities per unit
#'
#' @param x Counts per inspection unit.
#' @param center Pre-change mean count; omit to estimate it from `phase1`.
#' @param phase1 Optional Phase I counts (a numeric vector, unit exposure).
#' @inheritParams edetect_x
#' @return An `edetect_chart`.
#' @export
#' @examples
#' chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#' edetect_alarm(chart)
edetect_c <- function(x, center = NULL, phase1 = NULL, ...) {
  if (!is.null(phase1) && !is.data.frame(phase1)) phase1 <- data.frame(x = phase1, n = 1)
  design <- edetect_design(class = "poisson", center = center, phase1 = phase1, ...)
  edetect_update(edetect_init(design), x, n = 1)
}

#' u chart: nonconformities per unit of exposure
#'
#' @param x Counts per sample.
#' @param n Exposure (area of opportunity) of each sample.
#' @param center Pre-change rate per unit exposure; omit to estimate it from `phase1`.
#' @param phase1 Optional Phase I data frame with columns `x` and `n`.
#' @inheritParams edetect_x
#' @return An `edetect_chart`.
#' @export
#' @examples
#' chart <- edetect_u(x = c(3, 2, 4, 3, 8, 9, 11), n = c(2, 2, 2, 2, 2, 2, 2), center = 1.5, arl = 100)
#' edetect_alarm(chart)
edetect_u <- function(x, n, center = NULL, phase1 = NULL, ...) {
  design <- edetect_design(class = "poisson", center = center, phase1 = phase1, ...)
  edetect_update(edetect_init(design), x, n = n)
}

#' Regression chart: monitoring residuals of a Phase I model
#'
#' Fits a linear model on Phase I data and monitors the Phase II residuals
#' `y - prediction` as a sub-Gaussian stream centred at zero, with the residual
#' standard deviation of the Phase I fit as the declared scale (or a `sigma`
#' supplied by the user). The fitted model is kept in the chart.
#'
#' @param formula Model formula.
#' @param phase1 Phase I data frame.
#' @param phase2 Phase II data frame with the same columns.
#' @param sigma Declared sub-Gaussian scale of the residuals; default the Phase I
#'   residual standard deviation.
#' @inheritParams edetect_x
#' @return An `edetect_chart` with an extra element `fit`.
#' @export
#' @examples
#' set.seed(3)
#' d1 <- data.frame(z = 1:60); d1$y <- 2 + 0.5 * d1$z + rnorm(60, sd = 0.3)
#' d2 <- data.frame(z = 61:100)
#' d2$y <- 2 + 0.5 * d2$z + rnorm(40, sd = 0.3) + c(rep(0, 20), rep(1, 20))
#' chart <- edetect_regression(y ~ z, phase1 = d1, phase2 = d2, arl = 200)
#' edetect_alarm(chart)
edetect_regression <- function(formula, phase1, phase2, sigma = NULL, ...) {
  fit <- stats::lm(formula, data = phase1)
  if (is.null(sigma)) sigma <- stats::sigma(fit)
  resid <- phase2[[all.vars(formula)[1]]] - stats::predict(fit, newdata = phase2)
  design <- edetect_design(class = "subgaussian", center = 0, sigma = sigma, ...)
  design$center_source <- "phase1"
  design$n_phase1 <- nrow(phase1)
  state <- edetect_update(edetect_init(design), resid)
  state$fit <- fit
  state
}
