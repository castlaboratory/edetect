# Update an e-detector with new observations

Feeds one or more Phase II observations, in time order, to the detector.
The first time the statistic reaches the threshold an alarm is recorded;
the detector does not accept further observations after that (see
[`edetect_restart()`](https://castlaboratory.github.io/edetect/reference/edetect_restart.md)).

## Usage

``` r
edetect_update(state, x, n = NULL)
```

## Arguments

- state:

  An `edetect_chart` from
  [`edetect_init()`](https://castlaboratory.github.io/edetect/reference/edetect_init.md).

- x:

  Numeric vector of observations (values for the `"bounded"` and
  `"subgaussian"` classes; counts for `"bernoulli"` and `"poisson"`).

- n:

  Subgroup sizes (`"bernoulli"`) or exposures (`"poisson"`), one per
  observation or a single value. Ignored by the other classes.

## Value

The updated `edetect_chart`.

## Examples

``` r
design <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1)
state <- edetect_init(design)
set.seed(1)
state <- edetect_update(state, c(rnorm(30), rnorm(30, mean = 1.5)))
#> Warning: Alarm at t = 33; 27 later observations were not consumed.
edetect_alarm(state)
#> # A tibble: 1 × 6
#>   alarm alarm_time evidence threshold change_estimate n_observed
#>   <lgl>      <int>    <dbl>     <dbl>           <int>      <int>
#> 1 TRUE          33     329.       100              31         33
```
