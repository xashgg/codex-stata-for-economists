# Explorations

This folder is a sandbox for experimental and exploratory work. New methods, prototypes, simulations, diagnostics, and teaching demos go here first, not directly into production folders.

## How It Works

1. Create a subfolder for each exploration, for example `explorations/new_estimator/`.
2. Keep it self-contained with its own `README.md`, `dofiles/`, `logs/`, and `output/`.
3. Work freely during exploration, but keep logs and outputs auditable.
4. Decide whether to graduate the work to production, keep exploring, or archive it.

## Do-file Orchestration

There is no required one-model-per-file or one-step-per-file rule. An exploration
may begin with one independently runnable do-file. Split it only when dependencies,
runtime, repeated partial reruns, or readability make separate files useful.

For a multi-file exploration, an optional `dofiles/00_run_all.do` may call the other
files in dependency order. This is an exploration-local reproduction entry point:

```text
explorations/[active-project]/dofiles/
  00_run_all.do              # optional
  01_prepare_data.do
  02_main_analysis.do
  03_robustness.do
```

It must keep logs and outputs inside the exploration. It is not the production
`dofiles/00_master.do` and must not be added to that pipeline without explicit user
authorization.

If the user has not specified file boundaries, first propose each file's purpose,
inputs, outputs, and execution order. Treat the proposal as a maintainability choice,
not as a repository requirement.

## Prompt Templates

Start a new exploration:

```text
请阅读 AGENTS.md 和 README.md。新建 exploration：<项目名>。
数据位于 <路径>，研究问题是 <问题>。请先提出 do-file 编排方案，再实施。
日志和输出全部保存在该 exploration 内，不要修改生产 00_master.do。
```

Debug only one part:

```text
请只调试 explorations/<项目名>/ 中的 <具体问题>，只运行必要的 do-file。
不要运行完整生产 pipeline，也不要修改生产文件。
```

Audit before promotion:

```text
请对 explorations/<项目名>/ 做 production promotion audit，暂不迁移。
检查复现、日志、输出、数据安全、研究设定、README 和质量评分。
```

See the root `README.md` and `AGENTS.md` for the complete promotion prompt.

## Required Structure

```text
explorations/
  [active-project]/
    README.md
    dofiles/
    logs/
    output/
      tables/
      figures/
  ARCHIVE/
    completed_[name]/
    abandoned_[name]/
```

## Rules

- New top-level project folders under `explorations/` are gitignored by default. To publish a new exploration, intentionally add its folder to the allowlist in the root `.gitignore`.
- Do not leave Stata logs in the repository root.
- Move run logs and console transcripts to the relevant `explorations/<project>/logs/` folder, usually with a `_console.log` suffix for console transcripts.
- Logs remain gitignored. Commit only the exploration README, do-files, small non-PII summary tables, and figure exports when useful.
- If a method is only a simulation or test, keep it here until the user explicitly asks to integrate it into `dofiles/00_master.do`.
- Avoid `/*` inside Stata header comments, including paths like `output/tables/*`; Stata treats it as a block-comment opener.
- Export Stata figures as both PDF and PNG.

## Current Method Examples

- `cox_hazard_ratio_simulation/`: self-contained Cox proportional hazards simulation using `stset`, `stcox, hr`, a proportional-hazards diagnostic, and survival-curve exports.
- `staggered_did_simulation/`: staggered DID simulation and event-study outputs.

See `.claude/rules/exploration-folder-protocol.md` and `.claude/rules/exploration-fast-track.md` for legacy Claude Code reference material.
