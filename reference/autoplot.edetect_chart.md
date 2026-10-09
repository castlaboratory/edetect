# Plot a detector

Two panels: the observations (as values, proportions or rates per unit
exposure) with the pre-change centre, and the evidence of the detector
on the log10 scale with the alarm threshold and, if any, the alarm time
and the estimated change point.

## Usage

``` r
# S3 method for class 'edetect_chart'
autoplot(object, ...)
```

## Arguments

- object:

  An `edetect_chart`.

- ...:

  Unused.

## Value

A ggplot.

## Examples

``` r
chart <- edetect_c(x = c(3, 2, 4, 3, 8, 9, 11, 10), center = 3, arl = 100)
#> Warning: Alarm at t = 6; 2 later observations were not consumed.
autoplot(chart)
```
