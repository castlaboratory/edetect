# edetect 0.1.0

First submission.

## Test environments

* local: macOS 26 (Apple Silicon), R 4.6, `R CMD check --as-cran`
* CI (GitHub Actions): macOS-latest (R release), windows-latest (R release),
  ubuntu-latest (R devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* "New submission" (CRAN incoming feasibility). This is the first release.

## Notes for the reviewers

* The package implements e-detectors (Shin, Ramdas and Rinaldo, 2024, cited with
  its DOI in the Description) for process monitoring. The Monte Carlo tests of the
  e-value expectations and of the simulated average run length are skipped on CRAN
  (`skip_on_cran()`); lighter deterministic versions run everywhere.
* Examples and the vignette run in well under a minute; no example is wrapped in
  `\dontrun{}`. The vignette uses a dataset from the suggested package
  `shewhartr` only when it is installed.
