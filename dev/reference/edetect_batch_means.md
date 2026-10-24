# Batch means of a series

Averages consecutive, non-overlapping blocks of `size` observations. The
pre-change classes of the package allow dependence only through a bound
on the conditional mean, which positive autocorrelation around the
centre violates. Monitoring batch means, the classical remedy, weakens
the autocorrelation; the run length is then counted in batches, so a
target of `arl` observations corresponds to a threshold of about
`arl / size` batches. Use the same `size` for Phase I and Phase II.

## Usage

``` r
edetect_batch_means(x, size)
```

## Arguments

- x:

  Numeric vector of observations in time order.

- size:

  Number of observations per batch (a positive integer).

## Value

A numeric vector of `floor(length(x) / size)` batch means. Trailing
observations that do not fill a batch are dropped with a message.

## Examples

``` r
x <- stats::filter(stats::runif(500, -0.5, 0.5), 0.5, method = "recursive")
xb <- edetect_batch_means(as.numeric(x) / 2 + 0.5, size = 5)
length(xb)
#> [1] 100
```
