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
