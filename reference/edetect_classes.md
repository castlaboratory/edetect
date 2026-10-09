# Pre-change classes

The classes of pre-change distributions for which `edetect` builds
e-values. Each class is a statement about the observations *before* a
change; the average run length guarantee holds for every distribution in
the class.

## Usage

``` r
edetect_classes()
```

## Value

A character vector of class names.

## Details

- `"bounded"`: observations in known bounds `[a, b]` with mean at most
  (direction `"up"`), at least (`"down"`) or equal to (`"both"`)
  `center`. Nothing else is assumed. E-values: `"betting"` (tight,
  default) or `"hoeffding"` (sub-Bernoulli).

- `"subgaussian"`: observations with mean `center` and sub-Gaussian
  tails with declared scale `sigma`. Gaussian data with standard
  deviation `sigma` is the boundary case; heavier tails violate the
  class.

- `"bernoulli"`: counts of successes in subgroups of size `n`, each
  trial with success probability at most/at least/equal to `center`; any
  dependence within a subgroup is allowed. This is the p chart.

- `"poisson"`: counts with exposure `n` whose moment generating function
  is at most that of a Poisson with rate `center` per unit exposure
  (Poisson and underdispersed counts; overdispersed counts violate the
  class). These are the c (`n = 1`) and u charts.

## Examples

``` r
edetect_classes()
#> [1] "bounded"     "subgaussian" "bernoulli"   "poisson"    
```
