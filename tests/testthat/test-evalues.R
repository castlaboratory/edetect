test_that("e-values have expectation at most one under the pre-change class", {
  skip_on_cran()
  set.seed(11)
  m <- 2e5
  check <- function(design, x, n = 1) {
    e <- exp(log_evalues(design, x, n))
    means <- rowMeans(e)
    se <- apply(e, 1, stats::sd) / sqrt(ncol(e))
    expect_true(all(means <= 1 + 3 * se + 1e-3), info = design$class)
  }
  # bounded, betting and hoeffding, both directions, at the centre (mean = centre)
  for (ev in c("betting", "hoeffding")) {
    d <- edetect_design(arl = 100, class = "bounded", center = 0.3, bounds = c(0, 1), direction = "both", evalue = ev)
    check(d, rbeta(m, 3, 7))                     # mean 0.3
    check(d, rbinom(m, 1, 0.3))                  # extreme points
  }
  # bounded, up, with a pre-change mean below the centre
  d <- edetect_design(arl = 100, class = "bounded", center = 0.5, bounds = c(0, 1), direction = "up")
  check(d, runif(m, 0, 0.8))
  # subgaussian
  d <- edetect_design(arl = 100, class = "subgaussian", center = 1, sigma = 2, direction = "both")
  check(d, rnorm(m, 1, 2))
  # bernoulli with subgroups
  d <- edetect_design(arl = 100, class = "bernoulli", center = 0.05, direction = "both")
  check(d, rbinom(m, 40, 0.05), n = 40)
  # poisson with exposure
  d <- edetect_design(arl = 100, class = "poisson", center = 2.5, direction = "both")
  check(d, rpois(m, 2.5 * 3), n = 3)
})

test_that("betting e-values are non-negative at the bounds for every bet", {
  for (center in c(0.1, 0.5, 0.9)) {
    d <- edetect_design(arl = 50, class = "bounded", center = center, bounds = c(0, 1), direction = "both")
    expect_true(all(is.finite(log_evalues(d, c(0, 1)))))
  }
})

test_that("log_sum_exp and log_mix handle -Inf", {
  expect_equal(log_sum_exp(0, -Inf), 0)
  expect_equal(log_sum_exp(0, c(-Inf, 0)), c(0, log(2)))
  expect_equal(log_mix(log(c(0.5, 0.5)), c(-Inf, -Inf)), -Inf)
  expect_equal(log_mix(log(c(0.5, 0.5)), c(0, 0)), 0)
  expect_equal(log_mix(log(c(0.5, 0.5)), matrix(c(0, 0, -Inf, -Inf), 2)), c(0, -Inf))
})
