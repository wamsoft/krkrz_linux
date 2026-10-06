# krkrz_linux — tools/krkrz_linux.py の薄いラッパー
#
#   make all        # build + stage + package (sniper コンテナでビルド)
#   make build      # configure/build/install
#   make stage      # パッケージフォルダの組み立て
#   make package    # tar.gz 化
#   make native     # コンテナを使わずこのマシンでビルド (参考ビルド)
#   make clean
#
# 案件フォルダは環境変数 PROJECT_DIR (未設定ならこのリポジトリ = サンプル案件)。
# KRKRZ_BASE (krkrz_dev の親フォルダ) が必要。

PYTHON ?= python3
TOOL := $(PYTHON) $(dir $(abspath $(lastword $(MAKEFILE_LIST))))tools/krkrz_linux.py

.PHONY: all build stage package native clean gen

all:
	$(TOOL) all

build:
	$(TOOL) build

stage:
	$(TOOL) stage

package:
	$(TOOL) package

native:
	$(TOOL) all --native

gen:
	$(TOOL) gen

clean:
	$(TOOL) clean
