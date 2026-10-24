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
  phase1 = NULL,
  phase1_beta = 0.1
)
```

## Arguments

- arl:

  Target average run length to a false alarm. The alarm threshold is
  `arl` on the e-detector scale (equivalently `alpha = 1 / arl`).

- class:

  Pre-change class, see
  [`edetect_classes()`](https://castlaboratory.github.io/edetect/dev/reference/edetect_classes.md).

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
  time) or `"cusum"` (CUSUM type, a maximum). Both are e-detectors and
  both use the threshold `arl`, which for the CUSUM type is valid but
  conservative (Shin, Ramdas and Rinaldo, 2024, Section 2.5); `"sr"` is
  the default.

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

- phase1_beta:

  Probability that the Phase I bound on the centre fails. When `center`
  is estimated from `phase1`, the detector is centred at a one-sided
  confidence bound of level `1 - phase1_beta` (the upper bound for
  `"up"`, the lower bound for `"down"`, both bounds at level
  `1 - phase1_beta / 2` for `"both"`) rather than at the estimate. With
  probability at least `1 - phase1_beta` over the Phase I sample the
  average run length is then at least `arl`, and the probability of a
  false alarm by time `t` is at most `phase1_beta + t / arl`. `NULL`
  centres the detector at the Phase I estimate (plug-in), for which no
  guarantee holds. Ignored when `center` is declared.

## Value

An object of class `edetect_design`.

## Details

The guarantee is distribution-free within the class: for every
pre-change distribution in it, the expected time to a false alarm is at
least `arl` (Shin, Ramdas and Rinaldo, 2024, Theorem 2.4), and the
probability of a false alarm by any time `t`, including data-dependent
monitoring horizons, is at most `t / arl` (Ramdas, 2026). The price is
paid in detection delay, which depends on the alternatives the mixture
covers.

With a centre estimated from Phase I data, the guarantee of an
e-detector is not robust to estimation error: the Shiryaev–Roberts
statistic is a martingale plus a linear drift when the pre-change mean
equals the centre, so its average run length is close to `arl`, and a
centre estimated below the in-control mean turns the in-control e-values
into evidence. The bounds used by `phase1_beta` are inversions of the
e-values of each class. For the `"bounded"` class with
`evalue = "betting"` the bound inverts a betting martingale over the
Phase I observations in the order given (Waudby-Smith and Ramdas, 2024),
which adapts to the variance of the data; with `evalue = "hoeffding"` it
is the Bernoulli Kullback–Leibler (Chernoff) bound after rescaling to
`[0, 1]`. The other classes use the Bernoulli Kullback–Leibler bound
(`"bernoulli"`), the Poisson Kullback–Leibler bound for `"poisson"`, and
the Gaussian bound with the declared scale for `"subgaussian"`. They
require Phase I observations whose conditional means equal the
in-control mean (independent and identically distributed observations
are a special case). When `sigma` is also estimated from Phase I, the
bound for the `"subgaussian"` class is approximate.

The width of a betting bound has two regimes. While the bets adapt to
the variance it is close to `sd * sqrt(2 * log(1 / phase1_beta) / n)`;
when the standard deviation is small compared with the distance from the
estimate to the far bound, the bets are capped and the width is close to
that distance times `log(1 / phase1_beta) / (0.9 * n)`. The design
records which one applies in `bound_regime`, and the lag-one
autocorrelation of a numeric Phase I sample in `phase1_acf1`;
[`edetect_report()`](https://castlaboratory.github.io/edetect/dev/reference/edetect_report.md)
states both.

## References

Shin, J., Ramdas, A. and Rinaldo, A. (2024). E-detectors: a
nonparametric framework for sequential change detection. *The New
England Journal of Statistics in Data Science*, 2(2), 229–260.
[doi:10.51387/23-NEJSDS51](https://doi.org/10.51387/23-NEJSDS51)

Ramdas, A. (2026). Universality of e-detectors for ARL control.
arXiv:2608.12660.

Waudby-Smith, I. and Ramdas, A. (2024). Estimating means of bounded
random variables by betting. *Journal of the Royal Statistical Society
Series B*, 86(1), 1–27.
[doi:10.1093/jrsssb/qkad009](https://doi.org/10.1093/jrsssb/qkad009)

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
edetect_design(arl = 370, class = "subgaussian", phase1 = rnorm(100), sigma = 1, direction = "both")
#> 
#> ── e-detector design ───────────────────────────────────────────────────────────
#> Pre-change class: "subgaussian"; centre -0.05924 (phase1_bound, n = 100)
#> Phase I estimate -0.05924; bets centred at 0.1855 and -0.304 (failure
#> probability 0.1)
#> Sub-Gaussian scale: 1
#> Direction: "both"; type: "sr"; target ARL 370 (threshold 370 on the e-detector
#> scale)
#> Mixture over 12 shifts: 0.25, 0.5, 1, 1.5, 2, 3, -0.25, -0.5, -1, -1.5, -2, -3
```
