# backup.sh Linux実行手順

## 事前準備

### 1. backup.shをLinuxサーバにアップロード
```bash
# SCPでアップロード（例）
scp backup.sh user@server:/path/to/destination/

# または、サーバ上で直接作成・編集
vi backup.sh
# ファイル内容をコピー&ペースト
```

### 2. 実行権限の付与
```bash
chmod +x backup.sh
```

## 実行手順

### 1. バックアップ対象フォルダの確認
```bash
# フォルダが存在することを確認
ls -la /path/to/backup/folder

# フォルダ内のファイル確認（年パターンのファイルがあるか）
ls -la /path/to/backup/folder/*2010*
ls -la /path/to/backup/folder/*2020*
ls -la /path/to/backup/folder/*2024*
# 2010年から2024年までのファイルの存在確認
```

### 2. バックアップスクリプト実行
```bash
# スクリプト実行
./backup.sh /path/to/backup/folder

# バックグラウンド実行する場合
nohup ./backup.sh /path/to/backup/folder > backup.log 2>&1 &

# 進捗確認（バックグラウンド実行時）
tail -f backup.log
```

### 3. 実行結果確認
```bash
# バックアップ先フォルダの確認
ls -la /path/to/backup/folder/

# zipファイルの確認
ls -la /path/to/backup/folder/*.zip

# zipファイルの内容確認
unzip -l /path/to/backup/folder/back_2010.zip
unzip -l /path/to/backup/folder/back_2024.zip
```

## 注意事項

- **実行前にバックアップ対象フォルダのバックアップを取ることを推奨**
- **十分なディスク容量があることを確認**
- **実行権限とファイル操作権限があることを確認**
- **年パターン（2010-2024）以外のファイルは移動されません**
- **作成されるzipファイル名は「back_年.zip」形式です**

## エラー対処

### zipコマンドが見つからない場合
```bash
# エラーメッセージ例: "zip: command not found"
# zipパッケージをインストール
# Ubuntu/Debian系
sudo apt update
sudo apt install zip

# CentOS/RHEL系
sudo yum install zip
# または
sudo dnf install zip
```

### 権限エラーの場合
```bash
# 実行権限エラー
chmod +x backup.sh

# ファイル操作権限エラー
# フォルダの所有者・権限を確認
ls -la /path/to/backup/folder
# 必要に応じて権限変更
sudo chown user:group /path/to/backup/folder
```

### ディスク容量不足の場合
```bash
# ディスク使用量確認
df -h
du -sh /path/to/backup/folder
```