#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/backup.sh"
WORK_ROOT="$(mktemp -d)"
LOG_ROOT="$WORK_ROOT/logs"
mkdir -p "$LOG_ROOT"

cleanup() {
    rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

fail() {
    echo "NG: $1" >&2
    exit 1
}

pass() {
    echo "OK: $1"
}

test_nozip() {
    local workdir="$WORK_ROOT/nozip_case"
    mkdir -p "$workdir"
    touch "$workdir/report_2010.txt"

    bash "$SCRIPT_PATH" "$workdir" 1 nozip 2010 2010 > "$LOG_ROOT/nozip.log"

    [[ -d "$workdir/2010" ]] || fail "nozip: 2010 フォルダが作成されていません"
    [[ -f "$workdir/2010/report_2010.txt" ]] || fail "nozip: ファイルが 2010/ に移動されていません"
    [[ ! -f "$workdir/back_2010.zip" ]] || fail "nozip: back_2010.zip が作成されています"
    pass "nozip: フォルダ保持とファイル移動を確認しました"
}

test_zip() {
    if ! command -v zip > /dev/null 2>&1; then
        echo "SKIP: zipコマンドが存在しないため zip モードの検証をスキップします"
        return
    fi
    local workdir="$WORK_ROOT/zip_case"
    mkdir -p "$workdir"
    touch "$workdir/summary_2012.csv"

    bash "$SCRIPT_PATH" "$workdir" 1 zip 2012 2012 > "$LOG_ROOT/zip.log"

    local archive="$workdir/back_2012.zip"
    [[ -f "$archive" ]] || fail "zip: back_2012.zip が作成されていません"
    [[ ! -d "$workdir/2012" ]] || fail "zip: 2012 フォルダが削除されていません"
    unzip -Z1 "$archive" | grep -q "2012/summary_2012.csv" || fail "zip: アーカイブ内にファイルが見つかりません"
    pass "zip: アーカイブ作成とフォルダ削除を確認しました"
}

test_gzip() {
    local workdir="$WORK_ROOT/gzip_case"
    mkdir -p "$workdir"
    touch "$workdir/log_201305.txt"

    bash "$SCRIPT_PATH" "$workdir" 2 gzip 2013 2013 > "$LOG_ROOT/gzip.log"

    local archive="$workdir/back_201305.tar.gz"
    [[ -f "$archive" ]] || fail "gzip: back_201305.tar.gz が作成されていません"
    [[ ! -d "$workdir/201305" ]] || fail "gzip: 201305 フォルダが削除されていません"
    tar -tzf "$archive" | grep -q "201305/log_201305.txt" || fail "gzip: アーカイブ内にファイルが見つかりません"
    pass "gzip: gzipアーカイブ作成とフォルダ削除を確認しました"
}

test_nozip
test_zip
test_gzip
echo "All test cases passed."
