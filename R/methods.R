# S3 methods for edetect_chart -------------------------------------------------

#' @export
print.edetect_chart <- function(x, ...) {
  d <- x$design
  al <- edetect_alarm(x)
  cli::cli_h1("e-detector chart")
  cli::cli_text("{.val {d$class}} class, centre {signif(d$center, 4)} ({d$center_source}), direction {.val {d$direction}}, type {.val {d$type}}, target ARL {d$arl}")
  if (x$t == 0L) {
    cli::cli_text("No observations yet.")
  } else if (al$alarm) {
    cli::cli_alert_danger("Alarm at t = {al$alarm_time} (evidence {signif(al$evidence, 3)} >= {d$arl}); estimated change at t = {al$change_estimate}.")
  } else {
    cli::cli_alert_success("{x$t} observation{?s}, no alarm (evidence {signif(al$evidence, 3)} < {d$arl}).")
  }
  invisible(x)
}

#' @export
summary.edetect_chart <- function(object, ...) edetect_report(object)

#' Tidy the trajectory of a detector
#'
#' One row per observation with the mixed log e-value, the detector evidence
#' (SR or CUSUM type, as designed), the CUSUM-type evidence, the threshold, the
#' running change-point estimate and the alarm flag.
#'
#' @param x An `edetect_chart`.
#' @param ... Unused.
#' @return A tibble with columns `t`, `x`, `n`, `log_evalue`, `evidence`,
#'   `evidence_cusum`, `threshold`, `change_estimate`, `alarm`.
#' @exportS3Method generics::tidy edetect_chart
#' @examples
#' chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#' tidy(chart)
tidy.edetect_chart <- function(x, ...) {
  assert_chart(x)
  x$trajectory
}

#' Glance at a detector
#'
#' @param x An `edetect_chart`.
#' @param ... Unused.
#' @return A one-row tibble: `class`, `center`, `center_source`, `direction`,
#'   `type`, `arl`, `n_observed`, `alarm`, `alarm_time`, `evidence`,
#'   `change_estimate`.
#' @exportS3Method generics::glance edetect_chart
#' @examples
#' chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#' glance(chart)
glance.edetect_chart <- function(x, ...) {
  assert_chart(x)
  d <- x$design; al <- edetect_alarm(x)
  tibble::tibble(class = d$class, center = d$center, center_source = d$center_source,
                 direction = d$direction, type = d$type, arl = d$arl, n_observed = x$t,
                 alarm = al$alarm, alarm_time = al$alarm_time, evidence = al$evidence,
                 change_estimate = al$change_estimate)
}

#' Plot a detector
#'
#' Two panels: the observations (as values, proportions or rates per unit
#' exposure) with the pre-change centre, and the evidence of the detector on
#' the log10 scale with the alarm threshold and, if any, the alarm time and the
#' estimated change point.
#'
#' @param object An `edetect_chart`.
#' @param ... Unused.
#' @return A ggplot.
#' @exportS3Method ggplot2::autoplot edetect_chart
#' @examples
#' chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11, 10), center = 3, arl = 100)
#' autoplot(chart)
autoplot.edetect_chart <- function(object, ...) {
  assert_chart(object)
  tr <- object$trajectory
  if (nrow(tr) == 0L) cli::cli_abort("Nothing to plot: the detector has no observations.")
  d <- object$design
  value <- if (d$class %in% c("bernoulli", "poisson")) tr$x / tr$n else tr$x
  ylab_obs <- switch(d$class, bernoulli = "proportion", poisson = "rate per unit exposure", "observation")
  lv <- c(ylab_obs, "log10 evidence")
  long <- rbind(
    tibble::tibble(t = tr$t, panel = factor(ylab_obs, lv), value = value),
    tibble::tibble(t = tr$t, panel = factor("log10 evidence", lv), value = log10(pmax(tr$evidence, 1e-12))))
  ref <- tibble::tibble(panel = factor(lv, lv), yintercept = c(d$center, log10(d$arl)),
                        what = c("centre", "threshold"))
  p <- ggplot2::ggplot(long, ggplot2::aes(x = .data$t, y = .data$value)) +
    ggplot2::geom_hline(data = ref, ggplot2::aes(yintercept = .data$yintercept, linetype = .data$what), colour = "grey40") +
    ggplot2::geom_line(colour = "#0054AD") +
    ggplot2::geom_point(colour = "#0054AD", size = 1) +
    ggplot2::facet_wrap(~ panel, ncol = 1, scales = "free_y") +
    ggplot2::labs(x = "time", y = NULL, linetype = NULL, colour = NULL) +
    ggplot2::theme_minimal() + ggplot2::theme(legend.position = "bottom")
  al <- edetect_alarm(object)
  if (al$alarm) {
    marks <- tibble::tibble(t = c(al$change_estimate, al$alarm_time), what = c("estimated change", "alarm"))
    p <- p + ggplot2::geom_vline(data = marks, ggplot2::aes(xintercept = .data$t, colour = .data$what), linetype = "dashed") +
      ggplot2::scale_colour_manual(values = c("estimated change" = "#E69F00", "alarm" = "#D55E00"))
  }
  p
}
