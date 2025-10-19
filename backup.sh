#!/bin/bash

# Backup script
# Usage: ./backup.sh <directory> <mode> <compression_mode> [<start_year> <end_year>]
# Mode: 1=Year mode (yyyy), 2=Year-month mode (yyyymm)
# Compression mode: nozip=no compression, zip=zip archive, gzip=gzip archive

# Validate arguments
if [ $# -lt 3 ] || [ $# -gt 5 ]; then
    echo "Error: invalid arguments"
    echo "Usage: $0 <directory> <mode> <compression_mode> [<start_year> <end_year>]"
    echo "Mode: 1=Year mode (yyyy), 2=Year-month mode (yyyymm)"
    echo "Compression mode: nozip=no compression, zip=zip archive, gzip=gzip archive"
    echo "If start/end year are omitted, the range defaults to 2010 through the current year"
    exit 1
fi

dir="$1"
mode="$2"
compress_mode="$3"
DEFAULT_START_YEAR=2010
DEFAULT_END_YEAR=$(date +%Y)
start_year="$DEFAULT_START_YEAR"
end_year="$DEFAULT_END_YEAR"

if [ $# -ge 4 ]; then
    start_year="$4"
fi

if [ $# -eq 5 ]; then
    end_year="$5"
fi

# Year validation helper
is_valid_year() {
    [[ "$1" =~ ^[0-9]{4}$ ]]
}

if ! is_valid_year "$start_year" || ! is_valid_year "$end_year"; then
    echo "Error: start and end year must be four-digit numbers"
    exit 1
fi

if [ "$start_year" -gt "$end_year" ]; then
    echo "Error: start year must be less than or equal to end year"
    exit 1
fi

# Validate mode argument
if [ "$mode" != "1" ] && [ "$mode" != "2" ]; then
    echo "Error: mode must be 1 or 2"
    echo "Mode: 1=Year mode (yyyy), 2=Year-month mode (yyyymm)"
    exit 1
fi

# Validate compression mode
if [ "$compress_mode" != "zip" ] && [ "$compress_mode" != "nozip" ] && [ "$compress_mode" != "gzip" ]; then
    echo "Error: compression mode must be zip, nozip, or gzip"
    echo "Compression mode: nozip=no compression, zip=zip archive, gzip=gzip archive"
    exit 1
fi

if [ "$compress_mode" = "zip" ] && ! command -v zip > /dev/null 2>&1; then
    echo "Error: zip mode selected but the zip command is not available"
    exit 1
fi

# Zip archive helper
compress_with_zip() {
    local archive_path="$1"
    local target_dir="$2"

    if command -v zip > /dev/null 2>&1; then
        zip -rq "$archive_path" "$target_dir"
    else
        echo "  Error: zip command not found" >&2
        return 1
    fi
}

# Ensure target directory exists
if [ ! -d "$dir" ]; then
    echo "Error: directory '$dir' does not exist"
    exit 1
fi

echo "Starting backup for: $dir"
cd "$dir" || exit 1

# Dispatch to the requested processing mode
if [ "$mode" = "1" ]; then
    # Year mode: iterate over requested years
    for ((year=start_year; year<=end_year; year++)); do
        echo "Processing year: $year"
        archive_name=""
        if [ "$compress_mode" = "zip" ]; then
            archive_name="back_${year}.zip"
        elif [ "$compress_mode" = "gzip" ]; then
            archive_name="back_${year}.tar.gz"
        fi
        target_dir="$year"
        created_dir=0

        # Skip if an archive already exists
        if [ -n "$archive_name" ] && [ -f "$archive_name" ]; then
            echo "  $archive_name already exists; skipping."
            continue
        fi

        # Create staging directory
        if [ ! -d "$target_dir" ]; then
            mkdir "$target_dir"
            created_dir=1
            echo "  Created directory $target_dir"
        fi

        # Move matching files into staging directory
        file_count=0
        for file in *${year}*; do
            if [ -f "$file" ] && [[ "$file" != back_* ]] && { [ -z "$archive_name" ] || [ "$file" != "$archive_name" ]; }; then
                if ! mv "$file" "$target_dir/"; then
                    echo "エラー: ファイル移動に失敗しました: $file -> $target_dir/" >&2
                    exit 1
                fi
                echo "    Moved $file to $target_dir/"
                ((file_count++))
            fi
        done

        if [ $file_count -eq 0 ]; then
            echo "  No files matched year $year"
            if [ $created_dir -eq 1 ]; then
                rmdir "$target_dir"
            fi
            continue
        fi

        if [ "$compress_mode" = "zip" ]; then
            # Compress directory (move mode)
            echo "  Compressing $target_dir directory with zip..."
            if compress_with_zip "$archive_name" "$target_dir"; then
                echo "  Created $archive_name"
                rm -rf "$target_dir"
                echo "  Removed directory $target_dir"
            else
                echo "  Error: failed to compress year $year with zip"
                exit 1
            fi
        elif [ "$compress_mode" = "gzip" ]; then
            echo "  Compressing $target_dir directory with gzip..."
            if tar -czf "$archive_name" "$target_dir/"; then
                echo "  Created $archive_name"
                rm -rf "$target_dir"
                echo "  Removed directory $target_dir"
            else
                echo "  Error: failed to compress year $year with gzip"
                exit 1
            fi
        else
            echo "  Compression mode nozip; preserving directory $target_dir"
        fi
    done
elif [ "$mode" = "2" ]; then
    # Year-month mode: iterate over requested months
    for ((year=start_year; year<=end_year; year++)); do
        for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
            yearmonth=$(printf "%04d%s" "$year" "$month")
            echo "Processing year-month: $yearmonth"
            archive_name=""
            if [ "$compress_mode" = "zip" ]; then
                archive_name="back_${yearmonth}.zip"
            elif [ "$compress_mode" = "gzip" ]; then
                archive_name="back_${yearmonth}.tar.gz"
            fi
            target_dir="$yearmonth"
            created_dir=0

            # Skip if an archive already exists
            if [ -n "$archive_name" ] && [ -f "$archive_name" ]; then
                echo "  $archive_name already exists; skipping."
                continue
            fi

            # Create staging directory
            if [ ! -d "$target_dir" ]; then
                mkdir "$target_dir"
                created_dir=1
                echo "  Created directory $target_dir"
            fi

            # Move matching files into staging directory
            file_count=0
            for file in *${yearmonth}*; do
                if [ -f "$file" ] && [[ "$file" != back_* ]] && { [ -z "$archive_name" ] || [ "$file" != "$archive_name" ]; }; then
                    if ! mv "$file" "$target_dir/"; then
                        echo "エラー: ファイル移動に失敗しました: $file -> $target_dir/" >&2
                        exit 1
                    fi
                    echo "    Moved $file to $target_dir/"
                    ((file_count++))
                fi
            done

            if [ $file_count -eq 0 ]; then
                echo "  No files matched $yearmonth"
                if [ $created_dir -eq 1 ]; then
                    rmdir "$target_dir"
                fi
                continue
            fi

            if [ "$compress_mode" = "zip" ]; then
                # Compress directory (move mode)
                echo "  Compressing $target_dir directory with zip..."
                if compress_with_zip "$archive_name" "$target_dir"; then
                    echo "  Created $archive_name"
                    rm -rf "$target_dir"
                    echo "  Removed directory $target_dir"
                else
                    echo "  Error: failed to compress $yearmonth with zip"
                    exit 1
                fi
            elif [ "$compress_mode" = "gzip" ]; then
                echo "  Compressing $target_dir directory with gzip..."
                if tar -czf "$archive_name" "$target_dir/"; then
                    echo "  Created $archive_name"
                    rm -rf "$target_dir"
                    echo "  Removed directory $target_dir"
                else
                    echo "  Error: failed to compress $yearmonth with gzip"
                    exit 1
                fi
            else
                echo "  Compression mode nozip; preserving directory $target_dir"
            fi
        done
    done
fi

echo "Backup completed"
