#!/bin/bash

set -e

echo "System information:"
uname -a
cat /etc/os-release

echo "Contents of /keys:"
ls -l /keys

echo "Contents of /config:"
ls -l /config

echo "Contents of acra-server.yaml:"
cat /config/acra-server.yaml

echo "Setting up KMS encrypted master key..."
export ACRA_MASTER_KEY=$(tr -d '\0' < /keys/encrypted_master_key)
echo $ACRA_MASTER_KEY

echo "Starting Acra server..."

# Start acra-server with full path and error handling
if ! /usr/bin/acra-server -v -d --config_file=/config/acra-server.yaml --keys_dir=/keys --keystore_encryption_type=kms_encrypted_master_key; then
    echo "Failed to start acra-server. Check the error message above."
    echo "Acra server binary location:"
    which acra-server || echo "acra-server not found in PATH"
    echo "Acra server binary permissions:"
    ls -l $(which acra-server) || echo "Unable to find acra-server binary"
    exit 1
fi