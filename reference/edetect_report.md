# The full report of a detector

Everything a reader needs to audit an alarm or its absence: what was
assumed (class, centre and its source, bounds or scale, direction), how
the detector was built (type, e-value family, mixture), what was
observed, the outcome and the software versions.

## Usage

``` r
edetect_report(state)
```

## Arguments

- state:

  An `edetect_chart`.

## Value

A list of class `edetect_report`.

## Examples

``` r
design <- edetect_design(arl = 100, class = "bernoulli", center = 0.05)
state <- edetect_update(edetect_init(design), x = c(2, 3, 1, 4), n = 50)
edetect_report(state)
#> 
#> ── e-detector report ───────────────────────────────────────────────────────────
#> Class "bernoulli", centre 0.05 (declared); direction "up"; type "sr"; target
#> ARL 100.
#> Observations: 4. Maximum evidence 0.337 against a threshold of 100.
#> ✔ No alarm.
#> 
#> ── Assumptions ──
#> 
#> • Pre-change trials have success probability at most 0.05; dependence within a
#> subgroup is allowed.
#> • The centre was declared by the user.
#> • Observations arrive in time order and none was dropped or imputed.
#> edetect 0.0.0.9000, R version 4.6.1 (2026-06-24)
```
