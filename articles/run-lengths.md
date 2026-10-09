# Run lengths and detection delays

``` r

library(edetect)
```

Two numbers describe a chart: the **average run length to a false
alarm** (ARL), which the e-detector guarantees to be at least the target
for every pre-change distribution in the class, and the **detection
delay** after a change, which depends on the size of the change and on
the mixture of shifts the detector bets on.
[`edetect_arl()`](https://castlaboratory.github.io/edetect/reference/edetect_arl.md)
estimates both by Monte Carlo, running the recursion on many streams at
once.

## Checking the guarantee

A sub-Gaussian design with target ARL 100 and Gaussian pre-change data.
The estimate must be at least 100; it is usually well above, because the
guarantee is an inequality and the e-values are conservative.

``` r

design <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1, direction = "up")
set.seed(1)
no_change <- edetect_arl(design, pre = function(n) rnorm(n), n_rep = 100, max_t = 3000)
no_change$summary
#> # A tibble: 1 × 6
#>   arl_estimate    se censored target_arl n_rep max_t
#>          <dbl> <dbl>    <dbl>      <dbl> <int> <int>
#> 1         190.  17.1        0        100   100  3000
```

The guarantee holds for every distribution in the class, not only the
Gaussian one. A bounded design on \[0, 1\] with centre 0.5 is checked
here against three pre-change distributions with that mean: uniform, a
symmetric Beta and a two-point distribution at the bounds.

``` r

design_b <- edetect_design(arl = 100, class = "bounded", center = 0.5, bounds = c(0, 1), direction = "up")
set.seed(2)
generators <- list(
  uniform = function(n) runif(n),
  beta = function(n) rbeta(n, 4, 4),
  two_point = function(n) rbinom(n, 1, 0.5))
sapply(generators, function(g) edetect_arl(design_b, pre = g, n_rep = 60, max_t = 3000)$summary$arl_estimate)
#>   uniform      beta two_point 
#> 107.26667  99.83333 109.90000
```

## Measuring the delay

With a change at time 50 from mean 0 to mean 1, the delay is the number
of observations from the change to the alarm. Runs that alarm before the
change are counted as false alarms and excluded from the delay.

``` r

set.seed(3)
shift <- edetect_arl(design, pre = function(n) rnorm(n), post = function(n) rnorm(n, 1),
                     change_at = 50, n_rep = 100, max_t = 500)
shift$summary
#> # A tibble: 1 × 7
#>   delay_mean    se false_alarm censored change_at n_rep max_t
#>        <dbl> <dbl>       <dbl>    <dbl>     <int> <int> <int>
#> 1       6.82 0.390         0.2        0        50   100   500
```

The delay grows as the shift shrinks. A design whose mixture
concentrates on small shifts detects them sooner and pays for it on
large ones; the default grid spans both.

``` r

set.seed(4)
delays <- sapply(c(0.5, 1, 2), function(mu) {
  edetect_arl(design, pre = function(n) rnorm(n), post = function(n) rnorm(n, mu),
              change_at = 50, n_rep = 60, max_t = 800)$summary$delay_mean
})
data.frame(shift = c(0.5, 1, 2), delay = round(delays, 1))
#>   shift delay
#> 1   0.5  18.1
#> 2   1.0   7.0
#> 3   2.0   2.9
```

## Shiryaev–Roberts versus CUSUM type

Both types are e-detectors with the same guarantee. The Shiryaev–Roberts
type sums the e-processes started at every time; the CUSUM type keeps
the largest. Their delays are close; the CUSUM type is slightly faster
for changes early in the stream and the Shiryaev–Roberts type for
changes after a long stable period.

``` r

set.seed(5)
types <- sapply(c("sr", "cusum"), function(type) {
  d <- edetect_design(arl = 100, class = "subgaussian", center = 0, sigma = 1, direction = "up", type = type)
  edetect_arl(d, pre = function(n) rnorm(n), post = function(n) rnorm(n, 1),
              change_at = 50, n_rep = 60, max_t = 500)$summary$delay_mean
})
round(types, 1)
#>    sr cusum 
#>   6.4   8.9
```

## Bounded data: betting versus sub-Bernoulli e-values

On bounded data two e-value families are available. The betting e-value
`1 + lambda (x - centre)` is tight for data concentrated inside the
bounds; the sub-Bernoulli exponential e-value is the Hoeffding bound and
is slower unless the data sit at the bounds.

``` r

set.seed(6)
families <- sapply(c("betting", "hoeffding"), function(ev) {
  d <- edetect_design(arl = 100, class = "bounded", center = 0.5, bounds = c(0, 1), direction = "up", evalue = ev)
  edetect_arl(d, pre = function(n) runif(n, 0.3, 0.7), post = function(n) runif(n, 0.45, 0.85),
              change_at = 50, n_rep = 60, max_t = 800)$summary$delay_mean
})
round(families, 1)
#>   betting hoeffding 
#>       7.6      34.6
```
