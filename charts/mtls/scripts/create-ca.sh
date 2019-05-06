#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
if [[ "$PWD" == "$DIR" ]]; then
  echo "This script should not be run from scripts. It should be run in the base of the mtls chart"
  exit 1
fi

echo "Creating Root Certificate Output Folders..."
mkdir -p output/ca/certs \
  output/ca/crl \
  output/ca/newcerts \
  output/ca/private \
  output/ca/csr
chmod 700 output/ca/private
touch output/ca/index.txt
echo 1000 > output/ca/serial
cp "${DIR}/ca.cnf" output/ca/openssl.cnf
sed -i "s|^dir = /root/ca|dir = ${PWD}/output/ca|g" output/ca/openssl.cnf

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

echo "Generating Root CA RSA Key..."
EXTRA=""
if [[ $WITHPASSWORD ]]; then
  EXTRA="-aes256"
fi
openssl \
  genrsa \
  $EXTRA  \
  -out output/ca/private/ca.key.pem 4096

echo "Generating Root CA Certificate..."
openssl req -config output/ca/openssl.cnf \
  -subj "$SUBJ" \
  -key output/ca/private/ca.key.pem \
  -new -x509 -days 7300 -sha256 -extensions v3_ca \
  -out output/ca/certs/ca.cert.pem

# Clear some items to run intermediate
SUBJ=""
CN=""
unset $SUBJ
unset $CN
read -rp 'Create an intermediate certificate? (y/N) ' CREATE
if [[ "${CREATE}" == "y" ]]; then
  # shellcheck disable=SC1091
  source "./scripts/create-intermediate.sh"
fi
