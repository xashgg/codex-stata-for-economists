# CHARLS T2DM Survival Analysis

This exploration estimates associations between loneliness, social isolation, and incident type 2 diabetes using the CHARLS analytic CSV supplied at:

`data/raw/CHARLS_260602/Song2023_charls_analytic_t2dm.csv`

## Run

```bash
"D:\Stata18\StataMP-64.exe" /e do explorations/charls_t2dm_survival/dofiles/01_charls_t2dm_survival.do
```

The script is self-contained and writes logs inside `explorations/charls_t2dm_survival/logs/`.

## Outputs

- `output/tables/sample_summary.csv`: sample size, event count, follow-up, and exposure prevalence.
- `output/tables/baseline_characteristics.csv`: baseline characteristics by loneliness and social isolation.
- `output/tables/cox_models.csv`: hazard ratios, 95% confidence intervals, and p-values from staged Cox models, sex-stratified models, and robustness checks.
- `output/figures/km_t2dm_lonely.pdf` and `.png`: Kaplan-Meier cumulative incidence curve by loneliness.
- `output/figures/km_t2dm_isolated.pdf` and `.png`: Kaplan-Meier cumulative incidence curve by social isolation.
- `reports/charls_t2dm_survival_report.qmd`: analysis report with manuscript-ready Methods text.

## Model Specification

The main endpoint is incident T2DM, using `time_t2dm` as analysis time and `event_t2dm` as the failure indicator. The primary exposures are `lonely` and `isolated`; robustness checks use `si_score`, `si_cat`, `any_social_risk`, `both_social_risk`, and Weibull survival models.

Covariates are added in stages:

- M1: age and sex.
- M2: M1 plus ethnicity, education, and log household income.
- M3: M2 plus log total MET and BMI.
- M4: M3 plus baseline hypertension, heart disease, dyslipidemia, and stroke.

`rural_r`, `employed`, `smoke_cur`, and `drink_cur` are constant in this CSV and are documented in the log but not included in models.
