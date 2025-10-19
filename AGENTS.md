# Repository Guidelines

## Project Structure & Module Organization
- `backup.sh` — primary Bash entry point that validates arguments, sorts files into year or year-month folders, and generates `back_*.zip` / `back_*.tar.gz` archives.
- `test_backup/` — scratch workspace plus regression helpers (see `run_tests.sh`); keep committed state minimal so tests do not ship artifacts.
- `README.md`, `CLAUDE.md`, `Linux実行手順.md` — reference documents describing requirements and platform notes; update alongside script changes.

## Build, Test, and Development Commands
- `bash backup.sh <target_dir> 1 <zip|gzip|nozip>` — run the yearly backup mode and choose compression at call time; `zip` モードは `zip` コマンドが必要。
- `bash backup.sh <target_dir> 2 <zip|gzip|nozip>` — run the year-month backup mode; confirm that matching files are moved and archived correctly.
- `bash test_backup/run_tests.sh` — smoke-test all compression modes with disposable fixtures; review logs in the generated `logs/` subfolder if failures arise.
- `shellcheck backup.sh` — lint to catch unsafe Bash patterns; treat warnings as actionable even if the script runs.
- `bash -n backup.sh` — fast syntax check before sending a pull request.

## Coding Style & Naming Conventions
- Follow POSIX-friendly Bash; rely on built-in utilities (`printf`, `mkdir`, `tar`) and guard all commands with error handling. Python 3 is the fallback when `zip` is unavailable.
- Indent with four spaces, keep conditional blocks compact, and prefer descriptive variable names (`yearmonth`, `file_count`).
- Echo status lines in Japanese to match existing output; clarify new messages with consistent prefixes (`処理中`, `エラー`).

## Testing Guidelines
- Prepare fixture files inside `test_backup/<scenario>` named with the target yearまたは年月（例: `report_202401.csv`） so pattern moves can be observed.
- After running the script, confirm that生成された `back_*.zip` / `back_*.tar.gz` だけが残ること; 必要に応じて `python3 -m zipfile -l` や `tar -tzf` で中身を確認する。
- When adding features, script regression tests with lightweight harnesses (e.g., Bats) under `test_backup/tests/` and document how to execute them.
- Aim to keep manual verification steps documented in the pull request until automated coverage exists.

## Commit & Pull Request Guidelines
- Use concise, imperative commit subjects (`Add cleanup before zipping`) and keep bodies under 72 characters per line when context is needed.
- Reference related documents or scenarios (`README.md`, `test_backup/demo`) in the body so reviewers understand test coverage.
- Pull requests should summarize behavior changes, list executed commands, and note any remaining manual checks for the reviewer.
- Attach console excerpts demonstrating success (e.g., log lines showing skipped archives) and flag follow-up tasks explicitly in a checklist.
