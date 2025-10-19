#!/bin/bash

# バックアップスクリプト
# 使用法: ./backup.sh <フォルダ名> <モード> <圧縮モード> [<開始年> <終了年>]
# モード: 1=年モード(yyyy), 2=年月モード(yyyymm)
# 圧縮モード: nozip=圧縮しない zip=zip圧縮 gzip=gzip圧縮

# 引数チェック
if [ $# -ne 3 ] && [ $# -ne 5 ]; then
    echo "エラー: 引数が正しく設定されていません"
    echo "使用法: $0 <フォルダ名> <モード> <圧縮モード> [<開始年> <終了年>]"
    echo "モード: 1=年モード(yyyy), 2=年月モード(yyyymm)"
    echo "圧縮モード: nozip=圧縮しない zip=zip圧縮 gzip=gzip圧縮"
    echo "開始年・終了年は省略時 2010〜2024 を処理します"
    exit 1
fi

dir="$1"
mode="$2"
compress_mode="$3"
DEFAULT_START_YEAR=2010
DEFAULT_END_YEAR=2024
start_year="$DEFAULT_START_YEAR"
end_year="$DEFAULT_END_YEAR"

if [ $# -eq 5 ]; then
    start_year="$4"
    end_year="$5"
fi

# 年度バリデーション
is_valid_year() {
    [[ "$1" =~ ^[0-9]{4}$ ]]
}

if ! is_valid_year "$start_year" || ! is_valid_year "$end_year"; then
    echo "エラー: 開始年と終了年は4桁の数字で指定してください"
    exit 1
fi

if [ "$start_year" -gt "$end_year" ]; then
    echo "エラー: 開始年は終了年以下で指定してください"
    exit 1
fi

# モードチェック
if [ "$mode" != "1" ] && [ "$mode" != "2" ]; then
    echo "エラー: モードは1または2を指定してください"
    echo "モード: 1=年モード(yyyy), 2=年月モード(yyyymm)"
    exit 1
fi

# 圧縮モードチェック
if [ "$compress_mode" != "zip" ] && [ "$compress_mode" != "nozip" ] && [ "$compress_mode" != "gzip" ]; then
    echo "エラー: 圧縮モードはzip、nozip、またはgzipを指定してください"
    echo "圧縮モード: nozip=圧縮しない zip=zip圧縮 gzip=gzip圧縮"
    exit 1
fi

if [ "$compress_mode" = "zip" ] && ! command -v zip > /dev/null 2>&1; then
    echo "エラー: zip モードを選択しましたが zip コマンドが見つかりません"
    exit 1
fi

# zip アーカイブ作成ヘルパー
compress_with_zip() {
    local archive_path="$1"
    local target_dir="$2"

    if command -v zip > /dev/null 2>&1; then
        zip -rq "$archive_path" "$target_dir"
    else
        echo "  エラー: zipコマンドが見つかりません" >&2
        return 1
    fi
}

# フォルダの存在チェック
if [ ! -d "$dir" ]; then
    echo "エラー: フォルダ '$dir' が存在しません"
    exit 1
fi

echo "バックアップ処理開始: $dir"
cd "$dir" || exit 1

# モードによって処理を分岐
if [ "$mode" = "1" ]; then
    # 年モード: 2010から2024まで処理
    for ((year=start_year; year<=end_year; year++)); do
        echo "処理中: $year"
        archive_name=""
        if [ "$compress_mode" = "zip" ]; then
            archive_name="back_${year}.zip"
        elif [ "$compress_mode" = "gzip" ]; then
            archive_name="back_${year}.tar.gz"
        fi
        target_dir="$year"
        created_dir=0

        # zip ファイルが既に存在するかチェック
        if [ -n "$archive_name" ] && [ -f "$archive_name" ]; then
            echo "  $archive_name は既に存在します。スキップします。"
            continue
        fi

        # 年フォルダを作成
        if [ ! -d "$target_dir" ]; then
            mkdir "$target_dir"
            created_dir=1
            echo "  フォルダ $target_dir を作成しました"
        fi

        # 該当するファイルを検索して移動
        file_count=0
        for file in *${year}*; do
            if [ -f "$file" ] && [[ "$file" != back_* ]] && { [ -z "$archive_name" ] || [ "$file" != "$archive_name" ]; }; then
                mv "$file" "$target_dir/"
                echo "    $file を $target_dir/ に移動しました"
                ((file_count++))
            fi
        done

        if [ $file_count -eq 0 ]; then
            echo "  $year に該当するファイルがありません"
            if [ $created_dir -eq 1 ]; then
                rmdir "$target_dir"
            fi
            continue
        fi

        if [ "$compress_mode" = "zip" ]; then
            # フォルダを圧縮（移動モード）
            echo "  $target_dir フォルダを圧縮中..."
            if compress_with_zip "$archive_name" "$target_dir"; then
                echo "  $archive_name を作成しました"
                rm -rf "$target_dir"
                echo "  $target_dir フォルダを削除しました"
            else
                echo "  エラー: $year の圧縮に失敗しました"
                exit 1
            fi
        elif [ "$compress_mode" = "gzip" ]; then
            echo "  $target_dir フォルダをgzip圧縮中..."
            if tar -czf "$archive_name" "$target_dir/"; then
                echo "  $archive_name を作成しました"
                rm -rf "$target_dir"
                echo "  $target_dir フォルダを削除しました"
            else
                echo "  エラー: $year のgzip圧縮に失敗しました"
                exit 1
            fi
        else
            echo "  圧縮モード: nozip のためフォルダを保持します"
        fi
    done
elif [ "$mode" = "2" ]; then
    # 年月モード: 2010年1月から2024年12月まで処理
    for ((year=start_year; year<=end_year; year++)); do
        for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
            yearmonth=$(printf "%04d%s" "$year" "$month")
            echo "処理中: $yearmonth"
            archive_name=""
            if [ "$compress_mode" = "zip" ]; then
                archive_name="back_${yearmonth}.zip"
            elif [ "$compress_mode" = "gzip" ]; then
                archive_name="back_${yearmonth}.tar.gz"
            fi
            target_dir="$yearmonth"
            created_dir=0

            # zip ファイルが既に存在するかチェック
            if [ -n "$archive_name" ] && [ -f "$archive_name" ]; then
                echo "  $archive_name は既に存在します。スキップします。"
                continue
            fi

            # 年月フォルダを作成
            if [ ! -d "$target_dir" ]; then
                mkdir "$target_dir"
                created_dir=1
                echo "  フォルダ $target_dir を作成しました"
            fi

            # 該当するファイルを検索して移動
            file_count=0
            for file in *${yearmonth}*; do
                if [ -f "$file" ] && [[ "$file" != back_* ]] && { [ -z "$archive_name" ] || [ "$file" != "$archive_name" ]; }; then
                    mv "$file" "$target_dir/"
                    echo "    $file を $target_dir/ に移動しました"
                    ((file_count++))
                fi
            done

            if [ $file_count -eq 0 ]; then
                echo "  $yearmonth に該当するファイルがありません"
                if [ $created_dir -eq 1 ]; then
                    rmdir "$target_dir"
                fi
                continue
            fi

            if [ "$compress_mode" = "zip" ]; then
                # フォルダを圧縮（移動モード）
                echo "  $target_dir フォルダを圧縮中..."
                if compress_with_zip "$archive_name" "$target_dir"; then
                    echo "  $archive_name を作成しました"
                    rm -rf "$target_dir"
                    echo "  $target_dir フォルダを削除しました"
                else
                    echo "  エラー: $yearmonth の圧縮に失敗しました"
                    exit 1
                fi
            elif [ "$compress_mode" = "gzip" ]; then
                echo "  $target_dir フォルダをgzip圧縮中..."
                if tar -czf "$archive_name" "$target_dir/"; then
                    echo "  $archive_name を作成しました"
                    rm -rf "$target_dir"
                    echo "  $target_dir フォルダを削除しました"
                else
                    echo "  エラー: $yearmonth のgzip圧縮に失敗しました"
                    exit 1
                fi
            else
                echo "  圧縮モード: nozip のためフォルダを保持します"
            fi
        done
    done
fi

echo "バックアップ処理完了"
