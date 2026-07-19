# AGENTS.md - Codex Operating Guide

This repository is a Stata empirical-research workflow template. Codex should preserve the existing Stata pipeline behavior while using this file as the primary project instruction source.

## Project Purpose

- Maintain a reproducible Stata workflow for empirical economics research.
- Keep `dofiles/00_master.do` as the single end-to-end pipeline entry point.
- Keep raw data out of version control.
- Produce audit-friendly tables, figures, logs, and Quarto reports.
- Preserve the existing Claude Code assets under `.claude/` as reference material; do not remove them unless the user explicitly asks.

## Repository Map

- `dofiles/00_master.do`: canonical pipeline orchestrator.
- `dofiles/01_clean/`: raw data to cleaned data.
- `dofiles/02_construct/`: variable construction and samples.
- `dofiles/03_analysis/`: estimation, robustness, event studies, IV, DiD, etc.
- `dofiles/04_output/`: table and figure assembly.
- `dofiles/_utils/`: reusable Stata helpers.
- `data/raw/`: raw datasets, gitignored.
- `data/derived/`: intermediate datasets, gitignored.
- `logs/`: Stata logs, gitignored.
- `output/tables/`: committed publication/audit tables.
- `output/figures/`: committed figures.
- `reports/`: Quarto reports.
- `scripts/`: wrappers and quality tooling.
- `explorations/`: self-contained sandbox analyses and teaching demos.
- `templates/`: reusable project templates.
- `.claude/`: legacy Claude Code agents, skills, rules, and hooks. Treat as reference.

## Exploration Workflow

- New methods, one-off simulations, teaching examples, and diagnostic tests start in `explorations/<project_name>/`, not in the production `dofiles/` pipeline.
- Each exploration should be self-contained: `README.md`, `dofiles/`, `logs/`, `output/tables/`, and `output/figures/`.
- Keep exploration logs inside the corresponding exploration folder. Do not leave Stata console logs or run logs in the repository root.
- If Stata batch mode creates a root-level console transcript such as `01_example.log`, move it to the relevant `explorations/<project_name>/logs/` folder, usually with a `_console.log` suffix.
- Promote an exploration to production only after it is stable, documented, quality-checked, and intentionally wired into `dofiles/00_master.do`.

### Stata Execution Mode

- During exploration, use `stata-mcp` for single-command checks and iterative debugging when available.
- Routine MCP calls must explicitly use `session_id="default"`, which is also used by VS Code manual Run Selection requests, so both interfaces share Stata state.
- Create named sessions only for user-requested isolation or parallel work, and report the session ID. `Stata: Restart Session` clears only `default`, not named sessions.
- Do not create a temporary `.do` file merely to run one command. Save commands retained for analysis in the exploration's substantive `.do` files.
- MCP state is diagnostic and may differ from a fresh run; unsaved interactive output is not final numerical evidence.
- Validate stable exploration files in a fresh batch process. Production verification uses the relevant files and then `dofiles/00_master.do` where applicable.
- Never run MCP and batch jobs concurrently against the same data, log, table, or figure.
- If MCP is unavailable, say so; do not silently substitute batch/CMD or a temporary `.do` file for an MCP-only request.

## Research Workflow and Do-file Orchestration

Use the following lifecycle for new empirical work:

1. **Start in exploration.** Create its README, dofiles, logs, tables, and figures directories.
2. **Inspect before modeling.** Verify data, definitions, coding, missingness, and the proposed sample.
3. **Develop iteratively.** Prefer MCP for focused checks; run only the needed exploration file for file-level tests.
4. **Stabilize and document.** Record inputs, construction, sample rules, models, outputs, limitations, and commands.
5. **Audit before promotion.** Check reproducibility, current logs, traceable outputs, data safety, and quality gates.
6. **Promote intentionally.** Only on explicit request, move code by responsibility, redirect outputs, and wire `00_master.do` in dependency order.
7. **Verify production.** Run promoted files separately, then the full pipeline, comparing key samples, specifications, and outputs.

There is no mandatory rule that one command, model, or analysis module must have
its own `.do` file. Do-file boundaries are a maintainability decision based on
dependencies, independent rerun needs, runtime, and clarity. A single exploration
do-file is valid. If an exploration becomes difficult to debug, Codex may propose a
split, but must distinguish the proposal from a repository requirement and must not
perform a large structural split without user authorization.

An exploration-level orchestrator such as `dofiles/00_run_all.do` is optional. Use
one when an exploration has multiple dependent do-files and benefits from a single
reproduction entry point. It must write only to that exploration's directories and
must not be wired into the production `dofiles/00_master.do` until promotion.

When the user has not specified file boundaries, Codex should first propose a short
mapping of each do-file's purpose, inputs, outputs, and execution order. Codex may
choose routine filenames and logging details, but it must surface substantive choices
such as sample exclusions, variable meanings, model specifications, fixed effects,
and standard-error clustering rather than silently deciding them.

### Prompt Templates

Users may start an exploration with:

```text
请阅读 AGENTS.md 和 README.md。新建 exploration：<project_name>。
数据位于 <data_path>，研究问题是 <research_question>，计划分析 <analyses>。
请先检查数据并提出 do-file 编排、输入、输出和执行顺序，再实施。
所有日志、表格和图形保存在该 exploration 内；不要修改生产 00_master.do。
```

Users may request focused debugging with:

```text
请只在 explorations/<project_name>/ 中调试 <specific_issue>。
单行检查和迭代调试默认使用 stata-mcp；需要文件级测试时，只运行解决该问题所需的 do-file。
不要完整运行生产 pipeline，不要修改生产文件。
用当前日志或输出表格验证结论。
```

Users may request a promotion audit with:

```text
请对 explorations/<project_name>/ 做 production promotion audit，暂不迁移。
检查可复现性、日志、输出、数据安全、变量与样本定义、模型设定和质量评分，
列出尚未满足的生产条件。
```

Users may authorize production promotion with:

```text
explorations/<project_name>/ 已定稿。请将其按职责迁移到正式 dofiles/，
更新输出路径，并按依赖顺序接入 dofiles/00_master.do。
迁移前后分别运行并核对样本、模型和输出；不要改变未获授权的统计设定。
```

## Non-Negotiable Rules

- No numerical research claim without a source in `logs/*.log` or `output/tables/*`.
- Do not fabricate or infer coefficients, standard errors, p-values, sample sizes, or summary statistics.
- Do not commit or expose raw or derived datasets from `data/raw/` or `data/derived/`.
- Do not weaken `.gitignore` data-protection rules without explicit user confirmation.
- Use relative paths in Stata code. Avoid hardcoded machine-specific paths.
- Every substantive `.do` file should have `version`, `set more off`, `set varabbrev off`, logging, and a clear header.
- Write new or modified Stata do-file comments in Chinese unless the user requests another language.
- Keep reports downstream of pipeline outputs. Reports should consume `output/`, not become the primary analysis source.
- For substantive analysis reports, generate both English and Chinese Quarto reports by default unless the user asks for only one language. Use parallel filenames such as `analysis_report.qmd` and `analysis_report_zh.qmd`, and render both to HTML when Quarto is available.
- Do not edit protected files casually: `dofiles/00_master.do`, `.gitignore`, and bibliography files if added later.
- Do not put wildcard paths such as `output/tables/*` inside Stata block comments or header comments. Stata reads `/*` as the start of a block comment even when it appears inside a path, which can silently comment out the rest of a do-file. Prefer `output/tables/` in `.do` file headers.

## Commands

Run a single do-file:

```bash
bash scripts/run_stata.sh dofiles/03_analysis/main_regression.do
```

Run the full pipeline:

```bash
bash scripts/run_pipeline.sh
```

Render the report:

```bash
quarto render reports/analysis_report.qmd
```

If `quarto` is not on `PATH`, use the RStudio-bundled Quarto executable:

```powershell
& 'C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe' render reports\analysis_report.qmd
```

On this Windows setup, prefer `quarto.exe` over `quarto.cmd` when using the RStudio-bundled path because the `.cmd` wrapper can misparse paths under `C:\Program Files\...`.

Score an artifact:

```bash
python scripts/quality_score.py dofiles/03_analysis/main_regression.do
python scripts/quality_score.py reports/analysis_report.qmd
python scripts/quality_score.py scripts/check_data_safety.py
```

Check staged files for data leaks:

```bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

## Stata Conventions

- Pin the Stata version, use the project seed when randomness is involved, and open
  and close logs inside independently runnable do-files.
- Prefer explicit, line-by-line-readable specifications. Do not hide substantive model
  choices, sample restrictions, or variable lists behind unnecessary macros.
- Store estimation results with `estimates store` or `est store` when table assembly depends on them.
- Export figures with native Stata `graph export` as both PDF and PNG; do not commit
  Stata binary graph files. Consult a relevant example only when detailed styling is
  needed.
- For descriptive-statistics and regression tables, read and follow
  `.claude/skills/build-tables/SKILL.md`. That skill is the authoritative source for
  formats, headers, precision, alignment, notes, and output verification.
- Cluster standard errors at the most defensible aggregate level and document the choice.
- Keep required preprocessing outside Stata batch `shell` calls. When substantial
  preprocessing is needed, create a reproducible analysis-ready dataset under
  `data/derived/` and document how to regenerate it.
- When using variables with encoded categories, verify from the codebook whether values are true quantities or category codes. Do not treat education, occupation, or survey response codes as continuous measures unless the codebook confirms they are measured on a numeric scale.
- If a do-file includes numerical interpretation in comments, cite the generated log or output table in the comment and keep the numbers synchronized by rerunning the script after model changes.

## Local Environment

- Tool locations vary by machine. Use the paths supplied by the user or discovered in
  the current environment; do not encode machine-specific paths in project code.
- Prefer explicit executable paths when a tool is not on `PATH`. On Windows, prefer
  `quarto.exe` over a `.cmd` wrapper when paths contain spaces.

## Log Verification

Before stating a numerical result:

1. Find the current log or output table.
2. Verify the value appears in that artifact.
3. Cite the artifact path and, when practical, the surrounding context or line.
4. If no current artifact exists, say that the do-file must be run first.

Use this response pattern when blocked:

```text
I cannot state that result because no fresh log or output table backs it. I need to run the relevant do-file first, or remove the numerical claim.
```

## Data Protection

Never add these to version control:

- `data/raw/**`, except `.gitkeep` and documentation.
- `data/derived/**`, except `.gitkeep` and documentation.
- Stata logs under `logs/`.
- Stata logs under `explorations/*/logs/`.
- Stata binary graphs `*.gph`.
- Data files such as `*.dta`, `*.sav`, `*.por`, `*.parquet`, `*.feather`, `*.csv`, `*.json`, and `*.jsonl`, except narrow whitelisted output/example paths.
- Raw-data-style spreadsheets such as `*.xls` and `*.xlsx`, except narrow whitelisted output/example paths.

Allowed committed outputs:

- `output/tables/*.csv`, `*.tex`, `*.rtf`, and other small non-PII summary tables.
- `output/figures/*.pdf`, `*.png`.
- `explorations/*/output/tables/*.csv`, `*.xls`, and `*.xlsx` only when they are small non-PII teaching or sandbox summary tables.
- Template/example fixtures only when intentionally whitelisted.

## Quality Gates

- `80/100`: acceptable for commit.
- `90/100`: PR-ready.
- `95/100`: excellence target.

Run `python scripts/quality_score.py <file>` before finalizing substantive edits to `.do`, `.qmd`, or user-facing Python scripts.

For `explorations/`, the quality bar is relaxed because these are sandbox or teaching analyses, but they still need to be runnable and honest about limitations.

## Codex Workflow

- Inspect relevant files before editing.
- Prefer small, targeted patches.
- Preserve user changes and do not revert unrelated edits.
- Keep this repository usable by both Codex and Claude Code.
- If changing workflow rules, update `AGENTS.md` and any affected README section together.
- If changing Stata behavior, run the relevant wrapper when Stata is available; otherwise state exactly what was not verified.
- After running Stata batch jobs, check for root-level console transcripts such as `01_height_premium.log` and move them into the corresponding exploration `logs/` folder with a `_console.log` suffix.
- When a user reports a mismatch between their Stata output and reported results, first check whether macros, partial do-file execution, sample filters, or stale derived files changed the actual specification.

## Legacy Claude Code Material

The `.claude/` directory contains richer rule, agent, and skill documentation. Codex should consult it when deeper guidance is needed, especially:

- `.claude/rules/log-verification-protocol.md`
- `.claude/rules/data-protection.md`
- `.claude/rules/quality-gates.md`
- `.claude/rules/stata-coding-conventions.md`
- `.claude/rules/stata-reproducibility-protocol.md`
- `.claude/skills/stata/SKILL.md`

Do not assume Claude-only commands such as `/run-stata` exist in Codex. Use the shell commands documented above.
