# edetect 0.0.0.9000

* First implementation of the e-detector engine: `edetect_design()` (pre-change
  classes `bounded`, `subgaussian`, `bernoulli`, `poisson`; directions up, down,
  both; Shiryaev–Roberts and CUSUM types; mixture over post-change shifts;
  optional Phase I estimation of the centre and scale, recorded as an
  assumption), `edetect_init()`, `edetect_update()`, `edetect_restart()`,
  `edetect_alarm()`, `edetect_report()`.
* Charts: `edetect_x()`, `edetect_p()`, `edetect_c()`, `edetect_u()`,
  `edetect_regression()`.
* S3 class `edetect_chart` with `print`, `summary`, `tidy`, `glance`, `autoplot`.
* `edetect_arl()`: Monte Carlo run lengths (ARL without a change, delay and
  false alarms with a change), vectorised across replications.
* Getting-started vignette; pkgdown site; hex logo.
