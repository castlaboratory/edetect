# Initialise an e-detector

Initialise an e-detector

## Usage

``` r
edetect_init(design)
```

## Arguments

- design:

  An
  [`edetect_design()`](https://castlaboratory.github.io/edetect/reference/edetect_design.md).

## Value

An object of class `edetect_chart` holding the design, the running state
and an empty trajectory.

## Examples

``` r
design <- edetect_design(arl = 370, class = "bounded", center = 0.5, bounds = c(0, 1))
state <- edetect_init(design)
state
#> 
#> ── e-detector chart ────────────────────────────────────────────────────────────
#> "bounded" class, centre 0.5 (declared), direction "up", type "sr", target ARL
#> 370
#> No observations yet.
```
