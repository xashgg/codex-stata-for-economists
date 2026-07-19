# Do-files

Source code for the Stata pipeline.

## Stages

| Folder | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_clean/` | Standardize raw data | `data/raw/*` | `data/derived/clean_*.dta` |
| `02_construct/` | Build samples + variables | `data/derived/clean_*.dta` | `data/derived/sample_*.dta` |
| `03_analysis/` | Estimation | `data/derived/sample_*.dta` | `output/tables/*`, `output/figures/*`, saved estimates |
| `04_output/` | Polish + assemble | `output/*` | rendered `reports/*.qmd` → `docs/*.html` |
| `_utils/` | Helpers (programs, ado-style) | n/a | reusable across stages |

## Conventions

- Each do-file opens its own log: `capture log close` then `log using logs/<name>.log, replace text`
- Each do-file is independently runnable from project root (no `cd`, only relative paths)
- `00_master.do` calls every other do-file in dependency order — never bypass it for production runs
- Pin Stata version at top: `version 17` (override in your fork)
- Use `set seed YYYYMMDD` once per do-file when randomness is involved
- Cluster SEs at the most aggregate plausible level by default — document the choice in a comment

## File Boundaries and Orchestration

The stage directories define responsibilities, not a mandatory file granularity.
The repository does not require each command, model, table, or robustness check to
have its own `.do` file. Choose boundaries based on:

- data dependencies and execution order;
- whether a stage needs to be rerun independently;
- runtime and debugging cost;
- clarity and reuse;
- whether an intermediate analysis-ready dataset is needed.

When promoting an exploration, first map its code to production responsibilities:

```text
raw data handling                 -> 01_clean/
sample and variable construction  -> 02_construct/
estimation and diagnostics        -> 03_analysis/
final table/figure assembly       -> 04_output/
reusable helper programs          -> _utils/
```

Then add explicit `do` calls to `00_master.do` in dependency order. Do not merely
copy an exploration folder wholesale, and do not change sample or model choices as
an undocumented side effect of restructuring.

Before editing `00_master.do`, the user must explicitly authorize production
promotion. A request to test, debug, or add an exploratory model is not production
authorization.

Suggested promotion request:

```text
explorations/<项目名>/ 已定稿。请按职责迁移到正式 dofiles/，更新日志和输出路径，
按依赖顺序接入 dofiles/00_master.do，并比较迁移前后的样本、模型和结果。
```

See `.claude/rules/stata-coding-conventions.md` and `.claude/rules/stata-reproducibility-protocol.md`.

## Analysis Templates

- `templates/did-analysis-template.do`: copy to `dofiles/03_analysis/05_did.do` for TWFE DID, Callaway-Sant'Anna DID, pre-trend checks, and event-study output.
- `templates/ddml-analysis-template.do`: copy to `dofiles/03_analysis/06_ddml.do` for a DDML partial linear model using `ddml` with `rlasso` learners by default.
- `dofiles/00_master.do` records and optionally installs the extra DID/DDML dependencies when `local INSTALL_DEPS = 1`.

## Sandbox Before Production

- New method checks, simulations, and one-off tests should be created under `explorations/<project_name>/` first.
- Only move a do-file into `dofiles/03_analysis/` and wire it into `00_master.do` when the user explicitly wants it in the production pipeline.
- Keep production logs under top-level `logs/`; keep exploration logs under `explorations/<project_name>/logs/`.
- In Stata header comments, avoid paths ending in `/*` such as `output/tables/*`, because Stata parses `/*` as a block-comment opener.
