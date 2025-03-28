# === 1. CUDA のバージョンを指定（デフォルトは 11.8） ===
ARG CUDA_VERSION=11.8.0
ARG USE_CUDA=false
ARG MLAGENTS_VERSION=0.30.0

# === 2. CUDA を使う場合、NVIDIA の CUDA ベースイメージを使用 ===
# 使わない場合は通常の Ubuntu を使用
# `--build-arg USE_CUDA=true` の場合、CUDA ベースイメージを使用
FROM ubuntu:20.04 as cpu_base
FROM nvidia/cuda:${CUDA_VERSION}-base-ubuntu20.04 as cuda_base

# === 3. `USE_CUDA` に応じてベースイメージを選択 ===
# `--build-arg USE_CUDA=true` の場合は `cuda_base` を使用
# それ以外は `cpu_base` を使用
ARG FINAL_IMAGE=cpu_base
FROM ${USE_CUDA:+cuda_base} as FINAL_IMAGE
FROM FINAL_IMAGE

# === 4. 必要なパッケージをインストール ===
RUN apt-get update && apt-get install -y \
    python3 python3-pip git wget unzip \
    && rm -rf /var/lib/apt/lists/*

# === 5. Python 環境をセットアップ ===
RUN pip3 install --upgrade pip setuptools \
    && pip3 install mlagents==$MLAGENTS_VERSION \
    && pip3 freeze > /opt/requirements.txt

# === 6. 環境変数を設定 ===
ENV PYTHONUNBUFFERED=1
WORKDIR /unity-project

# === 7. デフォルトのコマンドを指定（コンテナ内で bash を実行） ===
CMD ["/bin/bash"]
