# Run-length simulation --------------------------------------------------------

#' Simulate run lengths of a design
#'
#' Estimates the average run length to a false alarm (ARL, no change) or the
#' detection delay (with a change) of an e-detector design by Monte Carlo. The
#' recursion is vectorised across replications.
#'
#' @param design An [edetect_design()].
#' @param pre A function `function(n)` returning `n` pre-change observations
#'   (for the `"bernoulli"` and `"poisson"` classes, a data frame with columns
#'   `x` and `n`).
#' @param post Optional function with the same signature for post-change
#'   observations. When supplied, the change happens at time `change_at`.
#' @param change_at Time of the first post-change observation.
#' @param n_rep Number of replications.
#' @param max_t Censoring time; runs that have not alarmed by `max_t` are
#'   reported as censored.
#' @return A list of class `edetect_runs` with `runs` (a tibble with one row
#'   per replication: `run_length`, `alarm`, `delay` when there is a change,
#'   `false_alarm`) and `summary` (a one-row tibble with the mean run length or
#'   delay, its standard error, the censoring fraction and, with a change, the
#'   false-alarm fraction before `change_at`).
#' @export
#' @examples
#' design <- edetect_design(arl = 50, class = "subgaussian", center = 0, sigma = 1)
#' set.seed(1)
#' edetect_arl(design, pre = function(n) rnorm(n), n_rep = 50, max_t = 2000)$summary
#' edetect_arl(design, pre = function(n) rnorm(n), post = function(n) rnorm(n, 1),
#'             change_at = 20, n_rep = 50, max_t = 500)$summary
edetect_arl <- function(design, pre, post = NULL, change_at = 1L, n_rep = 200L, max_t = NULL) {
  assert_design(design)
  n_rep <- check_count(n_rep, "n_rep"); change_at <- check_count(change_at, "change_at")
  if (is.null(max_t)) max_t <- as.integer(min(20 * design$arl, 1e5))
  max_t <- check_count(max_t, "max_t")
  if (!is.null(post) && change_at > max_t) cli::cli_abort("{.arg change_at} must not exceed {.arg max_t}.")
  stream <- function(gen, n) {
    s <- gen(n)
    if (design$class %in% c("bernoulli", "poisson")) {
      if (!is.data.frame(s) || !all(c("x", "n") %in% names(s))) cli::cli_abort("The generator must return a data frame with columns {.field x} and {.field n} for the {.val {design$class}} class.")
      list(x = s$x, n = s$n)
    } else list(x = as.numeric(s), n = rep(1, n))
  }
  x <- matrix(0, max_t, n_rep); nn <- matrix(1, max_t, n_rep)
  for (r in seq_len(n_rep)) {
    if (is.null(post)) {
      s <- stream(pre, max_t)
    } else {
      s1 <- stream(pre, change_at - 1L); s2 <- stream(post, max_t - change_at + 1L)
      s <- list(x = c(s1$x, s2$x), n = c(s1$n, s2$n))
    }
    x[, r] <- s$x; nn[, r] <- s$n
  }
  k <- length(design$lambda); log_w <- log(design$weights); log_arl <- log(design$arl)
  log_sr <- matrix(-Inf, k, n_rep); log_cu <- matrix(-Inf, k, n_rep)
  run_length <- rep(NA_integer_, n_rep); active <- rep(TRUE, n_rep)
  for (t in seq_len(max_t)) {
    idx <- which(active)
    le <- log_evalues(design, x[t, idx], nn[t, idx])
    log_sr[, idx] <- log_sum_exp(0, log_sr[, idx, drop = FALSE]) + le
    log_cu[, idx] <- pmax(0, log_cu[, idx, drop = FALSE]) + le
    lm <- if (design$type == "sr") log_sr[, idx, drop = FALSE] else log_cu[, idx, drop = FALSE]
    stat <- log_mix(log_w, lm)
    hit <- stat >= log_arl
    run_length[idx[hit]] <- t
    active[idx[hit]] <- FALSE
    if (!any(active)) break
  }
  alarm <- !is.na(run_length)
  runs <- tibble::tibble(run_length = run_length, alarm = alarm)
  if (is.null(post)) {
    summary <- tibble::tibble(
      arl_estimate = mean(ifelse(alarm, run_length, max_t)),
      se = stats::sd(ifelse(alarm, run_length, max_t)) / sqrt(n_rep),
      censored = mean(!alarm), target_arl = design$arl, n_rep = n_rep, max_t = max_t)
  } else {
    runs$false_alarm <- alarm & run_length < change_at
    runs$delay <- ifelse(alarm & !runs$false_alarm, run_length - change_at + 1L, NA_integer_)
    summary <- tibble::tibble(
      delay_mean = mean(runs$delay, na.rm = TRUE),
      se = stats::sd(runs$delay, na.rm = TRUE) / sqrt(sum(!is.na(runs$delay))),
      false_alarm = mean(runs$false_alarm), censored = mean(!alarm),
      change_at = change_at, n_rep = n_rep, max_t = max_t)
  }
  structure(list(runs = runs, summary = summary, design = design), class = "edetect_runs")
}

#' @export
print.edetect_runs <- function(x, ...) {
  cli::cli_h1("e-detector run lengths")
  print(x$summary)
  invisible(x)
}
