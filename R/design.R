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
#'   conditional success probability (given the earlier trials of the subgroup) at
#'   most/at least/equal to `center`; beyond that, dependence within a subgroup is
#'   allowed. This is the p chart.
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
#' (Shin, Ramdas and Rinaldo, 2024, Theorem 2.4), and the probability of a false
#' alarm by any time `t`, including data-dependent monitoring horizons, is at
#' most `t / arl` (Ramdas, 2026). The price is paid in detection delay, which
#' depends on the alternatives the mixture covers.
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
#'   every time) or `"cusum"` (CUSUM type, a maximum). Both are e-detectors and
#'   both use the threshold `arl`, which for the CUSUM type is valid but
#'   conservative (Shin, Ramdas and Rinaldo, 2024, Section 2.5); `"sr"` is the
#'   default.
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
#' @param phase1_beta Probability that the Phase I bound on the centre fails.
#'   When `center` is estimated from `phase1`, the detector is centred at a
#'   one-sided confidence bound of level `1 - phase1_beta` (the upper
#'   bound for `"up"`, the lower bound for `"down"`, both bounds at level
#'   `1 - phase1_beta / 2` for `"both"`) rather than at the estimate. With
#'   probability at least `1 - phase1_beta` over the Phase I sample the average
#'   run length is then at least `arl`, and the probability of a false alarm by
#'   time `t` is at most `phase1_beta + t / arl`. `NULL` centres the detector at
#'   the Phase I estimate (plug-in), for which no guarantee holds. Ignored when
#'   `center` is declared.
#'
#' @details
#' With a centre estimated from Phase I data, the guarantee of an e-detector is
#' not robust to estimation error: the Shiryaev--Roberts statistic is a
#' martingale plus a linear drift when the pre-change mean equals the centre,
#' so its average run length is close to `arl`, and a centre estimated below
#' the in-control mean turns the in-control e-values into evidence. The bounds
#' used by `phase1_beta` are inversions of the e-values of each class. For the
#' `"bounded"` class with `evalue = "betting"` the bound inverts a betting
#' martingale over the Phase I observations in the order given (Waudby-Smith
#' and Ramdas, 2024), which adapts to the variance of the data; with
#' `evalue = "hoeffding"` it is the Bernoulli Kullback--Leibler (Chernoff)
#' bound after rescaling to `[0, 1]`. The other classes use the Bernoulli
#' Kullback--Leibler bound (`"bernoulli"`), the Poisson
#' Kullback--Leibler bound for `"poisson"`, and the Gaussian bound with the
#' declared scale for `"subgaussian"`. They require Phase I observations whose
#' conditional means equal the in-control mean (independent and identically
#' distributed observations are a special case). When `sigma` is also estimated
#' from Phase I, the bound for the `"subgaussian"` class is approximate.
#'
#' The width of a betting bound has two regimes. While the bets adapt to the
#' variance it is close to `sd * sqrt(2 * log(1 / phase1_beta) / n)`; when the
#' standard deviation is small compared with the distance from the estimate to
#' the far bound, the bets are capped and the width is close to that distance
#' times `log(1 / phase1_beta) / (0.9 * n)`. The design records which one
#' applies in `bound_regime`, and the lag-one autocorrelation of a numeric
#' Phase I sample in `phase1_acf1`; [edetect_report()] states both.
#'
#' @return An object of class `edetect_design`.
#' @references Shin, J., Ramdas, A. and Rinaldo, A. (2024). E-detectors: a
#'   nonparametric framework for sequential change detection. *The New England
#'   Journal of Statistics in Data Science*, 2(2), 229--260.
#'   \doi{10.51387/23-NEJSDS51}
#'
#'   Ramdas, A. (2026). Universality of e-detectors for ARL control.
#'   arXiv:2608.12660.
#'
#'   Waudby-Smith, I. and Ramdas, A. (2024). Estimating means of bounded random
#'   variables by betting. *Journal of the Royal Statistical Society Series B*,
#'   86(1), 1--27. \doi{10.1093/jrsssb/qkad009}
#' @export
#' @examples
#' edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
#' edetect_design(arl = 500, class = "bernoulli", center = 0.02, direction = "up")
#' edetect_design(arl = 370, class = "subgaussian", phase1 = rnorm(100), sigma = 1, direction = "both")
edetect_design <- function(arl = 370, class = edetect_classes(), center = NULL,
                           bounds = NULL, sigma = NULL,
                           direction = c("up", "down", "both"),
                           type = c("sr", "cusum"),
                           evalue = c("betting", "hoeffding"),
                           delta = NULL, weights = NULL, phase1 = NULL,
                           phase1_beta = 0.1) {
  class <- rlang::arg_match(class)
  direction <- rlang::arg_match(direction)
  type <- rlang::arg_match(type)
  evalue <- rlang::arg_match(evalue)
  check_number(arl, "arl", lower = 1)
  check_number(phase1_beta, "phase1_beta", lower = 1e-12, upper = 0.5, allow_null = TRUE)

  if (class == "bounded") {
    if (is.null(bounds)) cli::cli_abort("{.arg bounds} are required for the {.val bounded} class.")
    if (!is.numeric(bounds) || length(bounds) != 2L || any(!is.finite(bounds)) || bounds[1] >= bounds[2]) {
      cli::cli_abort("{.arg bounds} must be two finite numbers {.code c(a, b)} with {.code a < b}.")
    }
  } else {
    bounds <- NULL
  }

  p1 <- summarise_phase1(phase1, class, bounds)
  sigma_source <- "declared"
  if (class == "subgaussian" && is.null(sigma)) {
    if (is.null(p1)) cli::cli_abort("{.arg sigma} is required for the {.val subgaussian} class (or supply {.arg phase1}).")
    sigma <- p1$sigma
    sigma_source <- "phase1"
  }
  if (class == "subgaussian") {
    check_number(sigma, "sigma")
    if (sigma <= 0) cli::cli_abort("{.arg sigma} must be positive.")
  }

  center_source <- "declared"
  center_bounds <- NULL
  if (is.null(center)) {
    if (is.null(p1)) {
      cli::cli_abort("Either {.arg center} or {.arg phase1} must be supplied.")
    }
    if (is.null(phase1_beta)) {
      center <- p1$center
      center_source <- "phase1"
    } else {
      center_bounds <- phase1_bound(p1, class, direction, phase1_beta, bounds, sigma, evalue, phase1)
      center <- switch(direction, up = center_bounds[["upper"]], down = center_bounds[["lower"]],
                       both = p1$center)
      center_source <- "phase1_bound"
    }
  } else {
    phase1_beta <- NULL
  }
  # Which term sets the width of a betting bound:
  # the variance term sigma sqrt(2 log(1/beta) / N), or the range term
  # (distance to the far bound) log(1/beta) / (0.9 N) once the bets are capped.
  bound_regime <- NA_character_
  if (center_source == "phase1_bound" && class == "bounded" && evalue == "betting") {
    level <- log(1 / if (direction == "both") phase1_beta / 2 else phase1_beta)
    var_term <- p1$sigma * sqrt(2 * level / p1$n)
    room <- c(if (direction != "down") bounds[2] - p1$center, if (direction != "up") p1$center - bounds[1])
    bound_regime <- if (max(room) * level / (0.9 * p1$n) > var_term) "range" else "variance"
  }
  c_up <- if (is.null(center_bounds)) center else center_bounds[["upper"]]
  c_down <- if (is.null(center_bounds)) center else center_bounds[["lower"]]
  goes_up <- direction != "down"; goes_down <- direction != "up"

  lo <- switch(class, bounded = bounds[1], bernoulli = 0, poisson = 0, subgaussian = -Inf)
  hi <- switch(class, bounded = bounds[2], bernoulli = 1, poisson = Inf, subgaussian = Inf)
  check_number(center, "center", lower = lo, upper = hi)
  if ((goes_up && c_up >= hi) || (goes_down && c_down <= lo)) {
    if (center_source == "phase1_bound") {
      cli::cli_abort(c(
        "The Phase I bound on the centre reaches the edge of the class: no change in that direction can be detected.",
        "i" = "Use more Phase I data or a larger {.arg phase1_beta}."))
    }
    cli::cli_abort(switch(class,
      bounded = "{.arg center} sits on a bound: no change in that direction is possible.",
      bernoulli = "{.arg center} of 0 or 1 leaves no room for a change in that direction.",
      poisson = "A zero {.arg center} leaves no room for a decrease."))
  }
  if (class != "bounded") evalue <- "exponential"

  mix <- build_mixture(class, c_up, c_down, bounds, sigma, direction, evalue, delta, weights)

  structure(list(
    arl = arl, alpha = 1 / arl, class = class, center = center,
    center_source = center_source, center_k = mix$center, center_bounds = center_bounds,
    phase1_beta = phase1_beta, n_phase1 = if (is.null(p1)) 0L else p1$n,
    phase1_acf1 = if (is.null(p1)) NA_real_ else p1$acf1 %||% NA_real_, bound_regime = bound_regime,
    bounds = bounds, sigma = sigma, sigma_source = sigma_source, direction = direction, type = type,
    evalue = evalue, delta = mix$delta, lambda = mix$lambda, weights = mix$weights,
    created = Sys.time(), version = as.character(utils::packageVersion("edetect"))
  ), class = "edetect_design")
}

summarise_phase1 <- function(phase1, class, bounds = NULL) {
  if (is.null(phase1)) return(NULL)
  if (class %in% c("bernoulli", "poisson")) {
    if (!is.data.frame(phase1) || !all(c("x", "n") %in% names(phase1))) {
      cli::cli_abort("{.arg phase1} must be a data frame with columns {.field x} and {.field n} for the {.val {class}} class.")
    }
    if (anyNA(phase1$x) || anyNA(phase1$n) || any(phase1$n <= 0) || any(phase1$x < 0)) {
      cli::cli_abort("{.arg phase1} has missing, negative or zero-size rows.")
    }
    if (class == "bernoulli" && any(phase1$x > phase1$n)) {
      cli::cli_abort("Counts in {.arg phase1} cannot exceed the subgroup sizes.")
    }
    list(center = sum(phase1$x) / sum(phase1$n), sigma = NULL, n = nrow(phase1), total = sum(phase1$n))
  } else {
    if (!is.numeric(phase1) || length(phase1) < 2L || anyNA(phase1)) {
      cli::cli_abort("{.arg phase1} must be a numeric vector of at least two non-missing values.")
    }
    if (class == "bounded" && any(phase1 < bounds[1] | phase1 > bounds[2])) {
      cli::cli_abort("{.arg phase1} has observations outside the declared {.arg bounds}.")
    }
    acf1 <- if (length(phase1) >= 3L && stats::sd(phase1) > 0) stats::acf(phase1, lag.max = 1, plot = FALSE)$acf[2] else NA_real_
    list(center = mean(phase1), sigma = stats::sd(phase1), n = length(phase1), total = length(phase1), acf1 = acf1)
  }
}

# One-sided confidence bounds for the in-control centre: the inversion of the
# e-value of each class over the Phase I sample (betting for the bounded class
# with betting e-values, Chernoff otherwise). For "both" each side gets half of
# beta. Unused sides are NA.
phase1_bound <- function(p1, class, direction, beta, bounds, sigma, evalue = "betting", phase1 = NULL) {
  level <- log(1 / if (direction == "both") beta / 2 else beta)
  side <- function(s) {
    switch(class,
      bounded = {
        a <- bounds[1]; b <- bounds[2]
        a + (b - a) * if (evalue == "betting") betting_bound((phase1 - a) / (b - a), level, s)
                      else chernoff_bernoulli((p1$center - a) / (b - a), p1$total, level, s)
      },
      bernoulli = chernoff_bernoulli(p1$center, p1$total, level, s),
      poisson = chernoff_poisson(p1$center, p1$total, level, s),
      subgaussian = p1$center + (if (s == "upper") 1 else -1) * sigma * sqrt(2 * level / p1$total))
  }
  c(estimate = p1$center,
    lower = if (direction != "up") side("lower") else NA_real_,
    upper = if (direction != "down") side("upper") else NA_real_)
}

# Upper (or, by reflection, lower) confidence bound for the mean of [0, 1]
# observations y, in time order, by betting: the wealth
#   W(m) = prod(1 + theta_i (m - y_i) / (1 - m))
# has expectation at most one at the true mean, and with theta_i predictable and
# in [0, 0.9] it is increasing in m, so {m : W(m) < exp(level)} is an interval
# whose right end is the bound. theta_i follows the predictable plug-in rule of
# Waudby-Smith and Ramdas (2024), on the bet scale lambda = theta / (1 - m).
betting_bound <- function(y, level, side) {
  if (side == "lower") return(1 - betting_bound(1 - y, level, "upper"))
  n <- length(y); i <- seq_len(n)
  mu_hat <- (0.5 + cumsum(y)) / (i + 1)
  s2 <- (0.25 + cumsum((y - mu_hat)^2)) / (i + 1)
  mu_prev <- c(0.5, mu_hat[-n]); s2_prev <- c(0.25, s2[-n])
  theta <- pmin(sqrt(2 * level / (n * s2_prev)) * (1 - mu_prev), 0.9)
  log_wealth <- function(m) sum(log1p(theta * (m - y) / (1 - m)))
  hi <- 1 - 1e-12; lo <- mean(y)
  if (log_wealth(hi) < level) return(1)
  if (log_wealth(lo) >= level) return(lo)
  stats::uniroot(function(m) log_wealth(m) - level, c(lo, hi), tol = 1e-12)$root
}

kl_bernoulli <- function(p, q) {
  (if (p > 0) p * log(p / q) else 0) + (if (p < 1) (1 - p) * log((1 - p) / (1 - q)) else 0)
}

kl_poisson <- function(a, b) (if (a > 0) a * log(a / b) else 0) - a + b

# The q on the requested side of p with total * kl(p, q) = level.
chernoff_bernoulli <- function(p, total, level, side) {
  f <- function(q) total * kl_bernoulli(p, q) - level
  if (side == "upper") {
    if (p >= 1) return(1)
    stats::uniroot(f, c(p, 1 - 1e-15), tol = 1e-12)$root
  } else {
    if (p <= 0) return(0)
    stats::uniroot(f, c(1e-15, p), tol = 1e-12)$root
  }
}

chernoff_poisson <- function(r, total, level, side) {
  f <- function(q) total * kl_poisson(r, q) - level
  if (side == "upper") {
    hi <- max(1, 2 * r)
    while (f(hi) < 0) hi <- 2 * hi
    stats::uniroot(f, c(r, hi), tol = 1e-12)$root
  } else {
    if (r <= 0) return(0)
    stats::uniroot(f, c(1e-300, r), tol = 1e-12)$root
  }
}

# Map post-change shifts to bets. Returns delta (signed), lambda (signed), the
# centre of each bet and normalised weights. Increases are bet against c_up and
# decreases against c_down (equal unless the centre comes from a Phase I
# bound). For direction "both" the grid is mirrored and the weights split in
# half. Betting e-values 1 + lambda (z - m0) on [0, 1] need lambda <= 1 / m0
# (increase) or |lambda| <= 1 / (1 - m0) (decrease) to stay non-negative; a
# shift d is bet with the fraction d / room of that cap, where room is how far
# the mean can move in that direction.
build_mixture <- function(class, c_up, c_down, bounds, sigma, direction, evalue, delta, weights) {
  fractions <- c(0.05, 0.1, 0.2, 0.35, 0.5, 0.7, 0.9)
  if (!is.null(delta) && (!is.numeric(delta) || any(!is.finite(delta)) || any(delta <= 0))) {
    cli::cli_abort("{.arg delta} must be positive finite shifts; the sign follows {.arg direction}.")
  }
  one_side <- function(sign) {
    center <- if (sign > 0) c_up else c_down
    out <- if (class == "bounded") {
      a <- bounds[1]; b <- bounds[2]
      m0 <- (center - a) / (b - a)
      room <- if (sign > 0) 1 - m0 else m0            # how far the mean can move
      cap <- if (sign > 0) 1 / m0 else 1 / (1 - m0)   # largest admissible |lambda| for betting
      d01 <- if (is.null(delta)) fractions * room else pmin(delta / (b - a), 0.999 * room)
      lam <- if (evalue == "betting") sign * pmin(d01 / room, 0.99) * cap
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
    out$center <- rep(center, length(out$delta))
    out
  }
  sides <- switch(direction, up = list(one_side(1)), down = list(one_side(-1)),
                  both = list(one_side(1), one_side(-1)))
  pick <- function(field) unname(unlist(lapply(sides, `[[`, field)))
  if (is.null(weights)) {
    w <- unlist(lapply(sides, function(s) rep(1 / length(s$delta), length(s$delta)))) / length(sides)
  } else {
    if (length(weights) != length(sides[[1]]$delta) || any(weights < 0) || sum(weights) <= 0) {
      cli::cli_abort("{.arg weights} must be non-negative, with one weight per value of {.arg delta}.")
    }
    w <- rep(weights / sum(weights), length(sides)) / length(sides)
  }
  list(delta = pick("delta"), lambda = pick("lambda"), center = pick("center"), weights = unname(w))
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
  if (!is.null(x$center_bounds)) {
    cb <- x$center_bounds
    cli::cli_text("Phase I estimate {signif(cb[['estimate']], 4)}; bets centred at {paste(signif(unique(x$center_k), 4), collapse = ' and ')} (failure probability {x$phase1_beta})")
  }
  if (!is.null(x$bounds)) cli::cli_text("Bounds: [{x$bounds[1]}, {x$bounds[2]}]; e-values: {.val {x$evalue}}")
  if (!is.null(x$sigma)) cli::cli_text("Sub-Gaussian scale: {signif(x$sigma, 4)}")
  cli::cli_text("Direction: {.val {x$direction}}; type: {.val {x$type}}; target ARL {x$arl} (threshold {x$arl} on the e-detector scale)")
  cli::cli_text("Mixture over {length(x$delta)} shift{?s}: {paste(signif(x$delta, 3), collapse = ', ')}")
  invisible(x)
}
