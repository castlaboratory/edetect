# p chart: proportion of nonconforming units

p chart: proportion of nonconforming units

## Usage

``` r
edetect_p(x, n, center = NULL, phase1 = NULL, ...)
```

## Arguments

- x:

  Counts of nonconforming units per subgroup.

- n:

  Subgroup sizes (one per subgroup or a single value).

- center:

  Pre-change proportion; omit to estimate it from `phase1`.

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
chart <- edetect_p(x = c(1, 0, 2, 1, 3, 4, 5, 6), n = 100, center = 0.01, arl = 100)
#> Warning: Alarm at t = 7; 1 later observation was not consumed.
edetect_alarm(chart)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE           7     197.       100               5          7
```
