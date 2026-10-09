test_that("the simulated ARL respects the guarantee", {
  skip_on_cran()
  set.seed(8)
  d <- edetect_design(arl = 20, class = "subgaussian", center = 0, sigma = 1, direction = "up")
  r <- edetect_arl(d, pre = function(n) rnorm(n), n_rep = 300, max_t = 2000)
  expect_s3_class(r, "edetect_runs")
  expect_equal(nrow(r$runs), 300L)
  # E[tau] >= 20 by construction; allow Monte Carlo error and censoring
  expect_true(r$summary$arl_estimate >= 20 - 3 * r$summary$se)
  expect_message(print(r), "run lengths")
})

test_that("a change is detected with a delay and false alarms are counted", {
  skip_on_cran()
  set.seed(9)
  d <- edetect_design(arl = 100, class = "bernoulli", center = 0.05, direction = "up")
  r <- edetect_arl(d, pre = function(n) data.frame(x = rbinom(n, 50, 0.05), n = 50),
                   post = function(n) data.frame(x = rbinom(n, 50, 0.20), n = 50),
                   change_at = 30, n_rep = 100, max_t = 300)
  expect_true(all(c("delay", "false_alarm") %in% names(r$runs)))
  expect_true(r$summary$delay_mean < 10)
  expect_true(r$summary$false_alarm < 0.5)
  expect_error(edetect_arl(d, pre = function(n) rbinom(n, 50, 0.05), n_rep = 5, max_t = 10), "data frame")
})

test_that("edetect_arl runs on a tiny problem (CRAN-safe)", {
  set.seed(10)
  d <- edetect_design(arl = 10, class = "subgaussian", center = 0, sigma = 1, direction = "up")
  r <- edetect_arl(d, pre = function(n) rnorm(n), n_rep = 10, max_t = 200)
  expect_equal(nrow(r$runs), 10L)
  expect_true(is.finite(r$summary$arl_estimate))
})
