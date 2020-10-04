#!/bin/bash

# Script to generate CA and server certificate for nginx

DIR="$(dirname "${BASH_SOURCE[0]}")"
DIR="$(realpath "${DIR}")"

# Create ssl dir
if [ ! -d "${DIR}/ssl/" ]; then
    mkdir -p ${DIR}/ssl/
fi

# Generate CA
if ! test -f "${DIR}/ssl/ca.key"; then
    openssl genrsa -out ${DIR}/ssl/ca.key 2048
fi

if ! test -f "${DIR}/ssl/ca.pem"; then
    openssl req -x509 -new -nodes -key ${DIR}/ssl/ca.key -sha256 -days 1825 -out ${DIR}/ssl/ca.pem -subj '/CN=Local CA'
fi

# Generate server certificate
openssl genrsa -out ${DIR}/ssl/star.vouchproxy.localhost.key 2048
openssl req -new -key ${DIR}/ssl/star.vouchproxy.localhost.key -out ${DIR}/ssl/star.vouchproxy.localhost.csr -subj '/CN=vouchproxy.localhost'

cat <<EOF > ${DIR}/ssl/star.vouchproxy.localhost.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vouchproxy.localhost
DNS.2 = *.vouchproxy.localhost
EOF

openssl x509 -req -in ${DIR}/ssl/star.vouchproxy.localhost.csr -CA ${DIR}/ssl/ca.pem -CAkey ${DIR}/ssl/ca.key -CAcreateserial -out ${DIR}/ssl/star.vouchproxy.localhost.crt -days 825 -sha256 -extfile ${DIR}/ssl/star.vouchproxy.localhost.ext

echo ""
echo "Trust CA on MacOS using:"
echo "sudo security add-trusted-cert -d -r trustRoot -k \"/Library/Keychains/System.keychain\" ${DIR}/ssl/ca.pem"
echo ""

echo ""
echo "Add podinfo to your hosts-file:"
echo "echo 127.0.0.1 podinfo.vouchproxy.localhost >> /etc/hosts"
echo ""

echo ""
echo "Browse podinfo here: https://podinfo.vouchproxy.localhost:8443/"
echo ""