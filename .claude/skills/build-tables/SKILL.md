---
name: build-tables
description: Combine saved Stata estimates or posted descriptive statistics into publication-ready tables via esttab. Produces synchronized .tex (for paper), .csv (for audit), and .rtf (for Word) files with consistent formatting.
disable-model-invocation: true
argument-hint: "[table-name or estimates-list]"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob"]
---

# Build Publication-Ready Tables

Take saved estimates or posted descriptive statistics and produce synchronized `.tex` (for the paper), `.csv` (for audit/sharing), and `.rtf` (for Microsoft Word) tables with the project's standard formatting.

## When to Use

- Whenever the user requests an exportable descriptive-statistics or regression table
- After running `dofiles/03_analysis/*.do` that produces `est store m_<name>` results
- When assembling a multi-spec table (main + alt outcome + alt cluster + alt FE)
- Before rendering the report — tables must exist in `output/tables/` first

## Steps

1. **Identify the estimates** in `$ARGUMENTS`:
   - If a table name (e.g., `main_regression`): search `dofiles/03_analysis/` for `est store m_main*` and assemble
   - If an explicit estimates list (e.g., `m_ols m_iv m_did`): use those
   - If empty: ask the user which table to build

2. **Locate the producing do-file** that has the `est store` calls. The do-file should also do the `esttab` export. If it doesn't, write a helper do-file in `dofiles/04_output/<table>_assemble.do`.

3. **Compose the `esttab` call** with project conventions:

   For regression tables, assign exactly one output column to each model. Put the standard error in parentheses on the row immediately below its coefficient. Do not put the coefficient and standard error in adjacent columns. Use top-level `b(...) se(...)` options; do not use `wide`, and do not use a `cells()` specification that creates separate coefficient and standard-error columns.

   Build a two-row regression header. Put only sequential model numbers—`(1)`, `(2)`, `(3)`, and so on—in the first header row. Put each model's dependent-variable name in a separate second header row. Never combine a dependent-variable name and model number in one cell; titles such as `Donations (1)` are invalid. In `esttab`, use `mgroups()` with `pattern(1 1 ...)` for the first model-number row, `mtitles()` for the second dependent-variable row, and `collabels(none)` to suppress an unwanted third row. Inspect every exported format because header rendering can differ across `.tex`, `.csv`, and `.rtf`.

   Format regression results with fixed three-decimal precision. Coefficients, standard errors, R-squared values, dependent-variable means, and all other non-integer model statistics must show exactly three digits after the decimal point. Keep `N` and other integer counts at zero decimals. Use `b(3) se(3)` and `stats(..., fmt(0 3 3 ...))`; do not use adaptive formats such as `a3` in regression tables.

   Vertically align the numeric core of regression entries on the decimal point within every model column. Plain right alignment is not enough: coefficients and their parenthesized standard errors must use the same decimal anchor despite different integer widths, signs, parentheses, or significance stars. For LaTeX, prefer `alignment(D{.}{.}{-1})` with the `dcolumn` package or an equivalent `siunitx` column. For RTF/Word, use decimal tab stops or an equivalent decimal-aligned cell layout and visually inspect the rendered file. CSV cannot store visual alignment; export fixed three-decimal numeric strings so spreadsheet software can parse and align them as numbers.

   Put the exact complete note `Heteroskedasticity-robust standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01` in a single table cell. Do not split it into separate standard-error and significance strings, rows, or cells. Pass it as one string to `addnotes()`. In LaTeX, verify it is one full-width `multicolumn` cell; in RTF/Word, verify it is one merged/full-width cell; in CSV, verify the entire sentence occupies one field. Keep any additional substantive note in a separate cell.

   Choose formats according to the statistic, not merely the source variable's storage type. Format `N` with zero decimal places. For integer-valued variables, format integer-valued statistics such as `Min` and `Max` with zero decimal places, but format derived statistics that need not be integers—especially `Mean` and `SD`—with two decimal places by default. For non-integer variables, use two decimal places by default. Numeric values that display decimals must align on the decimal point in rendered `.tex` and `.rtf`/Word tables. Apply the same convention in `.csv`.

   ```stata
   estimates restore m_main
   estimates restore m_alt_cluster
   estimates restore m_alt_fe

   esttab m_main m_alt_cluster m_alt_fe ///
       using "output/tables/<name>.tex", replace ///
       b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
       booktabs label alignment(D{.}{.}{-1}) ///
       mgroups("(1)" "(2)" "(3)", pattern(1 1 1)) ///
       mtitles("Outcome A" "Outcome A" "Outcome B") collabels(none) ///
       stats(N r2_within mean_dep, ///
             labels("Observations" "Within R-sq" "Mean of dep var") ///
             fmt(%9.0fc %9.3f %9.3f)) ///
       drop(_cons) ///
       title("<table title>") ///
       addnotes("Heteroskedasticity-robust standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")

   esttab m_main m_alt_cluster m_alt_fe ///
       using "output/tables/<name>.csv", replace ///
       b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) plain ///
       mgroups("(1)" "(2)" "(3)", pattern(1 1 1)) ///
       mtitles("Outcome A" "Outcome A" "Outcome B") collabels(none) ///
       stats(N r2_within mean_dep, fmt(0 3 3))

   esttab m_main m_alt_cluster m_alt_fe ///
       using "output/tables/<name>.rtf", replace ///
       b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
       label ///
       mgroups("(1)" "(2)" "(3)", pattern(1 1 1)) ///
       mtitles("Outcome A" "Outcome A" "Outcome B") collabels(none) ///
       stats(N r2_within mean_dep, ///
             labels("Observations" "Within R-sq" "Mean of dep var") ///
             fmt(0 3 3)) ///
       title("<table title>") ///
       addnotes("Heteroskedasticity-robust standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
   ```

   Apply the same three-format rule to descriptive-statistics tables produced with `estpost summarize` or `estpost tabstat`: generate `.tex`, `.csv`, and `.rtf` from the same posted results.

4. **Run the do-file** via `/run-stata`.

5. **Verify outputs:**
   - `.tex`, `.csv`, and `.rtf` all exist in `output/tables/`
   - Every model occupies one column, and every parenthesized standard error appears on the row immediately below its coefficient—not in a column to the right
   - The first header row contains model numbers only; the second header row contains dependent-variable names only; no cell combines the two
   - Every non-integer regression result has exactly three digits after the decimal point; `N` and other integer counts have none
   - Coefficients and standard errors are vertically aligned on their decimal points within each model column in rendered `.tex` and `.rtf`/Word output—not merely right-aligned
   - The full standard-error/significance note appears in one cell and exactly reads `Heteroskedasticity-robust standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01`
   - Read the `.csv` and spot-check coefficients are sensible
   - Confirm the `.tex` includes N, R², mean dep var, cluster info, significance stars
   - Open or inspect the `.rtf` sufficiently to confirm it is nonempty and Word-compatible
   - Render or open the `.tex` and `.rtf` tables and confirm that decimal values align on their decimal points; verify that `N` is an integer, `Mean` and `SD` retain two decimals, integer-valued `Min`/`Max` omit decimals, and the `.csv` follows the same convention

6. **Report:** paths of the new `.tex`, `.csv`, and `.rtf`, the specification each column represents, and a one-line summary of the headline coefficient.

## Examples

- `/build-tables main_regression` → assembles `output/tables/main_regression.{tex,csv,rtf}` from `m_main`-prefixed estimates.
- `/build-tables m_ols m_iv m_did` → assembles a 3-column table from those specific saved estimates.

## Troubleshooting

- **"estimates ... not found"** — `est store m_<name>` was never run. Re-run the producing do-file.
- **Missing `mean_dep`** — add `estadd ysumm` after each `reghdfe` call in the producing do-file.
- **`esttab` not installed** — `ssc install estout, replace`.
- **Long table names break LaTeX** — use the `label` option and define short labels via `label var`.

## Notes

- Requested descriptive-statistics and regression tables ALWAYS go to `.tex`, `.csv`, and `.rtf` — `.tex` is for LaTeX/report inclusion, `.csv` is for auditing, and `.rtf` is for insertion into Microsoft Word.
- Regression tables ALWAYS place parenthesized standard errors below coefficients. A side-by-side coefficient/standard-error column layout is not permitted unless the user explicitly overrides this rule.
- Regression tables ALWAYS separate model numbers from dependent-variable names: numbers alone on the first header row, dependent-variable names alone on the second. Combined labels such as `Outcome (1)` are not permitted unless the user explicitly overrides this rule.
- Regression tables ALWAYS use fixed three-decimal precision for coefficients, standard errors, R-squared values, dependent-variable means, and other non-integer model statistics. `N` and other integer counts use zero decimals. Adaptive formats such as `a3` are not permitted unless the user explicitly overrides this rule.
- Regression tables ALWAYS align the numeric core of coefficients and standard errors vertically on the decimal point within each model column. Ordinary right alignment does not satisfy this requirement. Verify the rendered LaTeX and RTF/Word artifacts; CSV must retain parseable fixed-three-decimal values.
- Regression tables ALWAYS keep `Heteroskedasticity-robust standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01` together in one cell. Never split this text across multiple `addnotes()` strings, rows, or cells unless the user explicitly overrides the rule.
- Within each numeric column, use consistent decimal precision and decimal-point alignment except where an inherently integer statistic correctly omits decimals. Do not infer that `Mean` or `SD` is an integer merely because the source variable is integer-valued.
- Default precision is `N`: zero decimals; `Mean` and `SD`: two decimals; integer-valued `Min` and `Max`: zero decimals; other non-integer statistics: two decimals. A direct user request or documented journal requirement may override this default.
- Never hand-edit the produced `.tex`; the next pipeline run will overwrite it. Adjust `esttab` options instead.
- Significance stars: `* p<0.10, ** p<0.05, *** p<0.01` is the project default. Override only if the journal requires different.
