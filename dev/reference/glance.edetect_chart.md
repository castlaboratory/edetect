# Glance at a detector

Glance at a detector

## Usage

``` r
# S3 method for class 'edetect_chart'
glance(x, ...)
```

## Arguments

- x:

  An `edetect_chart`.

- ...:

  Unused.

## Value

A one-row tibble: `class`, `center`, `center_source`, `direction`,
`type`, `arl`, `n_observed`, `alarm`, `alarm_time`, `evidence`,
`change_estimate`.

## Examples

``` r
chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#> Warning: Alarm at t = 6; 1 later observation was not consumed.
glance(chart)
#> # A tibble: 1 × 11
#>   class   center center_source direction type    arl n_observed alarm alarm_time
#>   <chr>    <dbl> <chr>         <chr>     <chr> <dbl>      <int> <lgl>      <int>
#> 1 poisson      3 declared      up        sr      100          6 TRUE           6
#> # ℹ 2 more variables: evidence <dbl>, change_estimate <int>
```
