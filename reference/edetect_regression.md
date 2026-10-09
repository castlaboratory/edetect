# Regression chart: monitoring residuals of a Phase I model

Fits a linear model on Phase I data and monitors the Phase II residuals
`y - prediction` as a sub-Gaussian stream centred at zero, with the
residual standard deviation of the Phase I fit as the declared scale (or
a `sigma` supplied by the user). The fitted model is kept in the chart.

## Usage

``` r
edetect_regression(formula, phase1, phase2, sigma = NULL, ...)
```

## Arguments

- formula:

  Model formula.

- phase1:

  Phase I data frame.

- phase2:

  Phase II data frame with the same columns.

- sigma:

  Declared sub-Gaussian scale of the residuals; default the Phase I
  residual standard deviation.

- ...:

  Passed to
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md)
  (`arl`, `direction`, `type`, `evalue`, `delta`, `weights`).

## Value

An `edetect_chart` with an extra element `fit`.

## Examples

``` r
set.seed(3)
d1 <- data.frame(z = 1:60); d1$y <- 2 + 0.5 * d1$z + rnorm(60, sd = 0.3)
d2 <- data.frame(z = 61:100)
d2$y <- 2 + 0.5 * d2$z + rnorm(40, sd = 0.3) + c(rep(0, 20), rep(1, 20))
chart <- edetect_regression(y ~ z, phase1 = d1, phase2 = d2, arl = 200)
#> Warning: Alarm at t = 21; 19 later observations were not consumed.
edetect_alarm(chart)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE          21   32505.       200              21         21
```
