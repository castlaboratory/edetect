# u chart: nonconformities per unit of exposure

u chart: nonconformities per unit of exposure

## Usage

``` r
edetect_u(x, n, center = NULL, phase1 = NULL, ...)
```

## Arguments

- x:

  Counts per sample.

- n:

  Exposure (area of opportunity) of each sample.

- center:

  Pre-change rate per unit exposure; omit to estimate it from `phase1`.

- phase1:

  Optional Phase I data frame with columns `x` and `n`.

- ...:

  Passed to
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md)
  (`arl`, `direction`, `type`, `evalue`, `delta`, `weights`).

## Value

An `edetect_chart`.

## Examples

``` r
chart <- edetect_u(x = c(3, 2, 4, 3, 8, 9, 11), n = c(2, 2, 2, 2, 2, 2, 2), center = 1.5, arl = 100)
#> Warning: Alarm at t = 6; 1 later observation was not consumed.
edetect_alarm(chart)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE           6     499.       100               5          6
```
