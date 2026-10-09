# Individual-observation chart for bounded data

Individual-observation chart for bounded data

## Usage

``` r
edetect_x(x, bounds, center = NULL, phase1 = NULL, ...)
```

## Arguments

- x:

  Phase II observations.

- bounds:

  Known bounds of the observations.

- center:

  Pre-change mean; omit to estimate it from `phase1`.

- phase1:

  Optional Phase I observations.

- ...:

  Passed to
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md)
  (`arl`, `direction`, `type`, `evalue`, `delta`, `weights`).

## Value

An `edetect_chart`.

## Examples

``` r
set.seed(2)
x <- c(runif(40, 0.3, 0.7), runif(40, 0.5, 0.9))
chart <- edetect_x(x, bounds = c(0, 1), center = 0.5, arl = 200)
#> Warning: Alarm at t = 50; 30 later observations were not consumed.
edetect_alarm(chart)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE          50     271.       200              33         50
```
