#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
if [[ "$PWD" == "$DIR" ]]; then
  echo "This script should not be run from scripts. It should be run in the base of the mtls chart"
  exit 1
fi

prompt_continue() {
  read -rp 'Create another intermediate certificate? (y/N) ' CREATE
  if [[ "${CREATE}" == "y" ]]; then
    query
  fi
}

query() {
  if [[ -z "${CN}" ]]; then
    read -rp 'What is the common name for this? (ie. My Intermediate CA): ' CN
  fi
  echo "Creating Intermediate Certificate Output Folders For ${CN}..."
  NORMALIZED_CN=$(echo "${CN}" | tr -d '[:space:][:punct:]')
  echo "${NORMALIZED_CN}"
  mkdir -p "output/ca/intermediate/${NORMALIZED_CN}/certs" \
    "output/ca/intermediate/${NORMALIZED_CN}/crl" \
    "output/ca/intermediate/${NORMALIZED_CN}/newcerts" \
    "output/ca/intermediate/${NORMALIZED_CN}/private" \
    "output/ca/intermediate/${NORMALIZED_CN}/csr"
  touch "output/ca/intermediate/${NORMALIZED_CN}/index.txt"
  echo 1000 > "output/ca/intermediate/${NORMALIZED_CN}/serial"
  cp "${DIR}/intermediate.cnf" "output/ca/intermediate/${NORMALIZED_CN}/openssl.cnf"
  sed -i "s|^dir = /root/ca|dir = ${PWD}/output/intermediate/${NORMALIZED_CN}|g" \
    "output/ca/intermediate/${NORMALIZED_CN}/openssl.cnf"
  gen_key "${NORMALIZED_CN}"
  if [[ -z "$SUBJ" ]]; then
    if [[ -z "$C" ]]; then
      read -rp 'COUNTRY: ' C
    fi
    if [[ -z "$ST" ]]; then
      read -rp 'State/Province: ' ST
    fi
    if [[ -z "$L" ]]; then
      read -rp 'Locality: ' L
    fi
    if [[ -z "$O" ]]; then
      read -rp 'Organization Name: ' O
    fi
    if [[ -z "$OU" ]]; then
      read -rp 'Organizational Unit: ' OU
    fi
    if [[ -z "$CN" ]]; then
      read -rp 'Common Name: ' CN
    fi
    SUBJ="/CN=$CN/O=$O/OU=$OU/C=$C/ST=$ST/L=$L"
  fi
  echo "Generating Intermediate CA Certificate CSR for ${CN}..."
  openssl req -config "output/ca/intermediate/${NORMALIZED_CN}/openssl.cnf" \
    -new -sha256 \
    -subj "${SUBJ}" \
    -key "output/ca/intermediate/${NORMALIZED_CN}/private/${NORMALIZED_CN}.key.pem" \
    -out "output/ca/intermediate/${NORMALIZED_CN}/csr/${NORMALIZED_CN}.csr.pem"

  echo "Generating Intermediate CA Certificate for ${NORMALIZED_CN}..."
  openssl ca -config output/ca/openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in "output/ca/intermediate/${NORMALIZED_CN}/csr/${NORMALIZED_CN}.csr.pem" \
    -out "output/ca/intermediate/${NORMALIZED_CN}/certs/${NORMALIZED_CN}.cert.pem"

  echo "Creating ca-chain..."
  cat "output/ca/intermediate/${NORMALIZED_CN}/certs/${NORMALIZED_CN}.cert.pem" \
    output/ca/certs/ca.cert.pem > \
    "output/ca/intermediate/${NORMALIZED_CN}/certs/ca-chain.cert.pem"

  # Clear out the values
  NORMALIZED_CN=""
  SUBJ=""
  CN=""
  # Unset the values
  unset $NORMALIZED_CN
  unset $SUBJ
  unset $CN
  prompt_continue
}

gen_key() {
  local NORMALIZED_CN=$1
  echo "Generating 4096 RSA Key..."
  EXTRA=""
  if [[ $WITHPASSWORD ]]; then
    EXTRA="-aes256"
  fi
  openssl \
    genrsa \
    $EXTRA  \
    -out "output/ca/intermediate/${NORMALIZED_CN}/private/${NORMALIZED_CN}.key.pem" \
    4096
}

query
