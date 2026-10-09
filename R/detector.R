# The e-detector: initialise, update, alarm, report -----------------------------
#
# Per bet lambda_k the Shiryaev-Roberts recursion is M_t = (1 + M_{t-1}) e_t and
# the CUSUM recursion is M_t = max(1, M_{t-1}) e_t, both in log space. The
# detector statistic is the mixture over k with the design weights: for "sr"
# this equals the SR detector of the mixture e-process; for "cusum" the mixture
# is taken outside the maximum, which keeps the recursion O(K) and is still an
# e-detector (a convex combination of e-detectors). The alarm is raised when the
# statistic reaches the target ARL.

#' Initialise an e-detector
#'
#' @param design An [edetect_design()].
#' @return An object of class `edetect_chart` holding the design, the running
#'   state and an empty trajectory.
#' @export
#' @examples
#' design <- edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
#' state <- edetect_init(design)
#' state
edetect_init <- function(design) {
  assert_design(design)
  k <- length(design$lambda)
  structure(list(
    design = design,
    log_sr = rep(-Inf, k), log_cu = rep(-Inf, k), restart = rep(1L, k),
    t = 0L, alarm_time = NA_integer_, alarm_evidence = NA_real_,
    change_estimate = NA_integer_,
    trajectory = empty_trajectory(),
    versions = list(edetect = as.character(utils::packageVersion("edetect")),
                    R = R.version.string)
  ), class = "edetect_chart")
}

empty_trajectory <- function() {
  tibble::tibble(t = integer(), x = numeric(), n = numeric(), log_evalue = numeric(),
                 evidence = numeric(), evidence_cusum = numeric(), threshold = numeric(),
                 change_estimate = integer(), alarm = logical())
}

#' Update an e-detector with new observations
#'
#' Feeds one or more Phase II observations, in time order, to the detector. The
#' first time the statistic reaches the threshold an alarm is recorded; the
#' detector does not accept further observations after that (see
#' [edetect_restart()]).
#'
#' @param state An `edetect_chart` from [edetect_init()].
#' @param x Numeric vector of observations (values for the `"bounded"` and
#'   `"subgaussian"` classes; counts for `"bernoulli"` and `"poisson"`).
#' @param n Subgroup sizes (`"bernoulli"`) or exposures (`"poisson"`), one per
#'   observation or a single value. Ignored by the other classes.
#' @return The updated `edetect_chart`.
#' @export
#' @examples
#' design <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1)
#' state <- edetect_init(design)
#' set.seed(1)
#' state <- edetect_update(state, c(rnorm(30), rnorm(30, mean = 1.5)))
#' edetect_alarm(state)
edetect_update <- function(state, x, n = NULL) {
  assert_chart(state)
  if (!is.na(state$alarm_time)) {
    cli::cli_abort(c("This detector raised an alarm at t = {state$alarm_time} and accepts no further observations.",
                     "i" = "Use {.fn edetect_restart} to monitor again with the same design."))
  }
  obs <- check_observations(x, state$design, n)
  d <- state$design
  log_w <- log(d$weights); log_arl <- log(d$arl)
  k <- length(d$lambda)
  nobs <- length(obs$x)
  tr_log_e <- tr_ev <- tr_ev_cu <- numeric(nobs); tr_ce <- integer(nobs); tr_alarm <- logical(nobs)
  log_sr <- state$log_sr; log_cu <- state$log_cu; restart <- state$restart
  t <- state$t
  alarm_time <- NA_integer_; alarm_evidence <- NA_real_; change_estimate <- NA_integer_
  for (i in seq_len(nobs)) {
    t <- t + 1L
    le <- log_evalues(d, obs$x[i], obs$n[i])[, 1]
    reset <- log_cu <= 0
    restart[reset] <- t
    log_sr <- log_sum_exp(0, log_sr) + le
    log_cu <- pmax(0, log_cu) + le
    ev_sr <- exp(log_mix(log_w, log_sr)); ev_cu <- exp(log_mix(log_w, log_cu))
    ev <- if (d$type == "sr") ev_sr else ev_cu
    ce <- restart[which.max(log_w + log_cu)]
    alarm <- is.finite(ev) && ev >= d$arl || is.infinite(ev)
    tr_log_e[i] <- log_mix(log_w, le); tr_ev[i] <- ev; tr_ev_cu[i] <- ev_cu
    tr_ce[i] <- ce; tr_alarm[i] <- alarm
    if (alarm) {
      alarm_time <- t; alarm_evidence <- ev; change_estimate <- ce
      if (i < nobs) {
        cli::cli_warn("Alarm at t = {t}; {nobs - i} later observation{?s} {?was/were} not consumed.")
      }
      break
    }
  }
  used <- seq_len(if (is.na(alarm_time)) nobs else t - state$t)
  rows <- tibble::tibble(t = state$t + used, x = obs$x[used], n = obs$n[used],
                         log_evalue = tr_log_e[used], evidence = tr_ev[used],
                         evidence_cusum = tr_ev_cu[used], threshold = d$arl,
                         change_estimate = tr_ce[used], alarm = tr_alarm[used])
  state$trajectory <- rbind(state$trajectory, rows)
  state$log_sr <- log_sr; state$log_cu <- log_cu; state$restart <- restart; state$t <- t
  state$alarm_time <- alarm_time; state$alarm_evidence <- alarm_evidence
  state$change_estimate <- change_estimate
  state
}

#' Restart a detector after an alarm
#'
#' Returns a fresh detector with the same design. The history of the previous
#' run is kept in the `runs` element of the new object, so that a report can
#' list every alarm.
#'
#' @param state An `edetect_chart` that raised an alarm.
#' @return A new `edetect_chart`.
#' @export
#' @examples
#' design <- edetect_design(arl = 20, class = "subgaussian", center = 0, sigma = 1)
#' state <- suppressWarnings(edetect_update(edetect_init(design), c(rnorm(5), rnorm(30, 3))))
#' edetect_alarm(state)$alarm
#' state <- edetect_restart(state)
#' edetect_alarm(state)$alarm
edetect_restart <- function(state) {
  assert_chart(state)
  new <- edetect_init(state$design)
  previous <- c(state$runs, list(list(trajectory = state$trajectory, alarm_time = state$alarm_time,
                                      change_estimate = state$change_estimate)))
  new$runs <- previous
  new$t_offset <- state$t + (state$t_offset %||% 0L)
  new
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' The alarm status of a detector
#'
#' @param state An `edetect_chart`.
#' @return A one-row tibble with `alarm` (logical), `alarm_time`, `evidence`
#'   at the alarm (or the current evidence), `threshold`, `change_estimate`
#'   (the start of the e-process that carries most of the current evidence)
#'   and `n_observed`.
#' @export
#' @examples
#' design <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1)
#' state <- edetect_update(edetect_init(design), rnorm(10))
#' edetect_alarm(state)
edetect_alarm <- function(state) {
  assert_chart(state)
  tr <- state$trajectory
  current <- if (nrow(tr)) tr$evidence[nrow(tr)] else 0
  tibble::tibble(
    alarm = !is.na(state$alarm_time), alarm_time = state$alarm_time,
    evidence = if (!is.na(state$alarm_time)) state$alarm_evidence else current,
    threshold = state$design$arl,
    change_estimate = if (nrow(tr)) tr$change_estimate[nrow(tr)] else NA_integer_,
    n_observed = state$t)
}

#' The full report of a detector
#'
#' Everything a reader needs to audit an alarm or its absence: what was assumed
#' (class, centre and its source, bounds or scale, direction), how the detector
#' was built (type, e-value family, mixture), what was observed, the outcome and
#' the software versions.
#'
#' @param state An `edetect_chart`.
#' @return A list of class `edetect_report`.
#' @export
#' @examples
#' design <- edetect_design(arl = 100, class = "bernoulli", center = 0.05)
#' state <- edetect_update(edetect_init(design), x = c(2, 3, 1, 4), n = 50)
#' edetect_report(state)
edetect_report <- function(state) {
  assert_chart(state)
  d <- state$design
  al <- edetect_alarm(state)
  assumptions <- c(
    switch(d$class,
      bounded = sprintf("Pre-change observations lie in [%s, %s] with mean %s %s (nothing else assumed).",
                        format(d$bounds[1]), format(d$bounds[2]), direction_word(d$direction), format(signif(d$center, 4))),
      subgaussian = sprintf("Pre-change observations have mean %s %s and sub-Gaussian tails with scale %s.",
                            direction_word(d$direction), format(signif(d$center, 4)), format(signif(d$sigma, 4))),
      bernoulli = sprintf("Pre-change trials have conditional success probability %s %s; other dependence within a subgroup is allowed.",
                          direction_word(d$direction), format(signif(d$center, 4))),
      poisson = sprintf("Pre-change counts are sub-Poisson with rate %s %s per unit exposure (no overdispersion).",
                        direction_word(d$direction), format(signif(d$center, 4)))),
    if (d$center_source == "phase1") sprintf("The centre%s was estimated from %d Phase I observations and is treated as known.",
                                             if (d$class == "subgaussian") " and the scale" else "", d$n_phase1)
    else "The centre was declared by the user.",
    "Observations arrive in time order and none was dropped or imputed."
  )
  structure(list(
    class = d$class, center = d$center, center_source = d$center_source, n_phase1 = d$n_phase1,
    bounds = d$bounds, sigma = d$sigma, direction = d$direction, type = d$type,
    evalue = d$evalue, delta = d$delta, lambda = d$lambda, weights = d$weights,
    arl = d$arl, alpha = d$alpha, n_observed = state$t,
    alarm = al$alarm, alarm_time = al$alarm_time, evidence = al$evidence,
    change_estimate = al$change_estimate,
    max_evidence = if (nrow(state$trajectory)) max(state$trajectory$evidence) else 0,
    n_runs_before = length(state$runs %||% list()),
    assumptions = assumptions, versions = state$versions, created = d$created
  ), class = "edetect_report")
}

direction_word <- function(direction) {
  switch(direction, up = "at most", down = "at least", both = "equal to")
}

#' @export
print.edetect_report <- function(x, ...) {
  cli::cli_h1("e-detector report")
  cli::cli_text("Class {.val {x$class}}, centre {signif(x$center, 4)} ({x$center_source}); direction {.val {x$direction}}; type {.val {x$type}}; target ARL {x$arl}.")
  cli::cli_text("Observations: {x$n_observed}. Maximum evidence {signif(x$max_evidence, 3)} against a threshold of {x$arl}.")
  if (x$alarm) {
    cli::cli_alert_danger("Alarm at t = {x$alarm_time} (evidence {signif(x$evidence, 3)}); estimated change at t = {x$change_estimate}.")
  } else {
    cli::cli_alert_success("No alarm.")
  }
  cli::cli_h2("Assumptions")
  cli::cli_ul(x$assumptions)
  cli::cli_text("{.emph edetect {x$versions$edetect}, {x$versions$R}}")
  invisible(x)
}
