# Restart a detector after an alarm

Returns a fresh detector with the same design. The history of the
previous run is kept in the `runs` element of the new object, so that a
report can list every alarm.

## Usage

``` r
edetect_restart(state)
```

## Arguments

- state:

  An `edetect_chart` that raised an alarm.

## Value

A new `edetect_chart`.

## Examples

``` r
design <- edetect_design(arl = 20, class = "subgaussian", center = 0, sigma = 1)
state <- suppressWarnings(edetect_update(edetect_init(design), c(rnorm(5), rnorm(30, 3))))
edetect_alarm(state)$alarm
#> [1] TRUE
state <- edetect_restart(state)
edetect_alarm(state)$alarm
#> [1] FALSE
```
