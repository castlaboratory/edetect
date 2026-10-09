# The alarm status of a detector

The alarm status of a detector

## Usage

``` r
edetect_alarm(state)
```

## Arguments

- state:

  An `edetect_chart`.

## Value

A one-row tibble with `alarm` (logical), `alarm_time`, `evidence` at the
alarm (or the current evidence), `threshold`, `change_estimate` (the
start of the e-process that carries most of the current evidence) and
`n_observed`.

## Examples

``` r
design <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1)
state <- edetect_update(edetect_init(design), rnorm(10))
edetect_alarm(state)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 FALSE         NA     1.67       100              10         10
```
