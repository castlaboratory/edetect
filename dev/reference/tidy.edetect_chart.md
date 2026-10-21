# Tidy the trajectory of a detector

One row per observation with the mixed log e-value, the detector
evidence (SR or CUSUM type, as designed), the CUSUM-type evidence, the
threshold, the running change-point estimate and the alarm flag.

## Usage

``` r
# S3 method for class 'edetect_chart'
tidy(x, ...)
```

## Arguments

- x:

  An `edetect_chart`.

- ...:

  Unused.

## Value

A tibble with columns `t`, `x`, `n`, `log_evalue`, `evidence`,
`evidence_cusum`, `threshold`, `change_estimate`, `alarm`.

## Examples

``` r
chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11), center = 3, arl = 100)
#> Warning: Alarm at t = 6; 1 later observation was not consumed.
tidy(chart)
#> # A tibble: 6 × 9
#>       t     x     n log_evalue evidence evidence_cusum threshold change_estimate
#>   <int> <dbl> <dbl>      <dbl>    <dbl>          <dbl>     <dbl>           <int>
#> 1     1     3     1     -0.546    0.579          0.579       100               1
#> 2     2     2     1     -0.902    0.728          0.406       100               2
#> 3     3     4     1     -0.133    1.66           0.875       100               3
#> 4     4     3     1     -0.546    1.84           0.633       100               3
#> 5     5     8     1      2.21    18.2            9.14        100               5
#> 6     6     9     1      2.96   420.           263.          100               5
#> # ℹ 1 more variable: alarm <lgl>
```
