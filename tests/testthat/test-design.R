test_that("a design records its class, centre source and mixture", {
  d <- edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
  expect_s3_class(d, "edetect_design")
  expect_equal(d$alpha, 1 / 370)
  expect_equal(d$center_source, "declared")
  expect_equal(sum(d$weights), 1)
  expect_true(all(d$lambda > 0))
  expect_true(all(d$delta > 0))
  expect_message(print(d), "bounded")
})

test_that("phase1 with phase1_beta = NULL sets the plug-in centre and scale", {
  set.seed(1)
  x <- rnorm(50, 10, 2)
  d <- edetect_design(class = "subgaussian", phase1 = x, phase1_beta = NULL)
  expect_equal(d$center, mean(x))
  expect_equal(d$sigma, sd(x))
  expect_equal(d$center_source, "phase1")
  expect_equal(d$sigma_source, "phase1")
  expect_equal(d$n_phase1, 50L)
  dp <- edetect_design(class = "bernoulli", phase1 = data.frame(x = c(2, 3), n = c(100, 100)), phase1_beta = NULL)
  expect_equal(dp$center, 0.025)
  expect_error(edetect_design(class = "bernoulli", phase1 = c(1, 2)), "data frame")
  expect_error(edetect_design(class = "subgaussian", center = 0), "sigma")
  expect_error(edetect_design(class = "bounded", center = 0.5), "bounds")
  expect_error(edetect_design(class = "bounded", bounds = c(0, 1)), "center")
  expect_error(edetect_design(class = "bounded", bounds = c(0, 1), phase1 = c(0.5, 1.2)), "outside")
})

test_that("by default the centre is the Chernoff bound of the Phase I sample", {
  lvl <- log(1 / 0.1)
  # bernoulli: total * kl(p_hat, upper) = log(1 / beta)
  dp <- edetect_design(class = "bernoulli", phase1 = data.frame(x = c(2, 3), n = c(100, 100)))
  expect_equal(dp$center_source, "phase1_bound")
  expect_equal(200 * kl_bernoulli(0.025, dp$center), lvl, tolerance = 1e-8)
  expect_true(all(dp$center_k == dp$center))
  # poisson, lower bound for a decrease
  dd <- edetect_design(class = "poisson", phase1 = data.frame(x = c(10, 14), n = c(2, 2)), direction = "down")
  expect_lt(dd$center, 6)
  expect_equal(4 * kl_poisson(6, dd$center), lvl, tolerance = 1e-8)
  # subgaussian with declared scale
  ds <- edetect_design(class = "subgaussian", phase1 = c(-1, 1, 0, 0), sigma = 2)
  expect_equal(ds$center, 2 * sqrt(2 * lvl / 4))
  expect_equal(ds$sigma_source, "declared")
  # bounded on [a, b] with Hoeffding e-values: Chernoff bound on the rescaled scale
  db <- edetect_design(class = "bounded", bounds = c(10, 20), phase1 = c(12, 14, 13, 15, 11), evalue = "hoeffding")
  expect_equal(5 * kl_bernoulli(0.3, (db$center - 10) / 10), lvl, tolerance = 1e-8)
  # with betting e-values: the betting bound, rescaled, and its mirror for "down"
  y <- c(12, 14, 13, 15, 11, 13, 12, 14)
  du <- edetect_design(class = "bounded", bounds = c(10, 20), phase1 = y)
  expect_equal(du$center, 10 + 10 * betting_bound((y - 10) / 10, lvl, "upper"))
  dd2 <- edetect_design(class = "bounded", bounds = c(10, 20), phase1 = y, direction = "down")
  expect_equal(dd2$center, 10 + 10 * (1 - betting_bound(1 - (y - 10) / 10, lvl, "upper")))
  expect_true(du$center > mean(y) && dd2$center < mean(y))
  # a declared centre ignores phase1_beta
  expect_null(edetect_design(class = "bernoulli", center = 0.1)$phase1_beta)
})

test_that("direction 'both' bets increases against the upper and decreases against the lower bound", {
  d <- edetect_design(class = "bernoulli", phase1 = data.frame(x = 20, n = 1000), direction = "both")
  cb <- d$center_bounds
  expect_equal(d$center, 0.02)
  expect_true(all(d$center_k[d$lambda > 0] == cb[["upper"]]))
  expect_true(all(d$center_k[d$lambda < 0] == cb[["lower"]]))
  expect_equal(1000 * kl_bernoulli(0.02, cb[["upper"]]), log(2 / 0.1), tolerance = 1e-8)
  expect_message(print(d), "Phase I estimate")
})

test_that("the betting wealth is increasing in the candidate mean", {
  set.seed(3)
  y <- rbeta(40, 2, 5)
  u <- betting_bound(y, log(10), "upper")
  expect_gt(u, mean(y))
  expect_lt(u, 1)
  expect_equal(betting_bound(rep(1, 5), log(10), "upper"), 1)
})

test_that("a Phase I bound at the edge of the class is an error", {
  expect_error(edetect_design(class = "bounded", bounds = c(0, 1), phase1 = c(1, 1, 1)), "edge")
  expect_error(edetect_design(class = "bernoulli", phase1 = data.frame(x = 0, n = 50), direction = "down"), "edge")
  expect_error(edetect_design(class = "bernoulli", phase1 = data.frame(x = 1, n = 50), phase1_beta = 0.9), "phase1_beta")
})

test_that("the Phase I bound covers the in-control mean with probability 1 - beta", {
  skip_on_cran()
  set.seed(12)
  cover <- replicate(4000, {
    y <- rbeta(30, 2, 8)
    edetect_design(class = "bounded", bounds = c(0, 1), phase1 = y, phase1_beta = 0.1)$center >= 0.2
  })
  expect_gt(mean(cover), 0.9 - 3 * sqrt(0.09 / 4000))
})

test_that("directions mirror the bets and 'both' splits the weights", {
  up <- edetect_design(class = "bernoulli", center = 0.2, direction = "up")
  down <- edetect_design(class = "bernoulli", center = 0.2, direction = "down")
  both <- edetect_design(class = "bernoulli", center = 0.2, direction = "both")
  expect_true(all(up$lambda > 0)); expect_true(all(down$lambda < 0))
  expect_equal(length(both$lambda), length(up$lambda) + length(down$lambda))
  expect_equal(sum(both$weights[both$lambda > 0]), 0.5)
  expect_true(all(abs(down$delta) < 0.2))
})

test_that("user shifts and weights are honoured and validated", {
  d <- edetect_design(class = "subgaussian", center = 0, sigma = 2, delta = c(1, 4), weights = c(3, 1))
  expect_equal(d$lambda, c(1, 4) / 4)
  expect_equal(d$weights, c(0.75, 0.25))
  expect_error(edetect_design(class = "subgaussian", center = 0, sigma = 2, delta = -1), "positive")
  expect_error(edetect_design(class = "subgaussian", center = 0, sigma = 2, delta = 1, weights = c(1, 2)), "one weight per")
  expect_error(edetect_design(arl = 0.5, class = "subgaussian", center = 0, sigma = 1), "between")
  expect_error(edetect_design(class = "bounded", center = 1, bounds = c(0, 1), direction = "up"), "bound")
  expect_error(edetect_design(class = "poisson", center = 0, direction = "down"), "zero")
})

test_that("Phase I autocorrelation and the regime of the bound are recorded and reported", {
  set.seed(11)
  y <- as.numeric(stats::filter(runif(300, 0.3, 0.7) - 0.5, 0.6, method = "recursive")) * 0.1 + 0.5
  d <- edetect_design(arl = 100, class = "bounded", bounds = c(0, 1), phase1 = y)
  expect_gt(d$phase1_acf1, 0.4)
  expect_identical(d$bound_regime, "range")
  rep <- edetect_report(edetect_init(d))
  expect_true(any(grepl("autocorrelation", rep$phase1_checks)))
  expect_true(any(grepl("declared bounds", rep$phase1_checks)))
  z <- runif(200, 0.2, 0.8)
  d2 <- edetect_design(arl = 100, class = "bounded", bounds = c(0, 1), phase1 = z)
  expect_identical(d2$bound_regime, "variance")
  expect_false(any(grepl("Positive autocorrelation", edetect_report(edetect_init(d2))$phase1_checks)))
  d3 <- edetect_design(arl = 100, class = "bounded", bounds = c(0, 1), center = 0.5)
  expect_length(edetect_report(edetect_init(d3))$phase1_checks, 0)
})

test_that("edetect_batch_means averages blocks and drops the remainder", {
  expect_equal(edetect_batch_means(1:6, 2), c(1.5, 3.5, 5.5))
  expect_message(b <- edetect_batch_means(1:7, 3), "Dropped the last 1")
  expect_equal(b, c(2, 5))
  expect_error(edetect_batch_means(1:2, 3), "fewer than")
  expect_error(edetect_batch_means(c(1, NA), 1), "missing")
})
