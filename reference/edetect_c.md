# c chart: counts of nonconformities per unit

c chart: counts of nonconformities per unit

## Usage

``` r
edetect_c(x, center = NULL, phase1 = NULL, ...)
```

## Arguments

- x:

  Counts per inspection unit.

- center:

  Pre-change mean count; omit to estimate it from `phase1`.

- phase1:

  Optional Phase I counts (a numeric vector, unit exposure).

- ...:

  Passed to
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md)
  (`arl`, `direction`, `type`, `evalue`, `delta`, `weights`).

## Value

An `edetect_chart`.

## Examples

``` r
chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#> Warning: Alarm at t = 6; 1 later observation was not consumed.
edetect_alarm(chart)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE           6     420.       100               5          6
```
