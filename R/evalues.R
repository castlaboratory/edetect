# Log e-values -----------------------------------------------------------------
#
# For observations (x, n) and the vector of bets lambda of a design, return the
# matrix of log e-values (one row per bet, one column per observation). Every
# family satisfies E[e] <= 1 under the pre-change class for the sign of lambda
# that matches the direction (positive: mean at most the centre; negative: mean
# at least the centre). Each bet has its own centre (`center_k`), which differs
# between the two sides when the centre comes from a Phase I bound.

log_evalues <- function(design, x, n = 1) {
  lam <- design$lambda
  c0 <- design$center_k %||% design$center
  if (length(n) == 1L) n <- rep(n, length(x))
  switch(design$class,
    bounded = {
      a <- design$bounds[1]; b <- design$bounds[2]
      z <- (x - a) / (b - a); m0 <- (c0 - a) / (b - a)
      if (design$evalue == "betting") {
        log1p(outer(lam, z) - lam * m0)
      } else {
        outer(lam, z) - log(1 - m0 + m0 * exp(lam))
      }
    },
    subgaussian = outer(lam, x) - lam * c0 - lam^2 * design$sigma^2 / 2,
    bernoulli = outer(lam, x) - outer(log(1 - c0 + c0 * exp(lam)), n),
    poisson = outer(lam, x) - outer(c0 * (exp(lam) - 1), n)
  )
}

# log(exp(a) + exp(b)) elementwise, with a possibly a scalar and b a vector or
# matrix; -Inf inputs are handled.
log_sum_exp <- function(a, b) {
  m <- pmax(a, b)
  out <- m + log(exp(a - m) + exp(b - m))
  out[is.infinite(m) & m < 0] <- -Inf
  out
}

# log of the weighted mixture sum(w_k exp(log_m_k)); log_m may be a matrix with
# one column per stream. The column maxima are taken row by row with pmax, which
# is much faster than apply() when there are many streams.
log_mix <- function(log_w, log_m) {
  v <- log_w + log_m
  if (is.matrix(v)) {
    m <- v[1, ]
    for (i in seq_len(nrow(v))[-1]) m <- pmax(m, v[i, ])
    out <- m + log(colSums(exp(v - rep(m, each = nrow(v)))))
    out[is.infinite(m) & m < 0] <- -Inf
    return(out)
  }
  m <- max(v)
  if (is.infinite(m) && m < 0) return(-Inf)
  m + log(sum(exp(v - m)))
}
