# Design an e-detector

Fixes, before any Phase II observation is seen, everything the detector
needs: the pre-change class and its parameters, the direction of the
change to detect, the detector type (Shiryaev–Roberts or CUSUM), the
family of e-values and the mixture over post-change alternatives, and
the target average run length (ARL) to a false alarm.

## Usage

``` r
edetect_design(
  arl = 370,
  class = edetect_classes(),
  center = NULL,
  bounds = NULL,
  sigma = NULL,
  direction = c("up", "down", "both"),
  type = c("sr", "cusum"),
  evalue = c("betting", "hoeffding"),
  delta = NULL,
  weights = NULL,
  phase1 = NULL
)
```

## Arguments

- arl:

  Target average run length to a false alarm. The alarm threshold is
  `arl` on the e-detector scale (equivalently `alpha = 1 / arl`).

- class:

  Pre-change class, see
  [`edetect_classes()`](https://castlaboratory.github.io/edetect/reference/edetect_classes.md).

- center:

  Pre-change mean (`"bounded"`, `"subgaussian"`), success probability
  (`"bernoulli"`) or rate per unit exposure (`"poisson"`). May be
  omitted when `phase1` is supplied.

- bounds:

  Known bounds `c(a, b)` of the observations (`"bounded"` only).

- sigma:

  Declared sub-Gaussian scale (`"subgaussian"` only). May be omitted
  when `phase1` is supplied, in which case the Phase I standard
  deviation is used and recorded as an assumption.

- direction:

  Change to detect: an increase (`"up"`), a decrease (`"down"`) or
  either (`"both"`, a half-and-half mixture of the two).

- type:

  `"sr"` (Shiryaev–Roberts type, a sum of e-processes started at every
  time) or `"cusum"` (CUSUM type, a maximum). Both are e-detectors;
  `"sr"` is the default.

- evalue:

  E-value family for the `"bounded"` class: `"betting"`
  (`1 + lambda (x - center)`, tight for bounded data) or `"hoeffding"`
  (sub-Bernoulli exponential). Ignored by the other classes, which use
  their natural exponential e-values.

- delta:

  Post-change shifts the mixture covers, in the units of the
  observations (positive numbers; the sign follows `direction`). Each
  shift is mapped to the bet `lambda` that is optimal for it in the
  class. The default is a geometric grid spanning small to large shifts.

- weights:

  Mixture weights over `delta`, normalised internally. Default uniform.

- phase1:

  Optional Phase I (in-control) data: a numeric vector for the
  `"bounded"` and `"subgaussian"` classes, or a data frame with columns
  `x` (counts) and `n` for `"bernoulli"` and `"poisson"`. Used to set
  `center` (and `sigma`) when they are not declared; the source is
  recorded in the design and in every report.

## Value

An object of class `edetect_design`.

## Details

The guarantee is distribution-free within the class: for every
pre-change distribution in it, the expected time to a false alarm is at
least `arl` (Shin, Ramdas and Rinaldo, 2024). The price is paid in
detection delay, which depends on the alternatives the mixture covers.

## References

Shin, J., Ramdas, A. and Rinaldo, A. (2024). E-detectors: a
nonparametric framework for sequential change detection. *The New
England Journal of Statistics in Data Science*, 2(2), 229–260.

## Examples

``` r
edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
#> 
#> ── e-detector design ───────────────────────────────────────────────────────────
#> Pre-change class: "bounded"; centre 0.5 (declared)
#> Bounds: [0, 1]; e-values: "betting"
#> Direction: "up"; type: "sr"; target ARL 370 (threshold 370 on the e-detector
#> scale)
#> Mixture over 7 shifts: 0.025, 0.05, 0.1, 0.175, 0.25, 0.35, 0.45
edetect_design(arl = 500, class = "bernoulli", center = 0.02, direction = "up")
#> 
#> ── e-detector design ───────────────────────────────────────────────────────────
#> Pre-change class: "bernoulli"; centre 0.02 (declared)
#> Direction: "up"; type: "sr"; target ARL 500 (threshold 500 on the e-detector
#> scale)
#> Mixture over 7 shifts: 0.049, 0.098, 0.196, 0.343, 0.49, 0.686, 0.882
edetect_design(arl = 370, class = "subgaussian", phase1 = rnorm(100), direction = "both")
#> 
#> ── e-detector design ───────────────────────────────────────────────────────────
#> Pre-change class: "subgaussian"; centre 0.0332 (phase1, n = 100)
#> Sub-Gaussian scale: 0.9445
#> Direction: "both"; type: "sr"; target ARL 370 (threshold 370 on the e-detector
#> scale)
#> Mixture over 12 shifts: 0.236, 0.472, 0.944, 1.42, 1.89, 2.83, -0.236, -0.472,
#> -0.944, -1.42, -1.89, -2.83
```
