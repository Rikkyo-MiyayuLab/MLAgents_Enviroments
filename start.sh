#!/bin/bash

# === 1. 設定ファイルを読み込む（連想配列を使わずリスト管理） ===
MLAGENTS_OPTIONS=()
MLAGENTS_VERSIONS=()
index=1

while IFS='=' read -r key value; do
    if [[ "$key" =~ ^release[0-9]+$ ]]; then
        MLAGENTS_OPTIONS+=("$index) $key (ML-Agents $value)")
        MLAGENTS_VERSIONS+=("$key:$value")
        ((index++))
    fi
done < mlagents_versions.conf

# === 2. ML-Agentsのバージョンを選択（手入力） ===
echo "💡 使用する ML-Agents のバージョンを選択してください:"
for option in "${MLAGENTS_OPTIONS[@]}"; do
    echo "$option"
done

read -p "番号を入力してください [1-${#MLAGENTS_VERSIONS[@]}]: " mlagents_choice

# ユーザーが選んだ番号に対応するリリース番号とバージョンを取得
if [[ "$mlagents_choice" =~ ^[0-9]+$ ]] && ((mlagents_choice >= 1 && mlagents_choice <= ${#MLAGENTS_VERSIONS[@]})); then
    selected_entry="${MLAGENTS_VERSIONS[$((mlagents_choice-1))]}"
    MLAGENTS_RELEASE="${selected_entry%%:*}"
    MLAGENTS_VERSION="${selected_entry##*:}"
else
    echo "❌ 無効な入力です。デフォルトで release22 (ML-Agents 0.30.0) を使用します。"
    MLAGENTS_RELEASE="release22"
    MLAGENTS_VERSION="0.30.0"
fi

# === 3. CUDA環境の利用可否を選択（手入力） ===
read -p "🔧 CUDA を利用しますか？ (y/n): " use_cuda
if [[ "$use_cuda" == "y" ]]; then
    USE_CUDA=true
    read -p "🛠 使用する CUDA バージョンを入力してください (例: 11.8): " CUDA_VERSION

    if ! command -v nvidia-smi &> /dev/null; then
        read -p "⚠️ CUDA がインストールされていません。インストールしますか？ (y/n): " install_cuda
        if [[ "$install_cuda" == "y" ]]; then
            echo "📥 CUDA ${CUDA_VERSION} をインストールします..."
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
        else
            echo "❌ CUDA 環境がないため、CPU環境で構築します。"
            USE_CUDA=false
        fi
    else
        echo "✅ CUDA はインストール済みです！"
    fi
else
    USE_CUDA=false
fi

# === 4. 環境情報の表示と確認（手入力） ===
echo ""
echo "🛠 環境構成の確認:"
echo "----------------------------------"
echo "💡 ML-Agents Release : ${MLAGENTS_RELEASE}"
echo "🎯 ML-Agents Version : ${MLAGENTS_VERSION}"
echo "🐍 Python Version    : $(python3 --version)"
echo "📦 Installed Packages:"
pip list | grep -E "mlagents|torch"
if [[ "$USE_CUDA" == "true" ]]; then
    echo "🚀 CUDA Enabled      : Yes (Version: ${CUDA_VERSION})"
else
    echo "🚀 CUDA Enabled      : No (CPU only)"
fi
echo "----------------------------------"

read -p "⚠️ この設定でコンテナをビルドしてよろしいですか？ (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "🚫 キャンセルしました。"
    exit 1
fi

# === 5. Dockerコンテナをビルド & 起動 ===
echo "🚀 Dockerコンテナをビルド & 起動します..."
docker-compose up --build -d

echo "✅ コンテナが起動しました。コンテナに入るには以下を実行してください:"
echo "   docker exec -it unity-env /bin/bash"
