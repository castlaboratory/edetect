#' Batch means of a series
#'
#' Averages consecutive, non-overlapping blocks of `size` observations. The
#' pre-change classes of the package allow dependence only through a bound on
#' the conditional mean, which positive autocorrelation around the centre
#' violates. Monitoring batch means, the classical remedy, weakens the
#' autocorrelation; the run length is then counted in batches, so a target of
#' `arl` observations corresponds to a threshold of about `arl / size` batches.
#' Use the same `size` for Phase I and Phase II.
#'
#' @param x Numeric vector of observations in time order.
#' @param size Number of observations per batch (a positive integer).
#' @return A numeric vector of `floor(length(x) / size)` batch means. Trailing
#'   observations that do not fill a batch are dropped with a message.
#' @examples
#' x <- stats::filter(stats::runif(500, -0.5, 0.5), 0.5, method = "recursive")
#' xb <- edetect_batch_means(as.numeric(x) / 2 + 0.5, size = 5)
#' length(xb)
#' @export
edetect_batch_means <- function(x, size) {
  if (!is.numeric(x) || anyNA(x)) cli::cli_abort("{.arg x} must be a numeric vector without missing values.")
  size <- check_count(size, "size")
  nb <- length(x) %/% size
  if (nb < 1L) cli::cli_abort("{.arg x} has fewer than {.arg size} = {size} observations.")
  left <- length(x) - nb * size
  if (left > 0L) cli::cli_inform("Dropped the last {left} observation{?s}, which do{?es/} not fill a batch.")
  colMeans(matrix(x[seq_len(nb * size)], nrow = size))
}
