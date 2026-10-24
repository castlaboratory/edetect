# edetect (development version)

* A centre estimated from `phase1` is now, by default, a one-sided confidence
  bound for the in-control mean rather than the Phase I estimate
  (`phase1_beta = 0.1` in `edetect_design()` and the chart wrappers). With
  probability at least `1 - phase1_beta` over Phase I the average run length is
  then at least `arl`, and the probability of a false alarm by time `t` is at
  most `phase1_beta + t / arl`. The plug-in centre, for which no such statement
  holds, is available with `phase1_beta = NULL`. The bound inverts the e-value
  of the class: a betting bound for the `"bounded"` class with betting
  e-values (Waudby-Smith and Ramdas, 2024), Chernoff bounds otherwise. For
  `direction = "both"` increases are bet against the upper bound and decreases
  against the lower bound, each at level `1 - phase1_beta / 2`.
* Designs carry a centre per bet (`center_k`), the Phase I bounds
  (`center_bounds`) and the source of the sub-Gaussian scale (`sigma_source`);
  reports state the guarantee that applies to the design.
* `phase1` observations outside the declared `bounds` are an error.
* Reports list Phase I checks: the lag-one autocorrelation of a numeric Phase I
  sample, flagged when above 0.2 (positive autocorrelation around the centre is
  outside every class and shortens the time to a false alarm), and, for a
  betting bound, whether its width is set by the variance of the data or by the
  declared `bounds` (designs record `phase1_acf1` and `bound_regime`).
* New `edetect_batch_means()` averages consecutive blocks of observations, the
  classical remedy for autocorrelated data.
* `edetect_arl()` generates observations in blocks for the replications still
  running, so memory no longer grows with `max_t * n_rep`; the mixture of the
  log statistics no longer uses `apply()`. Results for a given seed differ from
  version 0.1.0.

# edetect 0.1.0

First CRAN release.

* E-detector engine: `edetect_design()` (pre-change classes `bounded`,
  `subgaussian`, `bernoulli`, `poisson`; directions up, down, both;
  Shiryaev-Roberts and CUSUM types; mixture over post-change shifts mapped to the
  optimal bet of each class; optional Phase I estimation of the centre and scale,
  recorded as an assumption), `edetect_init()`, `edetect_update()`,
  `edetect_restart()`, `edetect_alarm()`, `edetect_report()`.
* Charts: `edetect_x()`, `edetect_p()`, `edetect_c()`, `edetect_u()`,
  `edetect_regression()`.
* S3 class `edetect_chart` with `print`, `summary`, `tidy`, `glance`, `autoplot`.
* `edetect_arl()`: Monte Carlo run lengths (ARL without a change, delay and
  false alarms with a change), vectorised across replications.
* Getting-started vignette.
