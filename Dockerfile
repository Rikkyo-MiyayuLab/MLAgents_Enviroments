# ユーザーのOSに応じたベースイメージを設定
ARG BASE_OS
FROM ${BASE_OS}

# CUDA対応（オプション）
ARG USE_CUDA=false
ARG CUDA_VERSION=11.8.0
RUN if [ "$USE_CUDA" = "true" ]; then \
        echo "Using CUDA ${CUDA_VERSION}"; \
        apt-get update && apt-get install -y --no-install-recommends \
        cuda-toolkit-${CUDA_VERSION}; \
    fi

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    python3 python3-pip git wget unzip \
    xvfb libxi6 libgconf-2-4 libxrandr2 libxrender1 \
    libxss1 libxcursor1 \
    && rm -rf /var/lib/apt/lists/*

# Pythonのバージョン情報を保持
RUN python3 --version > /opt/python_version.txt

# ML-Agentsのインストール（バージョンを指定可能）
ARG MLAGENTS_VERSION=1.1.0
RUN pip3 install --upgrade pip setuptools \
    && pip3 install mlagents==$MLAGENTS_VERSION \
    && pip3 freeze > /opt/requirements.txt

# コンテナ内でプロジェクト作成可能にするためVOLUMEを設定
VOLUME [ "/unity-project" ]
WORKDIR /unity-project

# デフォルトのコマンド
CMD ["bash"]
