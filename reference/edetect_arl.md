# Simulate run lengths of a design

Estimates the average run length to a false alarm (ARL, no change) or
the detection delay (with a change) of an e-detector design by Monte
Carlo. The recursion is vectorised across replications.

## Usage

``` r
edetect_arl(
  design,
  pre,
  post = NULL,
  change_at = 1L,
  n_rep = 200L,
  max_t = NULL
)
```

## Arguments

- design:

  An
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md).

- pre:

  A function `function(n)` returning `n` pre-change observations (for
  the `"bernoulli"` and `"poisson"` classes, a data frame with columns
  `x` and `n`).

- post:

  Optional function with the same signature for post-change
  observations. When supplied, the change happens at time `change_at`.

- change_at:

  Time of the first post-change observation.

- n_rep:

  Number of replications.

- max_t:

  Censoring time; runs that have not alarmed by `max_t` are reported as
  censored.

## Value

A list of class `edetect_runs` with `runs` (a tibble with one row per
replication: `run_length`, `alarm`, `delay` when there is a change,
`false_alarm`) and `summary` (a one-row tibble with the mean run length
or delay, its standard error, the censoring fraction and, with a change,
the false-alarm fraction before `change_at`).

## Examples

``` r
design <- edetect_design(arl = 50, class = "subgaussian", center = 0, sigma = 1)
set.seed(1)
edetect_arl(design, pre = function(n) rnorm(n), n_rep = 50, max_t = 2000)$summary
#> # A tibble: 1 × 6
#>   arl_estimate    se censored target_arl n_rep max_t
#>          <dbl> <dbl>    <dbl>      <dbl> <int> <int>
#> 1         100.  12.3        0         50    50  2000
edetect_arl(design, pre = function(n) rnorm(n), post = function(n) rnorm(n, 1),
            change_at = 20, n_rep = 50, max_t = 500)$summary
#> # A tibble: 1 × 7
#>   delay_mean    se false_alarm censored change_at n_rep max_t
#>        <dbl> <dbl>       <dbl>    <dbl>     <int> <int> <int>
#> 1       5.48 0.362        0.08        0        20    50   500
```
