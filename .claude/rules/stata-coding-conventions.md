---
paths:
  - "dofiles/**/*.do"
  - "templates/**/*.do"
  - "explorations/**/*.do"
---

# Stata Coding Conventions

**Standard:** Top empirical economics replication package. Every do-file must run cleanly from a fresh clone, log its actions, and produce outputs that another researcher can audit without asking the author.

---

## 1. File Header

Every do-file begins with:

```stata
*------------------------------------------------------------------------------
* File:     dofiles/03_analysis/main_regression.do
* Project:  [Your project name]
* Author:   [Your name]
* Purpose:  Estimate the main DiD specification on the analysis sample
* Inputs:   data/derived/sample_main.dta
* Outputs:  output/tables/main_regression.tex
*           output/tables/main_regression.csv
*           output/figures/event_study.pdf
* Log:      logs/03_analysis_main_regression.log
*------------------------------------------------------------------------------
```

## 2. Top-of-File Boilerplate

```stata
version 17                  // pin Stata version (override per fork in CLAUDE.md)
clear all
set more off
set varabbrev off           // disallow variable-name abbreviation (catches typos)
capture log close
log using "logs/03_analysis_main_regression.log", replace text

set seed 20260428           // set ONCE if randomness used (date-style integer)
```

## 3. Paths

- **Relative paths only.** Project root is `pwd` when do-files are launched via `scripts/run_stata.sh` or `master.do`.
- **Never** `cd "C:\Users\..."` or `cd "/home/..."`.
- Use forward slashes in paths (Stata accepts them on Windows too).
- Use `tempfile` for intermediate files within a do-file rather than writing to `data/` mid-script.

## 4. Naming

- Variable names: `snake_case`, descriptive (`treated`, `post_2010`, `log_wage`)
- Locals: `local varlist age educ exper exper2`
- Globals: rare; prefix with project tag (`global PROJECT_ROOT ...`) to avoid collisions
- File names mirror their stage: `01_clean_cps.do`, `02_construct_sample.do`, `03_analysis_main.do`

## 5. Estimation Output Discipline

After every estimation, name and store the result:

```stata
reghdfe log_wage treated##post i.year, absorb(state_id) cluster(state_id)
estimates store m_main
```

Save table-ready CSV alongside `.tex`:

```stata
esttab m_main using "output/tables/main_regression.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label
esttab m_main using "output/tables/main_regression.csv", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) plain
```

Regression-table layout is fixed by default: one column per model, with the
parenthesized standard error on the row immediately below its coefficient.
Never put standard errors in a separate column to the right. Use top-level
`b(...) se(...)` options in `esttab`; do not use `wide` or a `cells()` layout
that creates adjacent coefficient and standard-error columns.

Regression-table headers also use a fixed two-row hierarchy. The first header
row contains only model numbers such as `(1)`, `(2)`, and `(3)`. The second
header row contains the dependent-variable name for each model. Never combine
the two into one cell (for example, do not write `Outcome (1)`). In `esttab`,
use `mgroups("(1)" "(2)" ..., pattern(1 1 ...))` for the first row,
`mtitles("Outcome A" "Outcome B" ...)` for the second row, and
`collabels(none)` to suppress an unwanted third header row. Use explicit
`prehead()`/`posthead()` only if ordinary options cannot preserve the required
order in a particular output format.

Regression tables use fixed three-decimal precision. Display coefficients,
standard errors, R-squared values, dependent-variable means, and all other
non-integer model statistics with exactly three digits after the decimal point.
Display `N` and other inherently integer counts with zero decimals. Prefer
`b(3) se(3)` and `stats(..., fmt(0 3 3 ...))`; never use adaptive formats such
as `a3` for regression outputs unless the user explicitly requests them.

Within each regression-model column, vertically align coefficients and their
parenthesized standard errors on the decimal point. Ordinary right alignment
is insufficient because signs, integer widths, parentheses, and significance
stars can shift the visible decimal. For LaTeX, prefer
`alignment(D{.}{.}{-1})` with `\usepackage{dcolumn}` or an equivalent `siunitx`
numeric column. For RTF/Word, use decimal tab stops or an equivalent
decimal-aligned cell layout and inspect the rendered document. CSV stores no
visual alignment, so export fixed three-decimal values that remain numeric when
opened in spreadsheet software.

Place the exact regression-table note `Heteroskedasticity-robust standard errors in parentheses. *
p<0.10, ** p<0.05, *** p<0.01` in one cell. Pass it to `addnotes()` as one
string; never split the standard-error statement and significance thresholds
into different strings, rows, or cells. Render it as one full-width cell in
LaTeX and RTF/Word and as one field in CSV. Additional substantive notes may
occupy separate cells.

## 6. Figures

```stata
graph export "output/figures/event_study.pdf", replace
graph export "output/figures/event_study.png", replace width(1800)
```

Set scheme once at the top of a figure-producing do-file:

```stata
set scheme s2color   // or your project's installed scheme
```

Use the project graph style unless the user requests a different journal style:

- White `graphregion()` and `plotregion()` with no visible border.
- Title text in RGB `"31 55 73"` and secondary text in RGB `"74 89 105"`.
- Focal or exposed series in RGB `"49 145 255"` / HEX `#3191FF`, solid and medium-thick.
- Comparison series in muted blue-gray RGB `"142 164 184"`, dashed and medium-thin.
- Subtle horizontal gridlines only: `glcolor(gs14) glwidth(vthin)`.
- Small axis labels, horizontal labels where practical, and a white legend region.
- Export both PDF and PNG, with PNG width around 1800.

For survival curves, mirror `explorations/cox_hazard_ratio_simulation/dofiles/07_cox_hazard_ratio.do`. In Stata 15, prefer `sts graph, by(...)` when per-line styling is needed, because `stcurve` has limited line-style options.

## 7. Comment Quality

- Comments explain **WHY** (sample restriction rationale, identification choice), not WHAT
- Section headers as numbered banners:

```stata
*--- 1. Load + restrict sample ---------------------------------------------
*--- 2. Define treatment + outcome -----------------------------------------
*--- 3. Main specification -------------------------------------------------
*--- 4. Robustness ---------------------------------------------------------
*--- 5. Export tables/figures ----------------------------------------------
```

- No commented-out dead code
- No unexplained magic numbers — assign to a `local` with a name and a comment

## 8. Forbidden Patterns

| Forbidden | Why | Use instead |
|---|---|---|
| `cd "C:\..."` | Breaks reproducibility | run from project root |
| `set more off` *inside loops* | masks errors | once at top |
| `clear` mid-script without `tempfile` | risks losing data | `preserve`/`restore` or `tempfile` |
| Multiple `set seed` in one do-file | fakes reproducibility | once at top only |
| `varabbrev on` | typos compile silently | always `set varabbrev off` |
| Hardcoded dates/cutoffs without macro | obscures intent | `local cutoff_year 2010 // ATT cutoff per Section 3` |

## 9. Required User-Written Commands

The pipeline assumes these are installed (recipe in `templates/master-do-template.do`):

- `reghdfe` — high-dimensional FE regression
- `ftools` — required by reghdfe
- `estout` (provides `esttab`) — publication tables
- `ivreg2` + `ranktest` — IV with weak-instrument diagnostics
- `boottest` — wild bootstrap inference

Document any additional dependencies in the do-file header.

## 10. Closing

Every do-file ends with:

```stata
log close
```

— so subsequent runs can be matched to their log files.
