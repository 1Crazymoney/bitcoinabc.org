#!/usr/bin/env bash

set -euxo pipefail

# Github repository parameters
GITHUB_OWNER='Bitcoin-ABC'
GITHUB_REPO='bitcoin-abc'

# Max number of release versions to display
MAX_RELEASES=15

# Min version for rpc docs generation
MIN_VERSION_RPC_DOCS='0.22.1'

# Min version for man pages generation
MIN_VERSION_MAN_PAGES='0.22.1'


SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
TOPLEVEL=$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)

# Get the last MAX_RELEASES releases
RELEASES=$(curl -L -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases?per_page=${MAX_RELEASES})

# Extract releases version number 
RELEASE_VERSIONS=($(echo ${RELEASES} | jq -r .[].name))

# Extract releases version number 
RELEASE_TAGS=($(echo ${RELEASES} | jq -r .[].tag_name))

# Create the cache directory as needed. This is where the sources will be
# cloned, and where the docs will be built.
: "${CACHE_DIR:=${TOPLEVEL}/.user-doc-cache}"
mkdir -p "${CACHE_DIR}"

SRC_DIR="${CACHE_DIR}/${GITHUB_REPO}"
if [ ! -d "${SRC_DIR}" ]
then
  git clone "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}.git" "${SRC_DIR}"
fi

pushd "${SRC_DIR}"
git pull --tags origin master
popd

version_greater_equal()
{
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

for i in "${!RELEASE_VERSIONS[@]}"
do
  VERSION="${RELEASE_VERSIONS[$i]}"
  TAG="${RELEASE_TAGS[$i]}"

  if version_greater_equal "${VERSION}" "${MIN_VERSION_RPC_DOCS}"
  then
    BUILD_RPC_DOCS="yes"
  else
    BUILD_RPC_DOCS="no"
  fi

  if version_greater_equal "${VERSION}" "${MIN_VERSION_MAN_PAGES}"
  then
    BUILD_MAN_PAGES="yes"
  else
    BUILD_MAN_PAGES="no"
  fi

  if [ "${BUILD_RPC_DOCS}" = "no" ] && [ "${BUILD_MAN_PAGES}" = "no" ]
  then
    continue
  fi

  # Checkout the release tag
  pushd "${SRC_DIR}"
  git checkout "tags/${TAG}"
  popd

  # Prepare some directories
  WEBSITE_DIR="${TOPLEVEL}/_doc/${VERSION}"
  mkdir -p "${WEBSITE_DIR}"

  VERSION_DIR="${CACHE_DIR}/${VERSION}"
  mkdir -p "${VERSION_DIR}"

  BUILD_DIR="${SRC_DIR}/build_${VERSION}"
  mkdir -p "${BUILD_DIR}"

  INSTALL_DIR="${BUILD_DIR}/install"
  mkdir -p "${INSTALL_DIR}"

  pushd "${BUILD_DIR}"

  if [ "${BUILD_RPC_DOCS}" = "yes" ] && [ ! -d "${VERSION_DIR}/rpc" ]
  then
    # Build and install the release version
    cmake -GNinja "${SRC_DIR}" -DCLIENT_VERSION_IS_RELEASE=ON -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
    ninja install/strip

    BITCOIND_PID_FILE="${VERSION_DIR}/bitcoind_${VERSION}.pid"
    "${INSTALL_DIR}"/bin/bitcoind -regtest -daemon -pid="${BITCOIND_PID_FILE}"

    PID_WAIT_COUNT=0
    while [ ! -e "${BITCOIND_PID_FILE}" ]
    do
      ((PID_WAIT_COUNT+=1))
      if [ "${PID_WAIT_COUNT}" -gt 10 ]
      then
        echo "Timed out waiting for bitcoind PID file"
        exit 1
      fi
      sleep 0.5
    done
    BITCOIND_PID=$(cat "${BITCOIND_PID_FILE}")

    ninja doc-rpc

    kill "${BITCOIND_PID}"

    # Cache the result
    cp -R "${BUILD_DIR}/doc/rpc/en/${VERSION}/rpc" "${VERSION_DIR}/"
  fi

  if [ "${BUILD_MAN_PAGES}" = "yes" ] && [ ! -d "${VERSION_DIR}/man" ]
  then
    # Build and install the man pages
    cmake -GNinja "${SRC_DIR}" -DCLIENT_VERSION_IS_RELEASE=ON -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
    ninja install-manpages-html
    mkdir -p "${VERSION_DIR}/man"
    # Cache the result
    cp "${INSTALL_DIR}"/share/man/html/* "${VERSION_DIR}/man/"
  fi

  popd

  # Copy everything from the cache to the website directory
  cp -R "${VERSION_DIR}"/* "${WEBSITE_DIR}/"

done
