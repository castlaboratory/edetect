# Changelog

## edetect 0.0.0.9000

- First implementation of the e-detector engine:
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md)
  (pre-change classes `bounded`, `subgaussian`, `bernoulli`, `poisson`;
  directions up, down, both; Shiryaev–Roberts and CUSUM types; mixture
  over post-change shifts; optional Phase I estimation of the centre and
  scale, recorded as an assumption),
  [`edetect_init()`](https://castlaboratory.github.io/edetect/reference/edetect_init.md),
  [`edetect_update()`](https://castlaboratory.github.io/edetect/reference/edetect_update.md),
  [`edetect_restart()`](https://castlaboratory.github.io/edetect/reference/edetect_restart.md),
  [`edetect_alarm()`](https://castlaboratory.github.io/edetect/reference/edetect_alarm.md),
  [`edetect_report()`](https://castlaboratory.github.io/edetect/reference/edetect_report.md).
- Charts:
  [`edetect_x()`](https://castlaboratory.github.io/edetect/reference/edetect_x.md),
  [`edetect_p()`](https://castlaboratory.github.io/edetect/reference/edetect_p.md),
  [`edetect_c()`](https://castlaboratory.github.io/edetect/reference/edetect_c.md),
  [`edetect_u()`](https://castlaboratory.github.io/edetect/reference/edetect_u.md),
  [`edetect_regression()`](https://castlaboratory.github.io/edetect/reference/edetect_regression.md).
- S3 class `edetect_chart` with `print`, `summary`, `tidy`, `glance`,
  `autoplot`.
- [`edetect_arl()`](https://castlaboratory.github.io/edetect/reference/edetect_arl.md):
  Monte Carlo run lengths (ARL without a change, delay and false alarms
  with a change), vectorised across replications.
- Getting-started vignette; pkgdown site; hex logo.
