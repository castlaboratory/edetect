brute_force <- function(le, type) {
  # le: vector of log e-values for a single bet; SR = sum over starts of the
  # product, CUSUM = max over starts of the product.
  t <- length(le)
  vapply(seq_len(t), function(s) {
    prods <- vapply(seq_len(s), function(j) exp(sum(le[j:s])), numeric(1))
    if (type == "sr") sum(prods) else max(prods)
  }, numeric(1))
}

test_that("the recursions reproduce the brute-force SR and CUSUM detectors", {
  set.seed(5)
  x <- rnorm(25, 0.3)
  for (type in c("sr", "cusum")) {
    d <- edetect_design(arl = 1e6, class = "subgaussian", center = 0, sigma = 1, delta = 0.8, type = type)
    st <- edetect_update(edetect_init(d), x)
    le <- as.numeric(log_evalues(d, x))
    expect_equal(tidy(st)$evidence, brute_force(le, type), tolerance = 1e-10)
  }
})

test_that("the mixture over bets is the weighted average of per-bet SR detectors", {
  set.seed(6)
  x <- runif(30, 0.2, 0.9)
  d <- edetect_design(arl = 1e6, class = "bounded", center = 0.5, bounds = c(0, 1), delta = c(0.1, 0.3), weights = c(1, 3))
  st <- edetect_update(edetect_init(d), x)
  le <- log_evalues(d, x)
  per_bet <- rbind(brute_force(le[1, ], "sr"), brute_force(le[2, ], "sr"))
  expect_equal(tidy(st)$evidence, as.numeric(c(0.25, 0.75) %*% per_bet), tolerance = 1e-10)
})

test_that("an alarm stops the detector, warns about unconsumed data and can be restarted", {
  d <- edetect_design(arl = 20, class = "subgaussian", center = 0, sigma = 1, direction = "up")
  set.seed(7)
  x <- c(rnorm(10), rnorm(40, 3))
  expect_warning(st <- edetect_update(edetect_init(d), x), "not consumed")
  al <- edetect_alarm(st)
  expect_true(al$alarm)
  expect_true(al$alarm_time > 10 && al$alarm_time < 25)
  expect_true(al$evidence >= 20)
  expect_true(al$change_estimate >= 1 && al$change_estimate <= al$alarm_time)
  expect_error(edetect_update(st, 1), "no further observations")
  st2 <- edetect_restart(st)
  expect_equal(st2$t, 0L)
  expect_length(st2$runs, 1L)
  expect_false(edetect_alarm(st2)$alarm)
})

test_that("invalid input is refused, never fixed", {
  d <- edetect_design(arl = 100, class = "bounded", center = 0.5, bounds = c(0, 1))
  st <- edetect_init(d)
  expect_error(edetect_update(st, c(0.2, NA)), "missing")
  expect_error(edetect_update(st, c(0.2, 1.4)), "outside the declared bounds")
  expect_error(edetect_update(st, 0.2, n = 3), "only used by")
  dp <- edetect_design(arl = 100, class = "bernoulli", center = 0.1)
  expect_error(edetect_update(edetect_init(dp), 3), "required")
  expect_error(edetect_update(edetect_init(dp), 7, n = 5), "cannot exceed")
  expect_error(edetect_update(edetect_init(dp), -1, n = 5), "non-negative")
  expect_error(edetect_update("x", 1), "edetect_chart")
})

test_that("the report and glance carry the assumptions and the outcome", {
  d <- edetect_design(arl = 100, class = "poisson", phase1 = data.frame(x = c(3, 2, 4, 3), n = 1))
  st <- edetect_update(edetect_init(d), c(3, 2, 5), n = 1)
  r <- edetect_report(st)
  expect_s3_class(r, "edetect_report")
  expect_equal(r$center_source, "phase1")
  expect_equal(r$n_phase1, 4L)
  expect_false(r$alarm)
  expect_match(r$assumptions[1], "sub-Poisson")
  g <- glance(st)
  expect_equal(nrow(g), 1L)
  expect_equal(g$n_observed, 3L)
  expect_message(print(st), "no alarm")
  expect_message(print(r), "No alarm")
})
