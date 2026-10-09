# edetect

<!-- badges: start -->
[![R-CMD-check](https://github.com/castlaboratory/edetect/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/castlaboratory/edetect/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**Anytime-valid control charts with e-detectors.**

`edetect` answers one question: *how do I monitor a process for a change and
raise an alarm with a guaranteed false-alarm rate, without assuming a
parametric model for the process before or after the change?* It implements
**e-detectors** (Shin, Ramdas & Rinaldo, 2024): nonparametric, anytime-valid
analogues of the CUSUM and Shiryaev–Roberts charts, built from e-processes for
bounded or sub-psi observations, with a guaranteed **average run length** (ARL)
to a false alarm under every distribution in the declared pre-change class.

The package follows the Phase I / Phase II workflow of
[shewhartr](https://github.com/castlaboratory/shewhartr) and reuses the
confidence-sequence kernels of
[seqbench](https://CRAN.R-project.org/package=seqbench).

## Status

Pre-alpha. The API below is a design target, not yet implemented.

```r
design <- edetect_design(arl = 500, bounds = c(0, 1), type = "sr",
                         baseline = "betting", change = "mean")
state  <- edetect_init(design, phase1 = x_in_control)   # Phase I: declare the pre-change class
state  <- edetect_update(state, x_new)                   # Phase II: one or many observations
edetect_alarm(state)                                      # alarm time, evidence, reason
edetect_report(state)                                     # full auditable contract
autoplot(state); tidy(state); glance(state)
```

Attribute charts (`edetect_p()`, `edetect_c()`, `edetect_u()`) and a
regression chart (`edetect_regression()`) share the same engine.

## Installation

```r
# install.packages("pak")
pak::pak("castlaboratory/edetect")
```

## Related software

`edetect` is not a general change-point library. For classical charts
calibrated by simulation see [shewhartr](https://github.com/castlaboratory/shewhartr)
and [qcc](https://cran.r-project.org/package=qcc); for ARL computation of
CUSUM/EWMA charts see [spc](https://cran.r-project.org/package=spc); for
nonparametric sequential change-point models see
[cpm](https://cran.r-project.org/package=cpm). No package implementing
e-detectors was found on CRAN or PyPI (checked 2026-09-25 and 2026-10-10).

## License

GPL (>= 3). © CAST Lab, Universidade Federal de Pernambuco.
