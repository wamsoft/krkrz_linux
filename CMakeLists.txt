cmake_minimum_required(VERSION 3.20)

# 吉里吉里Z Linux 版アプリのビルド (外枠)
#
# krkrz_dev (umbrella) のトップ CMakeLists.txt と同じ手順で src/core をビルドする。
# 違いはプラグイン構成を linux-config.json の cmake セクションから取ること
# (tools/krkrz_linux.py が ${PROJECT_DIR}/build/linux/generated/myapp.cmake を生成し、
#  -DMYAPP_CMAKE_FILE=<path> で渡してくる。krkrz_android の myapp.cmake と同じ形式)。

# ※ vcpkg toolchain は最初の project() で manifest install を走らせるので、
#   project() はマニフェスト統合 (下) の後まで呼ばない (umbrella と同じ)

# 環境変数 KRKRZ_BASE に krkrz_dev のある親フォルダを指定する (krkrz_android と同じ規約)
if(NOT DEFINED KRKRZ_BASE)
    cmake_path(SET KRKRZ_BASE "$ENV{KRKRZ_BASE}")
endif()
set(KRKRZ_DEV_DIR ${KRKRZ_BASE}/krkrz_dev)
if(NOT EXISTS "${KRKRZ_DEV_DIR}/src/core/CMakeLists.txt")
    message(FATAL_ERROR "krkrz_dev not found: ${KRKRZ_DEV_DIR} (set KRKRZ_BASE)")
endif()

set(PLUGINS_DIR ${KRKRZ_DEV_DIR}/src/plugins)
set(TPSTUB_DIR ${PLUGINS_DIR}/tp_stub)
set(NCBIND_DIR ${PLUGINS_DIR}/ncbind)
set(SIMPLEBIND_DIR ${PLUGINS_DIR}/simplebinder)

# プラグイン構成 (TVP_PLUGIN_FOLDERS / TVP_PLUGINS / TVP_PLUGINS_STATIC)
if(DEFINED MYAPP_CMAKE_FILE AND EXISTS "${MYAPP_CMAKE_FILE}")
    message(STATUS "Including myapp.cmake from ${MYAPP_CMAKE_FILE}")
    include("${MYAPP_CMAKE_FILE}")
else()
    message(WARNING "MYAPP_CMAKE_FILE not given; building without plugins")
endif()

# ----------------------------------------------------
# vcpkg マニフェスト統合 (umbrella と同じ)。project() より前に行う
# ----------------------------------------------------
include(${KRKRZ_DEV_DIR}/src/core/cmake/MergeVcpkgManifest.cmake)

set(_KRKRZ_VCPKG_SUBDIRS
    "${KRKRZ_DEV_DIR}/src/core/external/movie-player"
)
foreach(_plugin IN LISTS TVP_PLUGINS)
    foreach(_folder IN LISTS TVP_PLUGIN_FOLDERS)
        if(EXISTS "${_folder}/${_plugin}")
            list(APPEND _KRKRZ_VCPKG_SUBDIRS "${_folder}/${_plugin}")
            break()
        endif()
    endforeach()
endforeach()

krkrz_merge_vcpkg_manifest(
    BASE    "${KRKRZ_DEV_DIR}/src/core/vcpkg.json"
    OUTPUT  "${CMAKE_BINARY_DIR}/vcpkg.json"
    SUBDIRS ${_KRKRZ_VCPKG_SUBDIRS}
    EXCLUDE
        "movie-player:glew"
        "movie-player:glfw3"
)
set(VCPKG_MANIFEST_DIR "${CMAKE_BINARY_DIR}" CACHE PATH
    "vcpkg manifest directory (merged manifest written by krkrz_merge_vcpkg_manifest)" FORCE)

project(krkrz_linux)

# 共通外部依存 (ICU / HarfBuzz)。TVP_PLUGINS を見るのでプラグイン定義より後
include(${KRKRZ_DEV_DIR}/cmake/CommonExternals.cmake)

option(KRKRZ_BUILD_TESTS "build SIMD parity tests" OFF)
add_subdirectory(${KRKRZ_DEV_DIR}/src/core ${CMAKE_CURRENT_BINARY_DIR}/core)
