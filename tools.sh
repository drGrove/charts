#!/bin/bash
set -eo pipefail

helm_version="2.14.3"
declare -A helm_hashes=(
  ["linux"]="38614a665859c0f01c9c1d84fa9a5027364f936814d1e47839b05327e400bf55"
  ["darwin"]="3f907cac93c6b18c36910b15af02ddc3d454b59a870899afdfa75548f9a7658d"
)

[[ "${OSTYPE}" =~ "linux" ]] && os=linux
[[ "${OSTYPE}" =~ "darwin" ]] && os=darwin

[ -z "${os}" ] && echo "${OSTYPE}" is not supported && exit

function sha256() {
  openssl sha256 "$@" | awk '{print $2}'
}

helm_host="https://storage.googleapis.com/kubernetes-helm"
helm_path="helm-v${helm_version}-${os}-amd64.tar.gz"
helm_url="${helm_host}/${helm_path}"
tiller_file="tiller-${os}-amd64-${helm_version}"
helm_file="helm-${os}-amd64-${helm_version}"
helm_archive="${helm_file}.tar.gz"
helm_archive_path="${os}-amd64"

dir=$(dirname "${BASH_SOURCE[0]}")
temp_dir="${dir}/.tmp"
download_dir="${temp_dir}/downloads"
release_dir="${temp_dir}/releases"
bin_dir="${temp_dir}/bin"

# Make Temp dirs
mkdir -p "${download_dir}" "${release_dir}" "${bin_dir}"

if [ ! -f "${release_dir}/${helm_file}" ]; then
  wget "${helm_url}" -O "${download_dir}/${helm_archive}"
  helm_hash=$(sha256 "${download_dir}/${helm_archive}")
  [[ "${helm_hashes[${os}]}" == "${helm_hash}" ]] || {
    ( >&2 echo "Invalid hash for ${helm_archive}"; exit 1; )
  }
  temp_dir=$(mktemp -d)
  tar xvf "${download_dir}/${helm_archive}" -C "${temp_dir}"
  mv "${temp_dir}/${helm_archive_path}/helm" "${release_dir}/${helm_file}"
  mv "${temp_dir}/${helm_archive_path}/tiller" "${release_dir}/${tiller_file}"
  ln -s "${PWD}/${release_dir}/${helm_file}" "${bin_dir}/helm"
  ln -s "${PWD}/${release_dir}/${tiller_file}" "${bin_dir}/tiller"
  chmod +x "${bin_dir}/helm"
  chmod +x "${bin_dir}/tiller"
fi

echo "Adding to path"
export PATH="${PWD}/${bin_dir}:${PATH}"
