# Repository Guidelines

## Project Structure & Module Organization
- `backup.sh` — primary Bash entry point that validates arguments, sorts files into year or year-month folders, and generates `back_*.zip` archives.
- `test_backup/` — scratch workspace for crafting sample source trees; keep committed state empty so tests do not ship artifacts.
- `README.md`, `CLAUDE.md`, `Linux実行手順.md` — reference documents describing requirements and platform notes; update alongside script changes.

## Build, Test, and Development Commands
- `bash backup.sh <target_dir> 1` — run the yearly backup mode; use a disposable directory such as `test_backup/demo` when validating logic.
- `bash backup.sh <target_dir> 2` — run the year-month backup mode; confirm that matching files are moved and compressed.
- `shellcheck backup.sh` — lint to catch unsafe Bash patterns; treat warnings as actionable even if the script runs.
- `bash -n backup.sh` — fast syntax check before sending a pull request.

## Coding Style & Naming Conventions
- Follow POSIX-friendly Bash; rely on built-in utilities (`printf`, `mkdir`, `zip`) and guard all commands with error handling.
- Indent with four spaces, keep conditional blocks compact, and prefer descriptive variable names (`yearmonth`, `file_count`).
- Echo status lines in Japanese to match existing output; clarify new messages with consistent prefixes (`処理中`, `エラー`).

## Testing Guidelines
- Prepare fixture files inside `test_backup/<scenario>` named with the target year or year-month (`report_202401.csv`) so pattern moves can be observed.
- After running the script, confirm that only `back_*.zip` archives remain alongside untouched files; inspect archive contents with `unzip -l`.
- When adding features, script regression tests with lightweight harnesses (e.g., Bats) under `test_backup/tests/` and document how to execute them.
- Aim to keep manual verification steps documented in the pull request until automated coverage exists.

## Commit & Pull Request Guidelines
- Use concise, imperative commit subjects (`Add cleanup before zipping`) and keep bodies under 72 characters per line when context is needed.
- Reference related documents or scenarios (`README.md`, `test_backup/demo`) in the body so reviewers understand test coverage.
- Pull requests should summarize behavior changes, list executed commands, and note any remaining manual checks for the reviewer.
- Attach console excerpts demonstrating success (e.g., log lines showing skipped archives) and flag follow-up tasks explicitly in a checklist.
