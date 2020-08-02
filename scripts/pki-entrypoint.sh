#!/bin/sh
# v0.2.0
# Copyright (c) 2020, Aaron Blair
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

# CA Common
CA_DOMAIN="${CA_DOMAIN:-example.com}"
export CA_PKI_DOMAIN="${CA_PKI_DOMAIN:-app-hsmocsp}"
CA_ORG="${CA_ORG:-Example Inc.}"
export CA_ORG_ABBR="${CA_ORG_ABBR:-Example}"
CA_ORG_UNIT="${CA_ORG_UNIT:-IT Department}"
CA_COUNTRY="${CA_COUNTRY:-US}"
CA_STATE="${CA_STATE:-New York}"
CA_LOCALITY="${CA_LOCALITY:-New York}"

## K8S
K8S_APISERVER="${K8S_APISERVER:-https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT}" # $KUBERNETES_SERVICE_PORT

# Default K8S Token for Roles
K8S_SA_JWT_TOKEN="${K8S_SA_JWT_TOKEN:-$(cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null)}"
K8S_SA_JWT_TOKEN_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${K8S_SA_JWT_TOKEN})
K8S_SA="${K8S_SA:-$(echo $K8S_SA_JWT_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/service-account.name" // "default"')}"
K8S_SA_NAMESPACE="${K8S_SA_NAMESPACE:-$(echo $K8S_SA_JWT_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/namespace" // "default"')}"

# Token Reviewer
K8S_TOKEN_REVIEWER_JWT="${K8S_TOKEN_REVIEWER_JWT:-$K8S_SA_JWT_TOKEN}"
K8S_TOKEN_REVIEWER_JWT_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${K8S_TOKEN_REVIEWER_JWT})

K8S_CACERT="${K8S_CACERT:-/var/run/secrets/kubernetes.io/serviceaccount/ca.crt}"
K8S_CA_CRT="${K8S_CA_CRT:-$(cat ${K8S_CACERT} 2>/dev/null)}"

## softhsm2
SOFTHSM2_DIR="${SOFTHSM2_DIR:-/app/.config/softhsm2}"
SOFTHSM2_CONF="${SOFTHSM2_CONF:-$SOFTHSM2_DIR/softhsm2.conf}"

## HSM
VALIDATE_HSM="${VALIDATE_HSM:-true}"

INIT_HSM="${INIT_HSM:-true}"
INIT_HSM_TOKEN="${INIT_HSM_TOKEN:-true}"

## Not defining HSM_MODULE will initialize SoftHSM for development purposes
# HSM_MODULE="/usr/lib64/pkcs11/opensc-pkcs11.so"
# HSM_MODULE="/usr/lib64/pkcs11/libsofthsm2.so"
# HSM_SLOTID="${HSM_SLOTID:-}"
HSM_TOKENLABEL="${HSM_TOKENLABEL:-pki-hsm}"
HSM_SOPIN="${HSM_SOPIN:-0123456789abcdef}"
export HSM_PIN="${HSM_PIN:-spyd3rweb}"

# CA
HSM_CA_KEYLABEL="${HSM_CA_KEYLABEL:-ca-keypair}"
HSM_CA_KEYID="${HSM_CA_KEYID:-1234}"
export HSM_CA_PKCS11_URI="${HSM_CA_PKCS11_URI:-pkcs11:token=$HSM_TOKENLABEL;object=$HSM_CA_KEYLABEL;pin-value=$HSM_PIN}"
HSM_CA_PKCS11_URI_SAFE=`echo ${HSM_CA_PKCS11_URI} | awk '{ sub(/pin-value=\w+/, ""); print }'`

# OCSP
HSM_OCSP_KEYID="${HSM_OCSP_KEYID:-5678}"
HSM_OCSP_KEYLABEL="${HSM_OCSP_KEYLABEL:-ocsp-keypair}"
HSM_OCSP_PKCS11_URI="${HSM_OCSP_PKCS11_URI:-pkcs11:token=$HSM_TOKENLABEL;object=$HSM_OCSP_KEYLABEL;pin-value=$HSM_PIN}"
HSM_OCSP_PKCS11_URI_SAFE=`echo ${HSM_OCSP_PKCS11_URI} | awk '{ sub(/pin-value=\w+/, ""); print }'`

# INT
HSM_INT_KEYID="${HSM_INT_KEYID:-9876}"
HSM_INT_KEYLABEL="${HSM_INT_KEYLABEL:-int-keypair}"
HSM_INT_PKCS11_URI="${HSM_INT_PKCS11_URI:-pkcs11:token=$HSM_TOKENLABEL;object=$HSM_INT_KEYLABEL;pin-value=$HSM_PIN}"
HSM_INT_PKCS11_URI_SAFE=`echo ${HSM_INT_PKCS11_URI} | awk '{ sub(/pin-value=\w+/, ""); print }'`

## OpenSSL CA (Level 1)
VALIDATE_OPENSSL_CA="${VALIDATE_OPENSSL_CA:-true}"

INIT_OPENSSL_CA="${INIT_OPENSSL_CA:-true}"

export OPENSSL_CA_DIR="${OPENSSL_CA_DIR:-/app/.config/pki}"
export OPENSSL_CA_CONF="${OPENSSL_CA_CONF:-$OPENSSL_CA_DIR/ca.conf}"
export OPENSSL_CA_CERTINDEX="${OPENSSL_CA_CERTINDEX:-$OPENSSL_CA_DIR/certindex}"
export OPENSSL_CA_CERTSERIAL="${OPENSSL_CA_CERTSERIAL:-$OPENSSL_CA_DIR/certserial}"
export OPENSSL_CA_CRLNUMBER="${OPENSSL_CA_CRLNUMBER:-$OPENSSL_CA_DIR/crlnumber}"
export OPENSSL_CA_NEW_CERTS_DIR="${OPENSSL_CA_NEW_CERTS_DIR:-$OPENSSL_CA_DIR/certs}"
export OPENSSL_PKCS11_ENGINE="${OPENSSL_PKCS11_ENGINE:-/usr/lib64/engines-1.1/pkcs11.so}"

export OPENSSL_CA_PEM="${OPENSSL_CA_PEM:-$OPENSSL_CA_DIR/ca.cert.pem}"
export OPENSSL_CA_URL="${OPENSSL_CA_URL:-http://$CA_PKI_DOMAIN/ca}"

# CRL
export OPENSSL_CA_CRL_DIR="${OPENSSL_CA_CRL_DIR:-$OPENSSL_CA_DIR/crl}"
export OPENSSL_CA_CRL_PEM="${OPENSSL_CA_CRL_PEM:-$OPENSSL_CA_CRL_DIR/ca.crl.pem}"
export OPENSSL_CA_CRL_CHAIN_PEM="${OPENSSL_CA_CRL_CHAIN_PEM:-$OPENSSL_CA_DIR/ca.crl_chain.pem}"
export OPENSSL_CA_CRL_URL="${OPENSSL_CA_CRL_URL:-http://$CA_PKI_DOMAIN/crl}"

# OpenSSL OCSP
INIT_OPENSSL_CA_OCSP="${INIT_OPENSSL_CA_OCSP:-true}"

OPENSSL_CA_OCSP_PEM="${OPENSSL_CA_OCSP_PEM:-$OPENSSL_CA_DIR/ocsp.cert.pem}"
OPENSSL_CA_OCSP_CSR="${OPENSSL_CA_OCSP_CSR:-$OPENSSL_CA_DIR/ocsp.cert.csr}"
export OPENSSL_CA_OCSP_URL="${OPENSSL_CA_OCSP_URL:-http://$CA_PKI_DOMAIN/ocsp}"

## OpenSSL Intermediate (Level 2)
VALIDATE_OPENSSL_INT="${VALIDATE_OPENSSL_INT:-true}"

TEST_OPENSSL_REVOKE="${TEST_OPENSSL_REVOKE:-true}"

INIT_OPENSSL_INT="${INIT_OPENSSL_INT:-true}"

OPENSSL_INT_PEM="${OPENSSL_INT_PEM:-$OPENSSL_CA_DIR/int.cert.pem}"
OPENSSL_INT_CSR="${OPENSSL_INT_CSR:-$OPENSSL_CA_DIR/int.cert.csr}"

## Vault
# Server
VALIDATE_VAULT_SERVER="${VALIDATE_VAULT_SERVER:-true}"
INIT_VAULT_DEV="${INIT_VAULT_DEV:-true}"

export VAULT_ADDR=${VAULT_ADDR:-http://127.0.0.1:8200}
export VAULT_CONFIG_DIR="${VAULT_CONFIG_DIR:-/app/.config/vault/config}"

# Agent
VALIDATE_VAULT_AGENT="${VALIDATE_VAULT_AGENT:-false}"
INIT_VAULT_AGENT="${INIT_VAULT_AGENT:-true}"

# CLI
export VAULT_FORMAT="json"
export VAULT_LOG_LEVEL="${VAULT_LOG_LEVEL:-debug}"

# K8S Auth
VALIDATE_VAULT_K8S_AUTH="${VALIDATE_VAULT_K8S_AUTH:-true}"

# K8S Admin auth
VALIDATE_VAULT_ADMIN_K8S_AUTH="${VALIDATE_VAULT_ADMIN_K8S_AUTH:-true}"
INIT_VAULT_ADMIN_K8S_AUTH="${INIT_VAULT_ADMIN_K8S_AUTH:-true}"

VAULT_ADMIN_ROLE="${VAULT_ADMIN_ROLE:-admin}"
VAULT_ADMIN_POLICY="${VAULT_ADMIN_POLICY:-$VAULT_CONFIG_DIR/$VAULT_ADMIN_ROLE-policy.hcl}"
VAULT_ADMIN_SA_TOKEN="${VAULT_ADMIN_SA_TOKEN:-$K8S_SA_JWT_TOKEN}"
VAULT_ADMIN_SA_TOKEN_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${VAULT_ADMIN_SA_TOKEN})
VAULT_ADMIN_SA="${VAULT_ADMIN_SA:-$(echo $VAULT_ADMIN_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/service-account.name" // "default"')}"
VAULT_ADMIN_SA_NAMESPACE="${VAULT_ADMIN_SA_NAMESPACE:-$(echo $VAULT_ADMIN_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/namespace" // "default"')}"
VAULT_ADMIN_SA_TTL="${VAULT_ADMIN_SA_TTL:-20m}"

## Vault Root CA (Level 2)
VALIDATE_VAULT_ROOT_CA="${VALIDATE_VAULT_ROOT_CA:-true}"

INIT_VAULT_ROOT_CA="${INIT_VAULT_ROOT_CA:-true}"

VAULT_ROOT_CA_PATH="${VAULT_ROOT_CA_PATH:-pki}"
VAULT_ROOT_CA_ORG="${VAULT_ROOT_CA_ORG:-$CA_ORG}"
VAULT_ROOT_CA_OU="${VAULT_ROOT_CA_OU:-$CA_ORG_UNIT}"
VAULT_ROOT_CA_DOMAIN="${VAULT_ROOT_CA_DOMAIN:-$CA_DOMAIN}"
VAULT_ROOT_CA_URL="${VAULT_ROOT_CA_URL:-$VAULT_ADDR/v1/$VAULT_ROOT_CA_PATH/ca}"

VAULT_ROOT_CA_CN="${VAULT_ROOT_CA_CN:-$CA_ORG_ABBR Intermediate CA 1}"
VAULT_ROOT_CA_CSR="${VAULT_ROOT_CA_CSR:-$OPENSSL_CA_DIR/ca.$VAULT_ROOT_CA_PATH.cert.csr}"
VAULT_ROOT_CA_PEM="${VAULT_ROOT_CA_PEM:-$OPENSSL_CA_DIR/ca.$VAULT_ROOT_CA_PATH.cert.pem}"
VAULT_ROOT_CA_TTL="${VAULT_ROOT_TTL:-43800h}" # 5 years
VAULT_ROOT_CA_SELF_SIGN="${VAULT_ROOT_CA_SELF_SIGNED:-false}" # recommend setting to false and using external CA

# CRL
VAULT_ROOT_CA_CRL_PEM="${VAULT_ROOT_CA_CRL_PEM:-$OPENSSL_CA_DIR/crl/ca.$VAULT_ROOT_CA_PATH.crl.pem}"
VAULT_ROOT_CA_CRL_CHAIN_PEM="${VAULT_ROOT_CA_CRL_CHAIN_PEM:-$OPENSSL_CA_DIR/ca.$VAULT_ROOT_CA_PATH.crl_chain.pem}"
VAULT_ROOT_CA_CRL_URL="${VAULT_ROOT_CA_CRL_URL:-$VAULT_ADDR/v1/$VAULT_ROOT_CA_PATH/crl}"

# INTR Role
VAULT_ROOT_CA_INTR_ROLE="${VAULT_ROOT_CA_INTR_ROLE:-ca-$(echo $VAULT_ROOT_CA_DOMAIN | sed s/[.]/-dot-/g)}"
VAULT_ROOT_CA_INTR_TTL="${VAULT_ROOT_CA_INTR_TTL:-8760h}" # 1 year

# OCSP Role
VAULT_ROOT_CA_OCSP_ROLE="${VAULT_ROOT_CA_OCSP_ROLE:-ocsp-$(echo $VAULT_ROOT_CA_DOMAIN | sed s/[.]/-dot-/g)}"
VAULT_ROOT_CA_OCSP_TTL="${VAULT_ROOT_CA_OCSP_TTL:-43799h}" # 5 years
VAULT_ROOT_CA_OCSP_URL="${VAULT_ROOT_CA_OCSP_URL:-http://$CA_PKI_DOMAIN/$VAULT_ROOT_CA_PATH/ocsp}"

# OCSP Cert
INIT_VAULT_ROOT_CA_OCSP="${INIT_VAULT_ROOT_OCSP:-true}"

VAULT_ROOT_CA_OCSP_CSR="${VAULT_ROOT_CA_OCSP_CSR:-$OPENSSL_CA_DIR/ocsp.$VAULT_ROOT_CA_PATH.cert.csr}"
VAULT_ROOT_CA_OCSP_PEM="${VAULT_ROOT_CA_OCSP_PEM:-$OPENSSL_CA_DIR/ocsp.$VAULT_ROOT_CA_PATH.cert.pem}"

# K8S Root CA Auth
INIT_VAULT_ROOT_CA_K8S_AUTH="${INIT_VAULT_ROOT_K8S_AUTH:-true}"

VAULT_ROOT_CA_ROLE="${VAULT_ROOT_CA_ROLE:-$VAULT_ROOT_CA_PATH}"
VAULT_ROOT_CA_POLICY="${VAULT_ROOT_CA_POLICY:-$VAULT_CONFIG_DIR/$VAULT_ROOT_CA_ROLE-policy.hcl}"
VAULT_ROOT_CA_SA_TOKEN="${VAULT_ROOT_CA_SA_TOKEN:-$K8S_SA_JWT_TOKEN}"
VAULT_ROOT_CA_SA_TOKEN_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${VAULT_ROOT_CA_SA_TOKEN})
VAULT_ROOT_CA_SA="${VAULT_ROOT_CA_SA:-$(echo $VAULT_ROOT_CA_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/service-account.name" // "default"')}"
VAULT_ROOT_CA_SA_NAMESPACE="${VAULT_ROOT_CA_SA_NAMESPACE:-$(echo $VAULT_ROOT_CA_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/namespace" // "default"')}"
VAULT_ROOT_CA_SA_TTL="${VAULT_ROOT_CA_SA_TTL:-20m}"

## Vault Intermediate CA (Level 3)
VALIDATE_VAULT_INTR_CA="${VALIDATE_VAULT_INTR_CA:-true}"

INIT_VAULT_INTR_CA="${INIT_VAULT_INTR_CA:-true}"

VAULT_INTR_CA_ORG="${VAULT_INTR_CA_ORG:-dev}"
VAULT_INTR_CA_OU="${VAULT_INTR_CA_OU:-development}" # use lower case for OU, as the vault path is case sensitive
VAULT_INTR_CA_DOMAIN="${VAULT_INTR_CA_DOMAIN:-$VAULT_INTR_CA_ORG.$CA_DOMAIN}"
VAULT_INTR_CA_PATH="${VAULT_INTR_CA_PATH:-pki_int_$VAULT_INTR_CA_OU}"
VAULT_INTR_CA_CN="${VAULT_INTR_CA_CN:-$CA_ORG_ABBR $VAULT_INTR_CA_OU Intermediate CA 1}"
VAULT_INTR_CA_CSR="${VAULT_INTR_CA_CSR:-$OPENSSL_CA_DIR/ca.$VAULT_INTR_CA_PATH.cert.csr}"
VAULT_INTR_CA_PEM="${VAULT_INTR_CA_PEM:-$OPENSSL_CA_DIR/ca.$VAULT_INTR_CA_PATH.cert.pem}"
VAULT_INTR_CA_TTL="${VAULT_INTR_CA_TTL:-8760h}" #  1 year
VAULT_INTR_CA_URL="${VAULT_INTR_CA_URL:-$VAULT_ADDR/v1/$VAULT_INTR_CA_PATH/ca}"

# CRL
VAULT_INTR_CA_CRL_PEM="${VAULT_INTR_CA_CRL_PEM:-$OPENSSL_CA_DIR/crl/ca.$VAULT_INTR_CA_PATH.crl.pem}"
VAULT_INTR_CA_CRL_CHAIN_PEM="${VAULT_INTR_CA_CRL_CHAIN_PEM:-$OPENSSL_CA_DIR/ca.$VAULT_INTR_CA_PATH.crl_chain.pem}"
VAULT_INTR_CA_CRL_URL="${VAULT_INTR_CA_CRL_URL:-$VAULT_ADDR/v1/$VAULT_INTR_CA_PATH/crl}"

# Client Role
VAULT_INTR_CA_CLIENT_ROLE="${VAULT_INTR_CA_CLIENT_ROLE:-$(echo $VAULT_INTR_CA_DOMAIN | sed s/[.]/-dot-/g)}"
VAULT_INTR_CA_CLIENT_TTL="${VAULT_INTR_CA_CLIENT_TTL:-2160h}" #  3 months

# OCSP Role
VAULT_INTR_CA_OCSP_ROLE="${VAULT_INTR_CA_OCSP_ROLE:-ocsp-$(echo $VAULT_INTR_CA_DOMAIN | sed s/[.]/-dot-/g)}"
VAULT_INTR_CA_OCSP_TTL="${VAULT_INTR_CA_OCSP_TTL:-8759h}" # 1 year
VAULT_INTR_CA_OCSP_URL="${VAULT_INTR_CA_OCSP_URL:-http://$CA_PKI_DOMAIN/$VAULT_INTR_CA_PATH/ocsp}"

# OCSP
INIT_VAULT_INTR_CA_OCSP="${INIT_VAULT_INTR_CA_OCSP:-true}"

VAULT_INTR_CA_OCSP_CSR="${VAULT_INTR_CA_OCSP_CSR:-$OPENSSL_CA_DIR/ocsp.$VAULT_INTR_CA_PATH.cert.csr}"
VAULT_INTR_CA_OCSP_PEM="${VAULT_INTR_CA_OCSP_PEM:-$OPENSSL_CA_DIR/ocsp.$VAULT_INTR_CA_PATH.cert.pem}"

## Vault Intermediate CA (Level 3) Client
VALIDATE_VAULT_INTR_CA_CLIENT="${VALIDATE_VAULT_INTR_CA_CLIENT:-true}"

TEST_VAULT_REVOKE="${TEST_VAULT_REVOKE:-true}"

INIT_VAULT_INTR_CA_CLIENT="${INIT_VAULT_INTR_CA_CLIENT:-true}"

VAULT_INTR_CA_CLIENT_CN="${VAULT_INTR_CA_CLIENT_CN:-user}"
VAULT_INTR_CA_CLIENT_PEM="${VAULT_INTR_CA_CLIENT_PEM:-$OPENSSL_CA_DIR/$VAULT_INTR_CA_CLIENT_CN.$VAULT_INTR_CA_PATH.cert.pem}"
VAULT_INTR_CA_CLIENT_KEY="${VAULT_INTR_CA_CLIENT_KEY:-$OPENSSL_CA_DIR/$VAULT_INTR_CA_CLIENT_CN.$VAULT_INTR_CA_PATH.cert.key}"

# K8S Vault Intr CA Auth
INIT_VAULT_INTR_CA_K8S_AUTH="${INIT_VAULT_INTR_CA_K8S_AUTH:-true}"

VAULT_INTR_CA_ROLE="${VAULT_INTR_CA_ROLE:-$VAULT_INTR_CA_PATH}"
VAULT_INTR_CA_POLICY="${VAULT_INTR_CA_POLICY:-$VAULT_CONFIG_DIR/$VAULT_INTR_CA_ROLE-policy.hcl}"
VAULT_INTR_CA_SA_TOKEN="${VAULT_INTR_CA_SA_TOKEN:-$K8S_SA_JWT_TOKEN}"
VAULT_INTR_CA_SA_TOKEN_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${VAULT_INTR_CA_SA_TOKEN})
VAULT_INTR_CA_SA="${VAULT_INTR_CA_SA:-$(echo $VAULT_INTR_CA_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/service-account.name" // "default"')}"
VAULT_INTR_CA_SA_NAMESPACE="${VAULT_INTR_CA_SA_NAMESPACE:-$(echo $VAULT_INTR_CA_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/namespace" // "default"')}"
VAULT_INTR_CA_SA_TTL="${VAULT_INTR_CA_SA_TTL:-20m}"

## Vault K8S OCSP Auth
VALIDATE_VAULT_OCSP_K8S_AUTH="${VALIDATE_VAULT_OCSP_K8S_AUTH:-true}"

INIT_VAULT_OCSP_K8S_AUTH="${INIT_VAULT_OCSP_K8S_AUTH:-true}"

VAULT_OCSP_ROLE="${VAULT_OCSP_ROLE:-ocsp}"
VAULT_OCSP_POLICY="${VAULT_OCSP_POLICY:-$VAULT_CONFIG_DIR/$VAULT_OCSP_ROLE-policy.hcl}"
VAULT_OCSP_SA_TOKEN="${VAULT_OCSP_SA_TOKEN:-$K8S_SA_JWT_TOKEN}"
VAULT_OCSP_SA_TOKEN_SAFE=$(jq -R 'split(".") | .[1] | @base64d | fromjson | del(.enc)' <<< ${VAULT_OCSP_SA_TOKEN})
VAULT_OCSP_SA="${VAULT_OCSP_SA:-$(echo $VAULT_OCSP_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/service-account.name" // "default"')}"
VAULT_OCSP_SA_NAMESPACE="${VAULT_OCSP_SA_NAMESPACE:-$(echo $VAULT_OCSP_SA_TOKEN_SAFE | jq -r '."kubernetes.io/serviceaccount/namespace" // "default"')}"
VAULT_OCSP_SA_TTL="${VAULT_OCSP_SA_TTL:-20m}"

## Test PKI Secret
INIT_TEST_PKI_SECRET="${INIT_TEST_PKI_SECRET:-true}"
TEST_PKI_SECRET_DIR="${TEST_PKI_SECRET_DIR:-$OPENSSL_CA_DIR}"
TEST_PKI_SECRET_ENV_FILE=${TEST_PKI_SECRET_ENV_FILE:-$TEST_PKI_SECRET_DIR/test-pki.env}
TEST_PKI_SECRET="${TEST_PKI_SECRET:-$CA_PKI_DOMAIN-test-pki-secret}"

TEST_PKI_OPENSSL_CA_SOURCE=${TEST_PKI_OPENSSL_CA_SOURCE:-$VALIDATE_OPENSSL_CA}
TEST_PKI_VAULT_CA_SOURCE=${TEST_PKI_OPENSSL_CA_SOURCE:-$VALIDATE_VAULT_ROOT_CA}

validate_hsm_module()
{
    if [ -z "${HSM_MODULE}" ]; then
        export HSM_MODULE="/usr/lib64/pkcs11/libsofthsm2.so"
    else
        printf "'HSM_MODULE' [${HSM_MODULE}] has been defined\n"
    fi

    if [ ! -f "${HSM_MODULE}" ]; then
        printf "Must set valid 'HSM_MODULE' [${HSM_MODULE}], file does not exist\n"
        exit 1
    fi
}

validate_hsm_slotid()
{
    TEMP_HSM_SLOTID=`pkcs11-tool -L --module ${HSM_MODULE} | grep "token label\s*:\s*${HSM_TOKENLABEL}" -B 1 | grep -E "Slot" | awk 'match($3, /\(0x[a-f0-9]*\)/) {print substr($3,RSTART+1,RLENGTH-2)}'`
    if [ -z "${HSM_SLOTID}" ] || [ ! "${HSM_SLOTID}" == "${TEMP_HSM_SLOTID}" ]; then 
        if [ -z "${TEMP_HSM_SLOTID}" ]; then
            printf "Could not find existing 'HSM_SLOTID' [${HSM_SLOTID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n'INIT_HSM' [${INIT_HSM}] and 'INIT_HSM_TOKEN' [${INIT_HSM_TOKEN}]\n"
            if [ "${INIT_HSM}" == true ] && [ "${INIT_HSM_TOKEN}" == true ]; then
                if [ -z "${HSM_SLOTID}" ]; then
                    HSM_SLOTID=0
                fi
                printf "Initializing 'HSM_SLOTID' [${HSM_SLOTID}] with 'HSM_MODULE' [${HSM_MODULE}] and 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n"
                if [ "$(basename ${HSM_MODULE})" == "libsofthsm2.so" ]; then
                    softhsm2-util --init-token --slot ${HSM_SLOTID} --label ${HSM_TOKENLABEL} --so-pin ${HSM_SOPIN} --pin ${HSM_PIN}
                else
                    sc-hsm-tool --initialize --label ${HSM_TOKENLABEL} --so-pin ${HSM_SOPIN} --pin ${HSM_PIN} --dkek-shares 1
                fi

                export HSM_SLOTID=`pkcs11-tool -L --module ${HSM_MODULE} | grep "token label\s*:\s*${HSM_TOKENLABEL}" -B 1 | grep -E "Slot" | awk 'match($3, /\(0x[a-f0-9]*\)/) {print substr($3,RSTART+1,RLENGTH-2)}'`

                if [ -z "${HSM_SLOTID}" ]; then
                    printf "Initialization of 'HSM_SLOTID' [${HSM_SLOTID}] failed, check 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n"
                    exit 1
                fi
            else
                exit 1
            fi
        else
            if [ -z "${HSM_SLOTID}" ]; then
                export HSM_SLOTID=${TEMP_HSM_SLOTID}
                printf "'HSM_SLOTID' was not preset, setting to 'TEMP_HSM_SLOTID' [${TEMP_HSM_SLOTID}] found with 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n"
            else
                printf "Error validating preset 'HSM_SLOTID' [${HSM_SLOTID}], found 'TEMP_HSM_SLOTID' [${TEMP_HSM_SLOTID}] instead, check 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n"
                exit 1
            fi
        fi
    else
        printf "Validated preset 'HSM_SLOTID' [${HSM_SLOTID}] with 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}]\n"
    fi
}

validate_hsm_ca_keypair()
{
    TEMP_HSM_CA_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_CA_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
    if [ -z "${HSM_CA_KEYID}" ] || [ ! "${HSM_CA_KEYID}" == "${TEMP_HSM_CA_KEYID}" ]; then
        if [ -z "${TEMP_HSM_CA_KEYID}" ]; then
            printf "Could not find existing 'HSM_CA_KEYID' [${HSM_CA_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n'INIT_HSM' [${INIT_HSM}] and 'INIT_OPENSSL_CA' [${INIT_OPENSSL_CA}]\n"
            if [ "${INIT_HSM}" == true ] && [ "${INIT_OPENSSL_CA}" == true ]; then
                printf "Generating 'HSM_CA_KEYID' [${HSM_CA_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n"
                pkcs11-tool --module ${HSM_MODULE} --token-label ${HSM_TOKENLABEL} --pin ${HSM_PIN} --keypairgen --key-type rsa:2048 --id ${HSM_CA_KEYID}   --label ${HSM_CA_KEYLABEL}
                export HSM_CA_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_CA_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
            else
                exit 1
            fi

            if [ -z "${HSM_CA_KEYID}" ]; then
                printf "Error generating 'HSM_CA_KEYID' [${HSM_CA_KEYID}], check 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n"
                exit 1
            fi
        else
            if [ -z "${HSM_CA_KEYID}" ]; then
                export HSM_CA_KEYID=${TEMP_HSM_CA_KEYID}
                printf "'HSM_CA_KEYID' was not preset, setting to 'TEMP_HSM_CA_KEYID' [${TEMP_HSM_CA_KEYID}] found with HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n"
            else
                printf "Error validating preset 'HSM_CA_KEYID' [${HSM_CA_KEYID}], found 'TEMP_HSM_CA_KEYID' [${TEMP_HSM_CA_KEYID}] instead, check 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n"
                exit 1
            fi
        fi
    else
        printf "Validated preset 'HSM_CA_KEYID' [${HSM_CA_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_CA_KEYLABEL' [${HSM_CA_KEYLABEL}]\n"
    fi
}

validate_hsm_ocsp_keypair()
{
    TEMP_HSM_OCSP_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_OCSP_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
    if [ -z "${HSM_OCSP_KEYID}" ] || [ ! "${HSM_OCSP_KEYID}" == "${TEMP_HSM_OCSP_KEYID}" ]; then
        if [ -z "${TEMP_HSM_OCSP_KEYID}" ]; then
            printf "Could not find existing 'HSM_OCSP_KEYID' [${HSM_OCSP_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n'INIT_HSM' [${INIT_HSM}] and 'INIT_OPENSSL_CA_OCSP' [${INIT_OPENSSL_CA_OCSP}]\n"
            if [ "${INIT_HSM}" == true ] && [ "${INIT_OPENSSL_CA_OCSP}" == true ]; then
                printf "Generating 'HSM_OCSP_KEYID' [${HSM_OCSP_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n"
                pkcs11-tool --module ${HSM_MODULE} --token-label ${HSM_TOKENLABEL} --pin ${HSM_PIN} --keypairgen --key-type rsa:2048 --id ${HSM_OCSP_KEYID} --label ${HSM_OCSP_KEYLABEL}
                export HSM_OCSP_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_OCSP_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
            fi

            if [ -z "${HSM_OCSP_KEYID}" ]; then
                printf "Error generating 'HSM_OCSP_KEYID' [${HSM_OCSP_KEYID}], check 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n"
                exit 1
            fi
        else
            if [ -z "${HSM_OCSP_KEYID}" ]; then
                export HSM_OCSP_KEYID=${TEMP_HSM_OCSP_KEYID}
                printf "'HSM_OCSP_KEYID' was not preset, setting to 'TEMP_HSM_OCSP_KEYID' [${TEMP_HSM_OCSP_KEYID}] found with HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n"
            else
                printf "Error validating preset 'HSM_OCSP_KEYID' [${HSM_OCSP_KEYID}], found 'TEMP_HSM_OCSP_KEYID' [${TEMP_HSM_OCSP_KEYID}] instead, check 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n"
                exit 1
            fi
        fi
    else
        printf "Validated preset 'HSM_OCSP_KEYID' [${HSM_OCSP_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_OCSP_KEYLABEL' [${HSM_OCSP_KEYLABEL}]\n"
    fi
}

validate_hsm_int_keypair()
{
    TEMP_INT_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_INT_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
    if [ -z "${HSM_INT_KEYID}" ] || [ ! "${HSM_OCSP_KEYID}" == "${TEMP_HSM_OCSP_KEYID}" ]; then
        if [ -z "${TEMP_HSM_INT_KEYID}" ]; then
            printf "Could not find existing 'HSM_INT_KEYID' [${HSM_INT_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n'INIT_HSM' [${INIT_HSM}] and 'INIT_OPENSSL_INT' [${INIT_OPENSSL_INT}]\n"
            if [ "${INIT_HSM}" == true ] && [ "${INIT_OPENSSL_INT}" == true ]; then
                printf "Generating 'HSM_INT_KEYID'[${HSM_INT_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n"
                pkcs11-tool --module ${HSM_MODULE} --token-label ${HSM_TOKENLABEL} --pin ${HSM_PIN} --keypairgen --key-type rsa:2048 --id ${HSM_INT_KEYID} --label ${HSM_INT_KEYLABEL}
                export HSM_INT_KEYID=`pkcs11-tool --list-objects --module ${HSM_MODULE} --slot ${HSM_SLOTID} --type pubkey | grep "label:\s*${HSM_INT_KEYLABEL}" -A 1 | grep "ID:" | awk '{print $2}'`
            fi

            if [ -z "${HSM_INT_KEYID}" ]; then
                printf "Error generating 'HSM_INT_KEYID' [${HSM_IN_KEYID}], check 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n"
                exit 1
            fi
        else
            if [ -z "${HSM_INT_KEYID}" ]; then
                export HSM_INT_KEYID=${TEMP_HSM_INT_KEYID}
                printf "'HSM_INT_KEYID' was not preset, setting to 'TEMP_HSM_INT_KEYID' [${TEMP_HSM_INT_KEYID}] found with HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n"
            else
                printf "Error validating preset 'HSM_INT_KEYID' [${HSM_INT_KEYID}], found 'TEMP_HSM_INT_KEYID' [${TEMP_HSM_INT_KEYID}] instead, check 'HSM_MODULE' [${HSM_MODULE}] or 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n"
                exit 1
            fi
        fi
    else
        printf "Validated preset 'HSM_INT_KEYID' [${HSM_INT_KEYID}] with 'HSM_MODULE' [${HSM_MODULE}], 'HSM_SLOTID' [${HSM_SLOTID}], 'HSM_TOKENLABEL' [${HSM_TOKENLABEL}], 'HSM_INT_KEYLABEL' [${HSM_INT_KEYLABEL}]\n"
    fi
}

validate_openssl_ca_config()
{
    if [ ! -f "${OPENSSL_CA_CONF}" ]; then
        printf "Error could not find 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
        exit 1
    else
        printf "Found existing 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
    fi
}

verify_openssl_ca_cert_dgst()
{
    printf "Verifying 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}] with 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}]\n"
    openssl x509 -pubkey -in ${OPENSSL_CA_PEM} -out ${OPENSSL_CA_PEM}.pubkey
    DIGEST="verify"
    echo $DIGEST | openssl dgst -sha256 -engine pkcs11 -keyform engine -sign "${HSM_CA_PKCS11_URI}" -out ${OPENSSL_CA_PEM}.out.sig 2>&1 || true
    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${OPENSSL_CA_PEM}.pubkey -signature ${OPENSSL_CA_PEM}.out.sig 2>&1 || true )

    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}] with 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}]\n"
    else
        printf "Error verifying 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}] with 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}]:\n${RESULT}\n"
        exit 1
    fi
}

validate_openssl_ca_cert()
{
    if [ ! -f "${OPENSSL_CA_PEM}" ]; then
        printf "Could not find existing 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}]\n'INIT_OPENSSL_CA' [${INIT_OPENSSL_CA}]\n"
        if  [ "${INIT_OPENSSL_CA}" == true ]; then
            printf "Creating a new 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}] using 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}]\n"
            OPENSSL_CONF=${OPENSSL_CA_CONF} openssl req \
            -engine pkcs11 -keyform engine -new -key "${HSM_CA_PKCS11_URI}" \
            -nodes -days 3650 -x509 -sha256 -out "${OPENSSL_CA_PEM}" \
            -subj "/C=${CA_COUNTRY}/ST=${CA_STATE}/L=${CA_LOCALITY}/O=${CA_ORG}/OU=${CA_ORG_UNIT}/CN=${CA_ORG_ABBR} CA"

            # Validate created OPENSSL_CA cert
            if [ ! -f "${OPENSSL_CA_PEM}" ]; then
                printf "Error creating new 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}], check 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
                exit 1
            fi
        else
            exit 1
        fi
    else
        printf "Found existing 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}]\n"
    fi

    verify_openssl_ca_cert_dgst
}

validate_openssl_ca_certindex()
{
    if [ ! -f "${OPENSSL_CA_CERTINDEX}" ]; then
        printf "Could not find existing 'OPENSSL_CA_CERTINDEX' [${OPENSSL_CA_CERTINDEX}]\n'INIT_OPENSSL_CA' [${INIT_OPENSSL_CA}]\n"
        if [ "${INIT_OPENSSL_CA}" == true ]; then
            printf "Creating a new 'OPENSSL_CA_CERTINDEX' [${OPENSSL_CA_CERTINDEX}]\n"
            mkdir -p "${OPENSSL_CA_DIR}"
            mkdir -p "${OPENSSL_CA_CRL_DIR}"
            mkdir -p "${OPENSSL_CA_NEW_CERTS_DIR}"
            touch ${OPENSSL_CA_CERTINDEX}
            echo 1000 > "${OPENSSL_CA_CERTSERIAL}"
            echo 1000 > "${OPENSSL_CA_CRLNUMBER}"
        else
            exit 1
        fi
    else
        printf "Found and using existing 'OPENSSL_CA_CERTINDEX' [${OPENSSL_CA_CERTINDEX}]\n"
    fi
}

init_openssl_ca_crl_chain()
{
    printf "Creating a new 'OPENSSL_CA_CRL_PEM' [${OPENSSL_CA_CRL_PEM}] using 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}]\n"
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl ca -batch \
    -engine pkcs11 -keyform engine \
    -gencrl -out ${OPENSSL_CA_CRL_PEM}

    if [ ! -f "${OPENSSL_CA_CRL_PEM}" ] || ! grep -q "BEGIN X509 CRL" ${OPENSSL_CA_CRL_PEM}; then
        printf "Error creating new 'OPENSSL_CA_CRL_PEM' [${OPENSSL_CA_CRL_PEM}], check 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
        cat ${OPENSSL_CA_CRL_PEM} 
        exit 1
    fi

    if [ ! -f ${OPENSSL_CA_PEM} ] || ! grep -q "BEGIN CERT" ${OPENSSL_CA_PEM}; then
        printf "Did not find expected 'OPENSSL_CA_PEM' [${OPENSSL_CA_PEM}]:\n"
        cat ${OPENSSL_CA_PEM} 
        exit 1
    fi

    cat ${OPENSSL_CA_PEM} ${OPENSSL_CA_CRL_PEM} > ${OPENSSL_CA_CRL_CHAIN_PEM}
}

init_openssl_ca_ocsp_cert()
{
    printf "Creating a new 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] using 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    # Create OPENSSL_CA_OCSP csr
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl req \
    -engine pkcs11 -keyform engine -new -key ${HSM_OCSP_PKCS11_URI} \
    -sha256 -out "${OPENSSL_CA_OCSP_CSR}" \
    -subj "/C=${CA_COUNTRY}/ST=${CA_STATE}/L=${CA_LOCALITY}/O=${CA_ORG}/OU=${CA_ORG_UNIT}/CN=${CA_PKI_DOMAIN}"
    
    # Validate created OPENSSL_CA_OCSP csr
    if [ -f "${OPENSSL_CA_OCSP_CSR}" ]; then
        # Create OPENSSL_CA_OCSP cert
        OPENSSL_CONF=${OPENSSL_CA_CONF} openssl ca -batch \
        -engine pkcs11 -keyform engine \
        -notext -in "${OPENSSL_CA_OCSP_CSR}" -out "${OPENSSL_CA_OCSP_PEM}"

        # Update OPENSSL_CA_CRL_PEM
        init_openssl_ca_crl_chain

        if [ ! -f "${OPENSSL_CA_OCSP_PEM}" ]; then
            printf "Error creating a new OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}], check 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
            exit 1
        fi
    else
        printf "Error creating new 'OPENSSL_CA_OCSP_CSR' [${OPENSSL_CA_OCSP_CSR}], check 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
        exit 1
    fi
}

verify_openssl_ca_ocsp_dgst()
{
    printf "Verifying 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    openssl x509 -pubkey -in ${OPENSSL_CA_OCSP_PEM} -out ${OPENSSL_CA_OCSP_PEM}.pubkey
    DIGEST="verify"
    echo $DIGEST | openssl dgst -sha256 -engine pkcs11 -keyform engine -sign "${HSM_OCSP_PKCS11_URI}" -out ${OPENSSL_CA_OCSP_PEM}.out.sig 2>&1 || true
    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${OPENSSL_CA_OCSP_PEM}.pubkey -signature ${OPENSSL_CA_OCSP_PEM}.out.sig 2>&1 || true )
    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    else
        printf "Error verifying 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]:\n${RESULT}\n"
        exit 1
    fi
}

verify_openssl_ca_ocsp_cert()
{
    # Create OPENSSL_CA_CRL_PEM
    init_openssl_ca_crl_chain

    printf "Verifying 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"

    RESULT=$(openssl verify -crl_check -CAfile ${OPENSSL_CA_CRL_CHAIN_PEM} ${OPENSSL_CA_OCSP_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
        cat ${OPENSSL_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

validate_openssl_ca_ocsp_cert()
{
    if [ ! -f "${OPENSSL_CA_OCSP_PEM}" ]; then
        printf "Could not find existing 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}]\n'INIT_OPENSSL_CA_OCSP' [${INIT_OPENSSL_CA_OCSP}]\n"
        if [ "${INIT_OPENSSL_CA_OCSP}" == true ]; then
            init_openssl_ca_ocsp_cert
        else
            exit 1
        fi
    else
        printf "Found existing 'OPENSSL_CA_OCSP_PEM' [${OPENSSL_CA_OCSP_PEM}]\n"
    fi

    verify_openssl_ca_ocsp_dgst

    verify_openssl_ca_ocsp_cert
}

init_openssl_int_cert()
{
    printf "Creating a new 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] using 'HSM_INT_PKCS11_URI_SAFE' [${HSM_INT_PKCS11_URI_SAFE}]\n"
    # Create INT csr
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl req \
    -engine pkcs11 -keyform engine -new -key ${HSM_INT_PKCS11_URI} \
    -sha256 -out "${OPENSSL_INT_CSR}" \
    -subj "/C=${CA_COUNTRY}/ST=${CA_STATE}/L=${CA_LOCALITY}/O=${CA_ORG}/OU=${CA_ORG_UNIT}/CN=${CA_ORG_ABBR} Intermediate CA 1"
    
    # Validate created OPENSSL_INT csr
    if [ -f "${OPENSSL_INT_CSR}" ]; then
        # Create OPENSSL_INT cert
        OPENSSL_CONF=${OPENSSL_CA_CONF} openssl ca -name ca_int -batch \
        -engine pkcs11 -keyform engine \
        -notext -in "${OPENSSL_INT_CSR}" -out "${OPENSSL_INT_PEM}"

        # Update OPENSSL_CA_CRL_PEM
        init_openssl_ca_crl_chain

        if [ ! -f "${OPENSSL_INT_PEM}" ]; then
            printf "Error creating new 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}], check 'HSM_CA_PKCS11_URI_SAFE' [${HSM_CA_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
            exit 1
        fi
    else
        printf "Error creating new 'OPENSSL_INT_CSR' [${OPENSSL_INT_CSR}], check 'HSM_INT_PKCS11_URI_SAFE' [${HSM_INT_PKCS11_URI_SAFE}] and 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
        exit 1
    fi
}

verify_openssl_int_cert_dgst()
{
    printf "Verifying 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'HSM_INT_PKCS11_URI_SAFE' [${HSM_INT_PKCS11_URI_SAFE}]\n"
    openssl x509 -pubkey -in ${OPENSSL_INT_PEM} -out ${OPENSSL_INT_PEM}.pubkey
    DIGEST="verify"
    echo $DIGEST | openssl dgst -sha256 -engine pkcs11 -keyform engine -sign "${HSM_INT_PKCS11_URI}" -out ${OPENSSL_INT_PEM}.out.sig 2>&1 || true

    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${OPENSSL_INT_PEM}.pubkey -signature ${OPENSSL_INT_PEM}.out.sig 2>&1 || true )
    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'HSM_INT_PKCS11_URI_SAFE' [${HSM_INT_PKCS11_URI_SAFE}]\n"
    else
        printf "Error verifying 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'HSM_INT_PKCS11_URI_SAFE' [${HSM_INT_PKCS11_URI_SAFE}]:\n${RESULT}\n"
        exit 1
    fi
}

verify_openssl_int_cert_crl_check()
{
    # Create OPENSSL_CA_CRL_PEM
    init_openssl_ca_crl_chain

    printf "Verifying 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"

    RESULT=$(openssl verify -crl_check -CAfile ${OPENSSL_CA_CRL_CHAIN_PEM} ${OPENSSL_INT_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM} with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${OPENSSL_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

revoke_openssl_int_cert()
{
    printf "Revoking 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'OPENSSL_CA_CONF' [${OPENSSL_CA_CONF}]\n"
    # revoke
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl ca \
        -engine pkcs11 -keyform engine \
        -revoke ${OPENSSL_INT_PEM}
}

verify_openssl_int_cert_revoke()
{
    init_openssl_ca_crl_chain
    printf "Verifying revoke of 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    
    RESULT=$(openssl verify -crl_check -CAfile ${OPENSSL_CA_CRL_CHAIN_PEM} ${OPENSSL_INT_PEM} 2>&1 || true )

    if echo "${RESULT}" | grep -q "lookup: certificate revoked"; then
        printf "Successfully revoked 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error revoking 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}], check 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${OPENSSL_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

validate_openssl_int_cert()
{
    if [ ! -f "${OPENSSL_INT_PEM}" ]; then
        printf "Could not find existing 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}]\n'INIT_OPENSSL_INT' [${INIT_OPENSSL_INT}] and 'TEST_OPENSSL_REVOKE' [${TEST_OPENSSL_REVOKE}]\n"
        if  [ "${INIT_OPENSSL_INT}" == true ]; then
            init_openssl_int_cert

            # Optionally revoke OPENSSL_INT
            if [ "${TEST_OPENSSL_REVOKE}" == true ]; then
                revoke_openssl_int_cert
            fi
        else
            exit 1
        fi
    else
        printf "Found existing 'OPENSSL_INT_PEM' [${OPENSSL_INT_PEM}]\n"
    fi

    verify_openssl_int_cert_dgst

    if [ "${TEST_OPENSSL_REVOKE}" == true ]; then
        verify_openssl_int_cert_revoke
    else
        verify_openssl_int_cert_crl_check
    fi
}

init_vault_dev()
{
    # export VAULT_HOME=${VAULT_HOME:-/app/.config/vault}
    # export HOME=$VAULT_HOME
    # export VAULT_CONFIG_PATH="${VAULT_CONFIG_PATH:-/etc/vault/vault-agent-config.hcl}"
    # Set a token to be used for vault authentication
    RANDOM_UUID=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random) # $(uuidgen)  
    VAULT_DEV_ROOT_TOKEN_ID="${VAULT_DEV_ROOT_TOKEN_ID:-$RANDOM_UUID}"
    VAULT_DEV_LISTEN_ADDRESS="${VAULT_DEV_LISTEN_ADDRESS:-0.0.0.0:8200}"
    
    printf "Initializing Vault Server with 'VAULT_DEV_LISTEN_ADDRESS' [${VAULT_DEV_LISTEN_ADDRESS}] and 'VAULT_LOG_LEVEL' [${VAULT_LOG_LEVEL}]\n"

    # Start a Vault server in dev mode in the background
    vault server -dev -dev-root-token-id="${VAULT_DEV_ROOT_TOKEN_ID}" -dev-listen-address="${VAULT_DEV_LISTEN_ADDRESS}" -log-level=${VAULT_LOG_LEVEL} &
    sleep 5
}

verify_vault_addr()
{
    printf "Checking if 'VAULT_TOKEN' is valid for 'VAULT_ADDR' [${VAULT_ADDR}]\n"
    RESULT=$(vault login $VAULT_TOKEN 2>&1 || true )

    if echo "${RESULT}" | grep -q "Success! You are now authenticated."; then
        printf "'VAULT_TOKEN' is valid for 'VAULT_ADDR' [${VAULT_ADDR}]:\n${RESULT}\n"
    else
        printf "'VAULT_TOKEN' is not valid for 'VAULT_ADDR' [${VAULT_ADDR}]:\n${RESULT}\n"
        exit 1
    fi
}

validate_vault_server()
{
    printf "'INIT_VAULT_DEV' [${INIT_VAULT_DEV}]\n"
    if [ "${INIT_VAULT_DEV}" == true ]; then
        init_vault_dev
    else
        verify_vault_addr
    fi
}

init_vault_agent()
{
    export VAULT_AGENT_ADDR=${VAULT_AGENT_ADDR:-http://127.0.0.1:8007}
    export VAULT_AGENT_CONFIG="${VAULT_AGENT_CONFIG:-/app/.config/vault/vault-agent-config.hcl}"

    printf "Initializing Vault Agent with 'VAULT_AGENT_CONFIG' [${VAULT_AGENT_CONFIG}] and 'VAULT_LOG_LEVEL' [${VAULT_LOG_LEVEL}]\n"

    # Start a Vault agent in the background
    vault agent -config=${VAULT_AGENT_CONFIG} -log-level=${VAULT_LOG_LEVEL} &
}

verify_vault_agent_addr()
{
    export VAULT_AGENT_ADDR=${VAULT_AGENT_ADDR:-http://127.0.0.1:8007}
    printf "Checking if 'VAULT_TOKEN' is valid for 'VAULT_AGENT_ADDR' [${VAULT_AGENT_ADDR}]\n"
    RESULT=$(vault login $VAULT_TOKEN 2>&1 || true )
    
    if echo "${RESULT}" | grep -q "Success! You are now authenticated."; then
        printf "'VAULT_TOKEN' is  valid for 'VAULT_AGENT_ADDR' [${VAULT_AGENT_ADDR}]:\n${RESULT}\n"
    else
        printf "'VAULT_TOKEN' is not valid for 'VAULT_AGENT_ADDR' [${VAULT_AGENT_ADDR}]:\n${RESULT}\n"
        exit
    fi
}
validate_vault_agent()
{
    printf "'INIT_VAULT_AGENT' [${INIT_VAULT_AGENT}]\n"
    if [ "${INIT_VAULT_AGENT}" == true ]; then
        init_vault_agent
    else
        verify_vault_agent_addr
    fi
}

init_vault_root_ca()
{
    # Enable the pki secrets engine at the pki path.
    printf "Enabling pki secrets engine at 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]\n"
    vault secrets enable -path=${VAULT_ROOT_CA_PATH} pki

    # Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL)
    vault secrets tune -max-lease-ttl=${VAULT_ROOT_CA_TTL} ${VAULT_ROOT_CA_PATH}

    if [ "${VAULT_ROOT_CA_SELF_SIGN}" == true ]; then
        printf "Generating new self-signed 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] from 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]\nWarning not recommended for production\n"
        # Generate self-signed VAULT_ROOT_CA cert
        vault write ${VAULT_ROOT_CA_PATH}/root/generate/internal \
            ttl=${VAULT_ROOT_CA_TTL} \
            country="${CA_COUNTRY}" \
            province="${CA_STATE}" \
            locality="${CA_LOCALITY}" \
            organization="${VAULT_ROOT_CA_ORG}" \
            ou="${VAULT_ROOT_CA_OU}" \
            common_name="${VAULT_ROOT_CA_CN}" | \
            jq -r '.data.certificate' > ${VAULT_ROOT_CA_PEM}
            # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_ROOT_CA_PEM}

    else
        # Generate CSR for the VAULT_ROOT_CA to be signed by the OPENSSL_CA, the key is stored
        # internally to vault
        printf "Generating intermediate 'VAULT_ROOT_CA_CSR' [${VAULT_ROOT_CA_CSR}] from 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]\n"
        vault write ${VAULT_ROOT_CA_PATH}/intermediate/generate/internal \
        ttl=${VAULT_ROOT_TTL} \
        country="${CA_COUNTRY}" \
        province="${CA_STATE}" \
        locality="${CA_LOCALITY}" \
        organization="${VAULT_ROOT_CA_ORG}" \
        ou="${VAULT_ROOT_CA_OU}" \
        common_name="${VAULT_ROOT_CA_CN}" | \
        jq -r '.data.csr' > ${VAULT_ROOT_CA_CSR}
        # sed -n '/csr/,/END CERTI/p' | sed 's/csr\s*//g' > ${VAULT_ROOT_CA_CSR}

        # Validate created VAULT_ROOT_CA csr
        if [ -f "${VAULT_ROOT_CA_CSR}" ]; then
            # Create VAULT_ROOT_CA cert
            printf "Creating new 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] with 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
            OPENSSL_CONF=${OPENSSL_CA_CONF} openssl ca -name ca_int -batch \
            -engine pkcs11 -keyform engine \
            -notext -in "${VAULT_ROOT_CA_CSR}" -out "${VAULT_ROOT_CA_PEM}"

            # Update OPENSSL_CA_CRL_PEM
            init_openssl_ca_crl_chain

            if [ -f ${VAULT_ROOT_CA_PEM} ]; then
                # Create crl chain for 
                printf "Creating 'VAULT_ROOT_CA_PEM'.fullchain [${VAULT_ROOT_CA_PEM}].fullchain with 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] and 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
                cat ${VAULT_ROOT_CA_PEM} ${OPENSSL_CA_CRL_CHAIN_PEM} > ${VAULT_ROOT_CA_PEM}.fullchain

                printf "Writing full chain 'VAULT_ROOT_CA_PEM'.fullchain [${VAULT_ROOT_CA_PEM}].fullchain to 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/intermediate/set-signed\n"
                # Add signed VAULT_ROOT_CA certificate to VAULT_ROOT_CA backend
                vault write ${VAULT_ROOT_CA_PATH}/intermediate/set-signed certificate=@${VAULT_ROOT_CA_PEM}.fullchain
            else
                printf "Error creating 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] with 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
                exit 1
            fi
        else
            printf "Error generating 'VAULT_ROOT_CA_CSR' [${VAULT_ROOT_CA_CSR}] from 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]\n"
            exit 1
        fi
    fi
}

verify_vault_root_ca_crl_check()
{
    init_vault_root_ca_crl_chain

    printf "Verifying 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    RESULT=$(openssl verify -crl_check -CAfile ${OPENSSL_CA_CRL_CHAIN_PEM} ${VAULT_ROOT_CA_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}] with 'OPENSSL_CA_CRL_CHAIN_PEM' [${OPENSSL_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${OPENSSL_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}


validate_vault_root_ca()
{
    vault read ${VAULT_ROOT_CA_PATH}/cert/ca | \
    jq -r '.data.certificate' > ${VAULT_ROOT_CA_PEM}.temp
    # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_ROOT_CA_PEM}.temp

    if [ ! -f ${VAULT_ROOT_CA_PEM}.temp ] || ! grep -q "BEGIN CERT" ${VAULT_ROOT_CA_PEM}.temp; then
        printf "Could not find existing 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}]\n'INIT_VAULT_ROOT_CA' [${INIT_VAULT_ROOT_CA}]\n"
        rm ${VAULT_ROOT_CA_PEM}.temp
        if [ "$INIT_VAULT_ROOT_CA" == true ]; then
            init_vault_root_ca
        else
            exit 1
        fi
    else
        printf "Found existing 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}]\n"
        mv ${VAULT_ROOT_CA_PEM}.temp ${VAULT_ROOT_CA_PEM}
    fi

    # Generated certificates can have the CRL location and the location of the issuing certificate encoded.
    printf "Writing new 'VAULT_ROOT_CA_URL' [${VAULT_ROOT_CA_URL}] and 'VAULT_ROOT_CA_CRL_URL' [${VAULT_ROOT_CA_CRL_URL}] url configuration to 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/config/urls\n"
    vault write ${VAULT_ROOT_CA_PATH}/config/urls \
        issuing_certificates="${VAULT_ROOT_CA_URL}" \
        crl_distribution_points="${VAULT_ROOT_CA_CRL_URL}"

    verify_vault_root_ca_crl_check

    # Create role for issuing INTR certificates
    printf "Writing new role 'VAULT_ROOT_CA_INTR_ROLE' [${VAULT_ROOT_CA_INTR_ROLE}] to 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/roles\n"
    vault write ${VAULT_ROOT_CA_PATH}/roles/${VAULT_ROOT_CA_INTR_ROLE} \
        country="${CA_COUNTRY}" \
        province="${CA_STATE}" \
        locality="${CA_LOCALITY}" \
        organization="${VAULT_ROOT_CA_ORG}" \
        ou="${VAULT_ROOT_CA_OU}" \
        allowed_domains="${VAULT_ROOT_CA_DOMAIN}" \
        allow_any_name=true \
        generate_lease=true \
        basic_constraints_valid_for_non_ca=false \
        server_flag=true \
        client_flag=false \
        code_signing_flag=false \
        key_bits=2048 \
        key_type=rsa \
        lease_max="${VAULT_ROOT_CA_INTR_TTL}"

    # Create role for issuing OCSP certificates
    printf "Writing new role 'VAULT_ROOT_CA_OCSP_ROLE' [${VAULT_ROOT_CA_OCSP_ROLE}] to 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/roles\n"
    vault write ${VAULT_ROOT_CA_PATH}/roles/${VAULT_ROOT_CA_OCSP_ROLE} \
        country="${CA_COUNTRY}" \
        province="${CA_STATE}" \
        locality="${CA_LOCALITY}" \
        organization="${VAULT_ROOT_CA_ORG}" \
        ou="${VAULT_ROOT_CA_OU}" \
        allowed_domains="${CA_PKI_DOMAIN}" \
        allow_any_name=true \
        generate_lease=true \
        basic_constraints_valid_for_non_ca=true \
        ext_key_usage="ocspsigning" \
        server_flag=true \
        client_flag=false \
        code_signing_flag=false \
        key_bits=2048 \
        key_type=rsa \
        lease_max="${VAULT_ROOT_CA_OCSP_TTL}"
}

init_vault_root_ca_crl_chain()
{
    # Get the 'VAULT_ROOT_CA_PEM'
    vault read ${VAULT_ROOT_CA_PATH}/cert/ca | \
    jq -r '.data.certificate' > ${VAULT_ROOT_CA_PEM}
    # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_ROOT_CA_PEM}

    if [ ! -f ${VAULT_ROOT_CA_PEM} ] || ! grep -q "BEGIN CERT" ${VAULT_ROOT_CA_PEM}; then
        printf "Did not find expected 'VAULT_ROOT_CA_PEM' [${VAULT_ROOT_CA_PEM}]:\n"
        cat ${VAULT_ROOT_CA_PEM} 
        exit 1
    fi

    # Get the 'VAULT_ROOT_CA_CRL_PEM'
    vault read ${VAULT_ROOT_CA_PATH}/cert/crl | \
    jq -r '.data.certificate' > ${VAULT_ROOT_CA_CRL_PEM}
    # sed -n '/certificate/,/END X509 CRL/p' | sed 's/certificate\s*//g' > ${VAULT_ROOT_CA_CRL_PEM}

    if [ ! -f ${VAULT_ROOT_CA_CRL_PEM} ] || ! grep -q "BEGIN X509 CRL" ${VAULT_ROOT_CA_CRL_PEM}; then
        printf "Did not find expected 'VAULT_ROOT_CA_CRL_PEM' [${VAULT_ROOT_CA_CRL_PEM}]:\n"
        cat ${VAULT_ROOT_CA_CRL_PEM} 
        exit 1
    fi

    init_openssl_ca_crl_chain

    cat ${VAULT_ROOT_CA_PEM} ${VAULT_ROOT_CA_CRL_PEM} ${OPENSSL_CA_CRL_CHAIN_PEM} > ${VAULT_ROOT_CA_CRL_CHAIN_PEM}
}

init_vault_root_ca_ocsp()
{
    printf "Creating new 'VAULT_ROOT_CA_OCSP_CSR' [${VAULT_ROOT_CA_OCSP_CSR}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}] and 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
    # Create VAULT_ROOT_CA_OCSP csr
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl req \
    -engine pkcs11 -keyform engine -new -key ${HSM_OCSP_PKCS11_URI} \
    -sha256 -out "${VAULT_ROOT_CA_OCSP_CSR}" \
    -subj "/C=${CA_COUNTRY}/ST=${CA_STATE}/L=${CA_LOCALITY}/O=${VAULT_ROOT_CA_ORG}/OU=${VAULT_ROOT_CA_OU}/CN=${CA_PKI_DOMAIN}"

    # Sign VAULT_ROOT_CA_OCSP cert
    if [ -f ${VAULT_ROOT_CA_OCSP_CSR} ]; then
        printf "Creating new 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'VAULT_ROOT_CA_OCSP_ROLE' [${VAULT_ROOT_CA_OCSP_ROLE}]\n"
        vault write ${VAULT_ROOT_CA_PATH}/sign/${VAULT_ROOT_CA_OCSP_ROLE} \
        ttl=${VAULT_ROOT_CA_OCSP_TTL} \
        csr=@${VAULT_ROOT_CA_OCSP_CSR} | \
        jq -r '.data.certificate' > ${VAULT_ROOT_CA_OCSP_PEM}
        # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_ROOT_CA_OCSP_PEM}
    else
        printf "Error creating 'VAULT_ROOT_CA_OCSP_CSR' [${VAULT_ROOT_CA_OCSP_CSR}], check 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}] and 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
        exit 1
    fi
}

verify_vault_root_ca_ocsp_dgst()
{
    printf "Verifying 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    DIGEST="verify"
    openssl x509 -pubkey -in ${VAULT_ROOT_CA_OCSP_PEM} -out ${VAULT_ROOT_CA_OCSP_PEM}.pubkey
    echo $DIGEST | openssl dgst -sha256 -engine pkcs11 -keyform engine -sign "${HSM_OCSP_PKCS11_URI}" -out ${VAULT_ROOT_CA_OCSP_PEM}.out.sig 2>&1 || true
    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${VAULT_ROOT_CA_OCSP_PEM}.pubkey -signature ${VAULT_ROOT_CA_OCSP_PEM}.out.sig 2>&1 || true )

    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    else
        printf "Error verifying 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]:\n${RESULT}\n"
        exit 1
    fi
}

verify_vault_root_ca_ocsp_crl_check()
{
    init_vault_root_ca_crl_chain

    printf "Verifying 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n"

    RESULT=$(openssl verify -crl_check -CAfile ${VAULT_ROOT_CA_CRL_CHAIN_PEM} ${VAULT_ROOT_CA_OCSP_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}]  with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}] with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n:\n${RESULT}\n"
        cat ${VAULT_ROOT_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

validate_vault_root_ca_ocsp()
{
    if [ ! -f ${VAULT_ROOT_CA_OCSP_PEM} ]; then
        printf "Could not find existing 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}]\n'INIT_VAULT_ROOT_CA_OCSP' [${INIT_VAULT_ROOT_CA_OCSP}]\n"
        if [ "$INIT_VAULT_ROOT_CA_OCSP" == true ]; then
           init_vault_root_ca_ocsp
        else
            exit 1
        fi
    else
        printf "Found existing 'VAULT_ROOT_CA_OCSP_PEM' [${VAULT_ROOT_CA_OCSP_PEM}]\n"
    fi

    verify_vault_root_ca_ocsp_dgst
        
    verify_vault_root_ca_ocsp_crl_check

    # Generated certificates can have the CRL location and the location of the issuing certificate encoded.
    printf "Writing new 'VAULT_ROOT_CA_URL' [${VAULT_ROOT_CA_URL}], 'VAULT_ROOT_CA_CRL_URL' [${VAULT_ROOT_CA_CRL_URL}], and 'VAULT_ROOT_CA_OCSP_URL' [${VAULT_ROOT_CA_OCSP_URL}] url configuration to 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/config/urls\n"
    vault write ${VAULT_ROOT_CA_PATH}/config/urls \
        issuing_certificates="${VAULT_ROOT_CA_URL}" \
        crl_distribution_points="${VAULT_ROOT_CA_CRL_URL}" \
        ocsp_servers="${VAULT_ROOT_CA_OCSP_URL}"
}

init_vault_intr_ca()
{
    printf "Enabling pki secrets engine at 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]\n"
    # Enable the pki secrets engine at the pki path.
    vault secrets enable -path=${VAULT_INTR_CA_PATH} pki

    # Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL)
    vault secrets tune -max-lease-ttl=${VAULT_INTR_CA_TTL} ${VAULT_INTR_CA_PATH}
    
    # Generate VAULT_INTR_CA_CSR to be signed by the VAULT_ROOT_CA, the key is stored
    # internally to vault
    printf "Generating intermediate 'VAULT_INTR_CA_CSR' [${VAULT_INTR_CA_CSR}] from 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/intermediate/generate/internal\n"
    vault write ${VAULT_INTR_CA_PATH}/intermediate/generate/internal \
        ttl=${VAULT_INTR_CA_TTL} \
        common_name="${VAULT_INTR_CA_CN}" | \
        jq -r '.data.csr' > ${VAULT_INTR_CA_CSR}
        # sed -n '/csr/,/END CERTI/p' | sed 's/csr\s*//g' > ${VAULT_INTR_CA_CSR}

    # Validate created VAULT_INTR_CA_CSR
    if [ -f "${VAULT_INTR_CA_CSR}" ]; then
        # Generate and sign the VAULT_INTR_CA_CSR as an intermediate CA
        printf "Creating new 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] with 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/root/sign-intermediate\n"
        vault write ${VAULT_ROOT_CA_PATH}/root/sign-intermediate \
        ttl=${VAULT_INTR_CA_TTL} \
        csr=@${VAULT_INTR_CA_CSR} | \
        jq -r '.data.certificate' > ${VAULT_INTR_CA_PEM}
        # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_INTR_CA_PEM}

        init_vault_root_ca_crl_chain

        if [ -f ${VAULT_INTR_CA_PEM} ]; then
        # Create crl chain for 
            printf "Creating 'VAULT_INTR_CA_PEM'.fullchain [${VAULT_INTR_CA_PEM}].fullchain with 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] and 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n"
            cat ${VAULT_INTR_CA_PEM} ${VAULT_ROOT_CA_CRL_CHAIN_PEM} > ${VAULT_INTR_CA_PEM}.fullchain

            printf "Writing full chain 'VAULT_INTR_CA_PEM'.fullchain [${VAULT_INTR_CA_PEM}].fullchain to 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/intermediate/set-signed\n"
            # Add signed VAULT_INTR_CA_PEM to intermediate CA backend
            vault write ${VAULT_INTR_CA_PATH}/intermediate/set-signed certificate=@${VAULT_INTR_CA_PEM}.fullchain
        else
            printf "Error creating new 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] from 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}]/root/sign-intermediate\n"
            exit 1
        fi
    else
        printf "Error creating 'VAULT_INTR_CA_CSR' [${VAULT_INTR_CA_CSR}] from 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/intermediate/generate/internal\n"
        exit 1
    fi
}

init_vault_intr_ca_crl_chain()
{
    # Get the 'VAULT_INTR_CA_PEM'
    vault read ${VAULT_INTR_CA_PATH}/cert/ca | \
    jq -r '.data.certificate' > ${VAULT_INTR_CA_PEM}
    # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_INTR_CA_PEM}

    if [ ! -f ${VAULT_INTR_CA_PEM} ] || ! grep -q "BEGIN CERT" ${VAULT_INTR_CA_PEM}; then
        printf "Did not find expected 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}]:\n"
        cat ${VAULT_INTR_CA_PEM} 
        exit 1
    fi

    # Get the 'VAULT_INTR_CA_CRL_PEM'
    vault read ${VAULT_INTR_CA_PATH}/cert/crl | \
    jq -r '.data.certificate' > ${VAULT_INTR_CA_CRL_PEM}
    # sed -n '/certificate/,/END X509 CRL/p' | sed 's/certificate\s*//g' > ${VAULT_INTR_CA_CRL_PEM}

    if [ ! -f ${VAULT_INTR_CA_CRL_PEM} ] || ! grep -q "BEGIN X509 CRL" ${VAULT_INTR_CA_CRL_PEM}; then
        printf "Did not find expected 'VAULT_INTR_CA_CRL_PEM' [${VAULT_INTR_CA_CRL_PEM}]:\n"
        cat ${VAULT_INTR_CA_CRL_PEM} 
        exit 1
    fi

    init_vault_root_ca_crl_chain

    cat ${VAULT_INTR_CA_PEM} ${VAULT_INTR_CA_CRL_PEM} ${VAULT_ROOT_CA_CRL_CHAIN_PEM} > ${VAULT_INTR_CA_CRL_CHAIN_PEM}
}

verify_vault_intr_ca_crl_check()
{
    init_vault_intr_ca_crl_chain

    printf "Verifying 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n"
    
    RESULT=$(openssl verify -crl_check -CAfile ${VAULT_ROOT_CA_CRL_CHAIN_PEM} ${VAULT_INTR_CA_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}] with 'VAULT_ROOT_CA_CRL_CHAIN_PEM' [${VAULT_ROOT_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${VAULT_ROOT_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

validate_vault_intr_ca()
{
    vault read ${VAULT_INTR_CA_PATH}/cert/ca | \
    jq -r '.data.certificate' > ${VAULT_INTR_CA_PEM}.temp
    # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_INTR_CA_PEM}.temp

    if [ ! -f ${VAULT_INTR_CA_PEM}.temp ] || ! grep -q "BEGIN CERT" ${VAULT_INTR_CA_PEM}.temp; then
        printf "Could not find existing 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}]\n'INIT_VAULT_INTR_CA' [${INIT_VAULT_INTR_CA}]\n"
        rm ${VAULT_INTR_CA_PEM}.temp
        if [ "$INIT_VAULT_INTR_CA" == true ]; then
            init_vault_intr_ca
        else
            exit 1
        fi
    else
        printf "Found existing 'VAULT_INTR_CA_PEM' [${VAULT_INTR_CA_PEM}]\n"
        mv ${VAULT_INTR_CA_PEM}.temp ${VAULT_INTR_CA_PEM}
    fi
    
    # Generated certificates can have the CRL location and the location of the issuing certificate encoded.
    printf "Writing new 'VAULT_INTR_CA_URL' [${VAULT_INTR_CA_URL}] and 'VAULT_INTR_CA_CRL_URL' [${VAULT_INTR_CA_CRL_URL}] url configuration to 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/config/urls\n"
    vault write ${VAULT_INTR_CA_PATH}/config/urls \
        issuing_certificates="${VAULT_INTR_CA_URL}" \
        crl_distribution_points="${VAULT_INTR_CA_CRL_URL}"

    verify_vault_intr_ca_crl_check

    # Create role for issuing intermediate client or server certificates
    printf "Writing new role 'VAULT_INTR_CA_CLIENT_ROLE' [${VAULT_INTR_CA_CLIENT_ROLE}] to 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/roles\n"
    vault write ${VAULT_INTR_CA_PATH}/roles/${VAULT_INTR_CA_CLIENT_ROLE} \
        country="${CA_COUNTRY}" \
        province="${CA_STATE}" \
        locality="${CA_LOCALITY}" \
        organization="${VAULT_INTR_CA_ORG},${CA_ORG}" \
        ou="${VAULT_INTR_CA_OU}" \
        allowed_domains="${VAULT_INTR_DOMAIN}" \
        allow_any_name=true \
        generate_lease=true \
        basic_constraints_valid_for_non_ca=true \
        server_flag=true \
        client_flag=true \
        code_signing_flag=false \
        key_bits=2048 \
        key_type=rsa \
        lease_max="${VAULT_INTR_CA_CLIENT_TTL}"

    # Create role for issuing intermediate ocsp server certificates
    printf "Writing new role 'VAULT_INTR_CA_OCSP_ROLE' [${VAULT_INTR_CA_OCSP_ROLE}] to 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/roles\n"
    vault write ${VAULT_INTR_CA_PATH}/roles/${VAULT_INTR_CA_OCSP_ROLE} \
        country="${CA_COUNTRY}" \
        province="${CA_STATE}" \
        locality="${CA_LOCALITY}" \
        organization="${VAULT_INTR_CA_ORG},${CA_ORG}" \
        ou="${VAULT_INTR_CA_OU}" \
        allowed_domains="${CA_PKI_DOMAIN}" \
        allow_any_name=true \
        generate_lease=true \
        basic_constraints_valid_for_non_ca=true \
        ext_key_usage="ocspsigning" \
        server_flag=true \
        client_flag=true \
        code_signing_flag=false \
        key_bits=2048 \
        key_type=rsa \
        lease_max="${VAULT_INTR_CA_OCSP_TTL}"
}

init_vault_intr_ca_ocsp()
{
    printf "Creating a new 'VAULT_INTR_CA_OCSP_CSR' [${VAULT_INTR_CA_OCSP_CSR}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}] and 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
    # Create VAULT_INTR_CA_OCSP_CSR
    OPENSSL_CONF=${OPENSSL_CA_CONF} openssl req \
    -engine pkcs11 -keyform engine -new -key ${HSM_OCSP_PKCS11_URI} \
    -sha256 -out "${VAULT_INTR_CA_OCSP_CSR}" \
    -subj "/C=${CA_COUNTRY}/ST=${CA_STATE}/L=${CA_LOCALITY}/O=${VAULT_INTR_CA_ORG}/OU=${VAULT_INTR_CA_OU}/CN=${CA_PKI_DOMAIN}"

    # Sign VAULT_INTR_CA_OCSP_PEM
    if [ -f ${VAULT_INTR_CA_OCSP_CSR} ]; then
        printf "Creating new 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'VAULT_INTR_CA_OCSP_ROLE' [${VAULT_INTR_CA_OCSP_ROLE}]\n"
        vault write ${VAULT_INTR_CA_PATH}/sign/${VAULT_INTR_CA_OCSP_ROLE} \
        ttl=${VAULT_INTR_CA_OCSP_TTL} \
        csr=@${VAULT_INTR_CA_OCSP_CSR} | \
        jq -r '.data.certificate' > ${VAULT_INTR_CA_OCSP_PEM}
        # sed -n '/certificate/,/END CERTI/p' | sed 's/certificate\s*//g' > ${VAULT_INTR_CA_OCSP_PEM}
    else
        printf "Error creating 'VAULT_INTR_CA_OCSP_CSR' [${VAULT_INTR_CA_OCSP_CSR}], check 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}] and 'OPENSSL_CONF' [${OPENSSL_CA_CONF}]\n"
        exit 1
    fi
}

verify_vault_intr_ca_ocsp_dgst()
{
    printf "Verifying 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    openssl x509 -pubkey -in ${VAULT_INTR_CA_OCSP_PEM} -out ${VAULT_INTR_CA_OCSP_PEM}.pubkey
    DIGEST="verify"
    echo $DIGEST | openssl dgst -sha256 -engine pkcs11 -keyform engine -sign "${HSM_OCSP_PKCS11_URI}" -out ${VAULT_INTR_CA_OCSP_PEM}.out.sig 2>&1 || true
    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${VAULT_INTR_CA_OCSP_PEM}.pubkey -signature ${VAULT_INTR_CA_OCSP_PEM}.out.sig 2>&1 || true )
    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]\n"
    else
        printf "Error verifying 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'HSM_OCSP_PKCS11_URI_SAFE' [${HSM_OCSP_PKCS11_URI_SAFE}]:\n${RESULT}\n"
        exit 1
    fi
}

verify_vault_intr_ca_ocsp_crl_check()
{
    init_vault_intr_ca_crl_chain

    printf "Verifying 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"

    RESULT=$(openssl verify -crl_check -CAfile ${VAULT_INTR_CA_CRL_CHAIN_PEM} ${VAULT_INTR_CA_OCSP_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Verified 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${VAULT_INTR_CA_CRL_CHAIN_PEM}
        exit 1        
    fi
}

validate_vault_intr_ca_ocsp()
{
    if [ ! -f ${VAULT_INTR_CA_OCSP_PEM} ]; then
        printf "Could not find existing 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}]\n'INIT_VAULT_INTR_CA_OCSP' [${INIT_VAULT_INTR_CA_OCSP}]\n"
        if [ "$INIT_VAULT_INTR_CA_OCSP" == true ]; then
            init_vault_intr_ca_ocsp
        else
            exit 1
        fi
    else
        printf "Found existing 'VAULT_INTR_CA_OCSP_PEM' [${VAULT_INTR_CA_OCSP_PEM}]\n"
    fi

    # Generated certificates can have the CRL location and the location of the issuing certificate encoded.
    printf "Writing new 'VAULT_INTR_CA_URL' [${VAULT_INTR_CA_URL}], 'VAULT_INTR_CA_CRL_URL' [${VAULT_INTR_CA_CRL_URL}] and 'VAULT_INTR_CA_OCSP_URL' [${VAULT_INTR_CA_OCSP_URL}] url configuration to 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/config/urls\n"
    vault write ${VAULT_INTR_CA_PATH}/config/urls \
        issuing_certificates="${VAULT_INTR_CA_URL}" \
        crl_distribution_points="${VAULT_INTR_CA_CRL_URL}" \
        ocsp_servers="${VAULT_INTR_CA_OCSP_URL}"

    verify_vault_intr_ca_ocsp_dgst

    verify_vault_intr_ca_ocsp_crl_check
}


init_vault_intr_ca_client()
{
    # Generate key
    #openssl genrsa -out ${USER}.key 2048
    #openssl req -config ./openssl-user.conf -new -key ${USER}.key -nodes -out ${USER}.csr
    vault write ${VAULT_INTR_CA_PATH}/issue/${VAULT_INTR_CA_CLIENT_ROLE} \
    ttl="${VAULT_INTR_CA_CLIENT_TTL}" \
    common_name="${VAULT_INTR_CA_CLIENT_CN}" > ${VAULT_INTR_CA_CLIENT_KEY}

    cat ${VAULT_INTR_CA_CLIENT_KEY} | jq -r '.data.certificate' > ${VAULT_INTR_CA_CLIENT_PEM}
    cat ${VAULT_INTR_CA_CLIENT_KEY} | jq -r '.data.ca_chain[]' >> ${VAULT_INTR_CA_CLIENT_PEM}
    cat <<< $( jq -r '.data.private_key' ${VAULT_INTR_CA_CLIENT_KEY} ) > ${VAULT_INTR_CA_CLIENT_KEY}
}

verify_vault_intr_ca_client_dgst()
{
    printf "Verifying 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CLIENT_KEY' [${VAULT_INTR_CA_CLIENT_KEY}]\n"
    openssl x509 -pubkey -in ${VAULT_INTR_CA_CLIENT_PEM} -out ${VAULT_INTR_CA_CLIENT_PEM}.pubkey
    DIGEST="verify"
    echo $DIGEST | openssl dgst -sha256 -sign ${VAULT_INTR_CA_CLIENT_KEY} -out ${VAULT_INTR_CA_CLIENT_PEM}.out.sig 2>&1 || true
    RESULT=$(echo $DIGEST | openssl dgst -sha256 -verify ${VAULT_INTR_CA_CLIENT_PEM}.pubkey -signature ${VAULT_INTR_CA_CLIENT_PEM}.out.sig 2>&1 || true )
    if [ "$RESULT" == 'Verified OK' ]; then
        printf "Verified 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CLIENT_KEY' [${VAULT_INTR_CA_CLIENT_KEY}]\n"
    else
        printf "Error verifying 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CLIENT_KEY' [${VAULT_INTR_CA_CLIENT_KEY}]:\n${RESULT}\n"
        exit 1
    fi
}

verify_vault_intr_ca_client_crl_check()
{
    init_vault_intr_ca_crl_chain

    printf "Verifying 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"

    RESULT=$(openssl verify -crl_check -CAfile ${VAULT_INTR_CA_CRL_CHAIN_PEM} ${VAULT_INTR_CA_CLIENT_PEM} | awk '{print $2}' || true )

    if [ "${RESULT}" == 'OK' ]; then
        printf "Validated 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error verifying 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${VAULT_INTR_CA_CRL_CHAIN_PEM}
        exit 1        
    fi
}

revoke_vault_intr_ca_client()
{
    SERIAL=`openssl x509 -noout -serial -in ${VAULT_INTR_CA_CLIENT_PEM} | sed 's/.*=//g;s/../&:/g;s/:$//'`
    printf "Revoking 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_PATH' [${VAULT_INTR_CA_PATH}]/revoke and 'SERIAL' [${SERIAL}]\n"
    # revoke
    vault write ${VAULT_INTR_CA_PATH}/revoke \
        serial_number=${SERIAL}
}

verify_vault_intr_ca_client_revoke()
{
    init_vault_intr_ca_crl_chain

    printf "Verifying revoke of 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"
    
    RESULT=$(openssl verify -crl_check -CAfile ${VAULT_INTR_CA_CRL_CHAIN_PEM} ${VAULT_INTR_CA_CLIENT_PEM} 2>&1 || true )

    if echo "${RESULT}" | grep -q "lookup: certificate revoked"; then
        printf "Successfully revoked 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}] with 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]\n"
    else
        printf "Error revoking 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}], check 'VAULT_INTR_CA_CRL_CHAIN_PEM' [${VAULT_INTR_CA_CRL_CHAIN_PEM}]:\n${RESULT}\n"
        cat ${VAULT_INTR_CA_CRL_CHAIN_PEM}
        exit 1
    fi
}

validate_vault_intr_ca_client()
{
    if [ ! -f ${VAULT_INTR_CA_CLIENT_PEM} ]; then
        printf "Could not find existing 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}]\n'INIT_VAULT_INTR_CA_CLIENT' [${INIT_VAULT_INTR_CA_CLIENT}] and 'TEST_VAULT_REVOKE' [${TEST_VAULT_REVOKE}]\n"
        if [ "$INIT_VAULT_INTR_CA_CLIENT" == true ]; then
            init_vault_intr_ca_client

            # Optionally revoke VAULT_INTR_CA_CLIENT
            if [ "${TEST_VAULT_REVOKE}" == true ]; then
                revoke_vault_intr_ca_client
            fi
        else
            exit 1
        fi
    else
        printf "Found existing 'VAULT_INTR_CA_CLIENT_PEM' [${VAULT_INTR_CA_CLIENT_PEM}]\n"
    fi

    verify_vault_intr_ca_client_dgst

    # Optionally revoke VAULT_INTR_CA_CLIENT
    if [ "${TEST_VAULT_REVOKE}" == true ]; then
        verify_vault_intr_ca_client_revoke
    else
        verify_vault_intr_ca_client_crl_check
    fi
}

validate_vault_k8s_auth()
{
    # Enable the Kubernetes auth method at the default path ("auth/kubernetes")
    printf "Enabling vault kubernetes auth\n"
    vault auth enable kubernetes

    # Tell Vault how to communicate with the Kubernetes cluster
    printf "Writing 'K8S_TOKEN_REVIEWER_JWT_SAFE' [${K8S_TOKEN_REVIEWER_JWT_SAFE}] as vault kubernetes auth token reviewer\n"
    vault write auth/kubernetes/config \
        token_reviewer_jwt="$K8S_TOKEN_REVIEWER_JWT" \
        kubernetes_host="$K8S_APISERVER" \
        kubernetes_ca_cert="$K8S_CA_CRT"
}

init_vault_admin_k8s_auth()
{
# Create a policy that enables access to the PKI secrets engine paths.
    printf "Writing 'VAULT_ADMIN_POLICY' [${VAULT_ADMIN_POLICY}]\n"
    if [ ! -f "${VAULT_ADMIN_POLICY}" ]; then
        cat <<EOF > "${VAULT_ADMIN_POLICY}"
# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# To list policies - Step 3
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create and manage secrets engines broadly across Vault.
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# To perform Step 4
path "sys/capabilities"
{
  capabilities = ["create", "update"]
}

# To perform Step 4
path "sys/capabilities-self"
{
  capabilities = ["create", "update"]
}
EOF
    fi

    vault policy write ${VAULT_ADMIN_ROLE} ${VAULT_ADMIN_POLICY}

    # Create a role to map Kubernetes Service Account to
    # Vault policies and default token TTL
    printf "Binding 'VAULT_ADMIN_SA' [${VAULT_ADMIN_SA}] with 'VAULT_ADMIN_ROLE' [${VAULT_ADMIN_ROLE}] role and policies\n"
    vault write auth/kubernetes/role/${VAULT_ADMIN_ROLE} \
        bound_service_account_names=${VAULT_ADMIN_SA} \
        bound_service_account_namespaces=${VAULT_ADMIN_SA_NAMESPACE} \
        policies=${VAULT_ADMIN_ROLE} ttl=${VAULT_ADMIN_SA_TTL}
}

validate_vault_admin_k8s_auth()
{
    printf "Checking if 'VAULT_ADMIN_SA_TOKEN_SAFE' [${VAULT_ADMIN_SA_TOKEN_SAFE}] is valid for 'VAULT_ADMIN_ROLE' [${VAULT_ADMIN_ROLE}] role\n"
    TOKEN=$(curl -s \
        --request POST \
        --data "{\"jwt\": \"${VAULT_ADMIN_SA_TOKEN}\", \"role\": \"${VAULT_ADMIN_ROLE}\"}" \
        ${VAULT_ADDR}/v1/auth/kubernetes/login | jq -r '.auth?.client_token')

    if [ -z ${TOKEN} ] || [ "${TOKEN}" == "null" ]; then
        printf "'VAULT_ADMIN_SA' [${VAULT_ADMIN_SA}] is not valid for 'VAULT_ADMIN_ROLE' [${VAULT_ADMIN_ROLE}]\n'INIT_VAULT_ADMIN_K8S_AUTH' [${INIT_VAULT_ADMIN_K8S_AUTH}]\n"
        if [ "${INIT_VAULT_ADMIN_K8S_AUTH}" == true ]; then
            init_vault_admin_k8s_auth
        else
            exit 1
        fi
    else
         printf "'VAULT_ADMIN_SA' [${VAULT_ADMIN_SA}] is valid for 'VAULT_ADMIN_ROLE' [${VAULT_ADMIN_ROLE}]\n"
    fi
}

init_vault_root_ca_k8s_auth()
{
    # Create a policy that enables access to the PKI secrets engine paths.
    printf "Writing 'VAULT_ROOT_CA_POLICY' [${VAULT_ROOT_CA_POLICY}]\n"
    if [ ! -f "${VAULT_ROOT_CA_POLICY}" ]; then
        cat <<EOF > "${VAULT_ROOT_CA_POLICY}"
path "${VAULT_ROOT_CA_PATH}*"                                   { capabilities = ["read", "list"] }
path "${VAULT_ROOT_CA_PATH}/roles/${VAULT_ROOT_CA_OCSP_ROLE}"   { capabilities = ["create", "update"] }
path "${VAULT_ROOT_CA_PATH}/sign/${VAULT_ROOT_CA_OCSP_ROLE}"    { capabilities = ["create", "update"] }
path "${VAULT_ROOT_CA_PATH}/issue/${VAULT_ROOT_CA_OCSP_ROLE}"   { capabilities = ["create"] }
path "${VAULT_ROOT_CA_PATH}/roles/${VAULT_ROOT_CA_INTR_ROLE}"   { capabilities = ["create", "update"] }
path "${VAULT_ROOT_CA_PATH}/sign/${VAULT_ROOT_CA_INTR_ROLE}"    { capabilities = ["create", "update"] }
path "${VAULT_ROOT_CA_PATH}/issue/${VAULT_ROOT_CA_INTR_ROLE}"   { capabilities = ["create"] }
EOF
    fi

    vault policy write ${VAULT_ROOT_CA_ROLE} ${VAULT_ROOT_CA_POLICY}
    # Create a role to map Kubernetes Service Account to
    # Vault policies and default token TTL
    printf "Binding 'VAULT_ROOT_CA_SA' [${VAULT_ROOT_CA_SA}] with 'VAULT_ROOT_CA_ROLE' [${VAULT_ROOT_CA_ROLE}] role and policies\n"
    vault write auth/kubernetes/role/${VAULT_ROOT_CA_ROLE} \
        bound_service_account_names=${VAULT_ROOT_CA_SA} \
        bound_service_account_namespaces=${VAULT_ROOT_CA_SA_NAMESPACE} \
        policies=${VAULT_ROOT_CA_ROLE} ttl=${VAULT_ROOT_CA_SA_TTL}
}

validate_vault_root_ca_k8s_auth()
{
    printf "Checking if 'VAULT_ROOT_CA_SA_TOKEN_SAFE' [${VAULT_ROOT_CA_SA_TOKEN_SAFE}] token is valid for 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}] role\n"
    TOKEN=$(curl -s \
        --request POST \
        --data "{\"jwt\": \"${VAULT_ROOT_CA_SA_TOKEN}\", \"role\": \"${VAULT_ROOT_CA_PATH}\"}" \
        ${VAULT_ADDR}/v1/auth/kubernetes/login | jq -r '.auth?.client_token')
    
    if [ -z ${TOKEN} ] || [ "${TOKEN}" == "null" ]; then
        printf "'VAULT_ROOT_CA_SA' [${VAULT_ROOT_CA_SA}] token is not valid for 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}] role\n'INIT_VAULT_ROOT_CA_K8S_AUTH' [${INIT_VAULT_ROOT_CA_K8S_AUTH}]\n"
        if [ "${INIT_VAULT_ROOT_CA_K8S_AUTH}" == true ]; then
            init_vault_root_ca_k8s_auth
        else
            exit 1
        fi
    else
        printf "'VAULT_ROOT_CA_SA' [${VAULT_ROOT_CA_SA}] token is valid for 'VAULT_ROOT_CA_PATH' [${VAULT_ROOT_CA_PATH}] role\n"
    fi
}

init_vault_intr_ca_k8s_auth()
{
 # Create a policy that enables access to the PKI secrets engine paths.
    printf "Writing 'VAULT_INTR_CA_POLICY' [${VAULT_INTR_CA_POLICY}]\n"
    if [ ! -f "${VAULT_INTR_CA_POLICY}" ]; then
        cat <<EOF > "${VAULT_INTR_CA_POLICY}"
path "${VAULT_INTR_CA_PATH}*"                                   { capabilities = ["read", "list"] }
path "${VAULT_INTR_CA_PATH}/roles/${VAULT_INTR_CA_OCSP_ROLE}"   { capabilities = ["create", "update"] }
path "${VAULT_INTR_CA_PATH}/sign/${VAULT_INTR_CA_OCSP_ROLE}"    { capabilities = ["create", "update"] }
path "${VAULT_INTR_CA_PATH}/issue/${VAULT_INTR_CA_OCSP_ROLE}"   { capabilities = ["create"] }
path "${VAULT_INTR_CA_PATH}/roles/${VAULT_INTR_CA_CLIENT_ROLE}" { capabilities = ["create", "update"] }
path "${VAULT_INTR_CA_PATH}/sign/${VAULT_INTR_CA_CLIENT_ROLE}"  { capabilities = ["create", "update"] }
path "${VAULT_INTR_CA_PATH}/issue/${VAULT_INTR_CA_CLIENT_ROLE}" { capabilities = ["create"] }
EOF
    fi
    vault policy write ${VAULT_INTR_CA_ROLE} ${VAULT_INTR_CA_POLICY}
    # Create a role to map Kubernetes Service Account to
    # Vault policies and default token TTL
    printf "Binding 'VAULT_INTR_CA_SA' [${VAULT_INTR_CA_SA}] with 'VAULT_INTR_CA_ROLE' [${VAULT_INTR_CA_ROLE}] role and policies\n"
    vault write auth/kubernetes/role/${VAULT_INTR_CA_ROLE} \
        bound_service_account_names=${VAULT_INTR_CA_SA} \
        bound_service_account_namespaces=${VAULT_INTR_CA_SA_NAMESPACE} \
        policies=${VAULT_INTR_CA_ROLE} ttl=${VAULT_INTR_CA_SA_TTL}
}


validate_vault_intr_ca_k8s_auth()
{
    printf "Checking if 'VAULT_INTR_CA_SA_TOKEN_SAFE' [${VAULT_INTR_CA_SA_TOKEN_SAFE}] is valid for 'VAULT_INTR_CA_ROLE' [${VAULT_INTR_CA_ROLE}]\n"
    TOKEN=$(curl -s \
        --request POST \
        --data "{\"jwt\": \"${VAULT_INTR_CA_SA_TOKEN}\", \"role\": \"${VAULT_INTR_CA_PATH}\"}" \
        ${VAULT_ADDR}/v1/auth/kubernetes/login | jq -r '.auth?.client_token')
    
    if [ -z ${TOKEN} ] || [ "${TOKEN}" == "null" ]; then
        printf "'VAULT_INTR_CA_SA' [${VAULT_INTR_CA_SA}] is not valid for 'VAULT_INTR_CA_ROLE' [${VAULT_INTR_CA_ROLE}]\n'INIT_VAULT_INTR_CA_K8S_AUTH' [${INIT_VAULT_INTR_CA_K8S_AUTH}]\n"
        if [ "${INIT_VAULT_INTR_CA_K8S_AUTH}" == true ]; then
           init_vault_intr_ca_k8s_auth
        else
            exit 1
        fi
    else
        printf "'VAULT_INTR_CA_SA' [${VAULT_INTR_CA_SA}] is valid for 'VAULT_INTR_CA_ROLE' [${VAULT_INTR_CA_ROLE}] role\n"
    fi
}

init_vault_ocsp_k8s_auth()
{
 # Create a policy that enables access to the PKI secrets engine paths.
    printf "Writing 'VAULT_OCSP_POLICY' [${VAULT_OCSP_POLICY}]\n"

    if [ ! -f "${VAULT_OCSP_POLICY}" ]; then
        cat <<EOF > "${VAULT_OCSP_POLICY}"
path "${VAULT_ROOT_CA_PATH}*" { capabilities = ["read", "list"] }
path "${VAULT_INTR_CA_PATH}*" { capabilities = ["read", "list"] }
EOF
    fi

    vault policy write ${VAULT_OCSP_ROLE} ${VAULT_OCSP_POLICY}
    # Create a role to map Kubernetes Service Account to
    # Vault policies and default token TTL
    printf "Binding 'VAULT_OCSP_SA' [${VAULT_OCSP_SA}] with 'VAULT_OCSP_ROLE' [${VAULT_OCSP_ROLE}] role and policies\n"
    vault write auth/kubernetes/role/${VAULT_OCSP_ROLE} \
        bound_service_account_names=${VAULT_OCSP_SA} \
        bound_service_account_namespaces=${VAULT_OCSP_SA_NAMESPACE} \
        policies=${VAULT_OCSP_ROLE} ttl=${VAULT_OCSP_SA_TTL}
}

validate_vault_ocsp_k8s_auth()
{
    printf "Checking if 'VAULT_OCSP_SA_TOKEN_SAFE' [${VAULT_OCSP_SA_TOKEN_SAFE}] is valid for 'VAULT_OCSP_ROLE' [${VAULT_OCSP_ROLE}] role\n"
    TOKEN=$(curl -s \
        --request POST \
        --data "{\"jwt\": \"${VAULT_OCSP_SA_TOKEN}\", \"role\": \"${VAULT_OCSP_ROLE}\"}" \
        ${VAULT_ADDR}/v1/auth/kubernetes/login | jq -r '.auth?.client_token')
    
    if [ -z ${TOKEN} ] || [ "${TOKEN}" == "null" ]; then
        printf "'VAULT_OCSP_SA' [${VAULT_OCSP_SA}] is not valid for 'VAULT_OCSP_ROLE' [${VAULT_OCSP_ROLE}] role\n'INIT_VAULT_OCSP_K8S_AUTH' [${INIT_VAULT_OCSP_K8S_AUTH}]\n"
        if [ "${INIT_VAULT_OCSP_K8S_AUTH}" == true ]; then
            init_vault_ocsp_k8s_auth
        else
            exit 1
        fi
    else
        printf "'VAULT_OCSP_SA' [${VAULT_OCSP_SA}] is valid for 'VAULT_OCSP_ROLE' [${VAULT_OCSP_PATH}] role\n"
    fi
}

test_pki_good_openssl_ca_source()
{
    printf "Verifying 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM} -issuer ${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": good" ); then
        printf "Verified 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
    else
        printf "Error verifying 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
        exit 1
    fi
}

test_pki_revoked_openssl_ca_source()
{
    printf "Verifying 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL}] and 'TEST_OPENSSL_REVOKE' [${TEST_OPENSSL_REVOKE}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM} -issuer ${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": revoked" ); then
        printf "Verified 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL}] and 'TEST_OPENSSL_REVOKE' [${TEST_OPENSSL_REVOKE}]\n"
    else
        printf "Error verifying 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL}] and 'TEST_OPENSSL_REVOKE' [${TEST_OPENSSL_REVOKE}]\n"
        exit 1
    fi
}

test_pki_unknown_openssl_ca_source()
{
    printf "Verifying 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM} -issuer ${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": unknown" ); then
        printf "Verified 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
    elif ( ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": No Status found." ) ) || ( echo "${RESULT}" | grep -q "Error querying OCSP responder" ); then
        # TODO: Remove once hsmocsp is updated to properly respond and trigger unknown status
        printf "Warning unable to verify 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
    else
        printf "Error verifying 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM}] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL}]\n"
        exit 1
    fi
}

test_pki_good_vault_ca_source()
{
    printf "Verifying 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM}.fullchain -issuer ${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": good" ); then
        printf "Verified 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL}]\n"
    else
        printf "Error verifying'TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL}]\n"
        exit 1
    fi
}

test_pki_revoked_vault_ca_source()
{
    printf "Verifying 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL}] and 'TEST_VAULT_REVOKE' [${TEST_VAULT_REVOKE}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM}.fullchain -issuer ${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": revoked" ); then
        printf "Verified 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL}] and 'TEST_VAULT_REVOKE' [${TEST_VAULT_REVOKE}]\n"
    else
        printf "Error verifying 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL}] and 'TEST_VAULT_REVOKE' [${TEST_VAULT_REVOKE}]\n"
        exit 1
    fi
}

test_pki_unknown_vault_ca_source()
{
    printf "Verifying 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL}]\n"
    RESULT=$(openssl ocsp -CAfile ${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM}.fullchain -issuer ${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM} -cert ${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM} -url ${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL} 2>&1 || true )
    printf "${RESULT}\n"

    if ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": unknown" ); then
        printf "Verified 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL}]\n"
    elif ( ( echo "${RESULT}" | grep -q "Response verify OK" ) && ( echo "${RESULT}" | grep -q ": No Status found." ) ) || ( echo "${RESULT}" | grep -q "Error querying OCSP responder" ); then
        # TODO: Remove once vault-ocsp is updated to properly respond and trigger unknown status
        printf "Warning unable to verify 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL}]\n"
    else
        printf "Error verifying 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM}] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM}].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL}]\n"
        exit 1
    fi
}

init_test_pki_secret()
{
    printf "'INIT_TEST_PKI_SECRET' [${INIT_TEST_PKI_SECRET}]\nInitalizing 'TEST_PKI_SECRET' [${TEST_PKI_SECRET}] with 'TEST_PKI_SECRET_DIR' [${TEST_PKI_SECRET_DIR}] and 'K8S_SA_JWT_TOKEN_SAFE' [${K8S_SA_JWT_TOKEN_SAFE}]\n"
    
    if [ "${TEST_PKI_OPENSSL_CA_SOURCE}" == true ]; then
        # Append Env File
        tee -a ${TEST_PKI_SECRET_ENV_FILE} &>/dev/null <<EOF
# OpenSSL CA Source
TEST_PKI_OPENSSL_CA_SOURCE="\${TEST_PKI_OPENSSL_CA_SOURCE:-$VALIDATE_OPENSSL_CA}"
TEST_PKI_OPENSSL_CA_REVOKE="\${TEST_PKI_OPENSSL_CA_REVOKE:-$TEST_OPENSSL_REVOKE}"

TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM="\${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM:-$OPENSSL_CA_PEM}"
TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL="\${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL:-$OPENSSL_CA_OCSP_URL}"
TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM="\${TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM:-$OPENSSL_CA_OCSP_PEM}"

TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM="\${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM:-$OPENSSL_CA_PEM}"
TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL="\${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL:-$OPENSSL_CA_OCSP_URL}"
TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM="\${TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM:-$OPENSSL_INT_PEM}"

TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM="\${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM:-$OPENSSL_CA_PEM}"
TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL="\${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL:-$OPENSSL_CA_OCSP_URL}"
TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM="\${TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM:-$OPENSSL_CA_PEM}"
EOF
    fi

    if [ "${TEST_PKI_VAULT_CA_SOURCE}" == true ]; then
        # Append Env File
        tee -a ${TEST_PKI_SECRET_ENV_FILE} &>/dev/null <<EOF
# Vault CA Source
TEST_PKI_VAULT_CA_SOURCE="\${TEST_PKI_VUALT_CA_SOURCE:-$VALIDATE_VAULT_ROOT_CA}"
TEST_PKI_VAULT_CA_REVOKE="\${TEST_PKI_VAULT_CA_REVOKE:-$TEST_VAULT_REVOKE}"

TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM="\${TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM:-$VAULT_ROOT_CA_PEM}"
TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL="\${TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL:-$VAULT_ROOT_CA_OCSP_URL}"
TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM="\${TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM:-$VAULT_ROOT_CA_OCSP_PEM}"

TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM="\${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM:-$VAULT_INTR_CA_PEM}"
TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL="\${TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL:-$VAULT_INTR_CA_OCSP_URL}"
TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM="\${TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM:-$VAULT_INTR_CA_CLIENT_PEM}"

TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM="\${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM:-$VAULT_ROOT_CA_PEM}"
TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL="\${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL:-$VAULT_ROOT_CA_OCSP_URL}"
TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM="\${TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM:-$VAULT_ROOT_CA_PEM}"
EOF

    fi

    # add files
    kubectl create secret generic -n ${K8S_SA_NAMESPACE} ${TEST_PKI_SECRET} --from-file=${TEST_PKI_SECRET_DIR}

    K8S_SA_LABELS=$( kubectl get serviceaccounts -n ${K8S_SA_NAMESPACE} ${K8S_SA} -o json \
    | jq -r '.metadata.labels // {"app.kubernetes.io/name": "app-hsmocsp"}' )
    printf "Patching ${TEST_PKI_SECRET} with 'K8S_SA_LABELS' [${K8S_SA_LABELS}]\n"
    
    kubectl patch secret -n ${K8S_SA_NAMESPACE} ${TEST_PKI_SECRET} -p "{\"metadata\":{\"labels\":$K8S_SA_LABELS}}"
}

if [ "$1" = 'init' ]; then
    set -m
    
    printf "Init PKI is recommended for development purposes only\n"

    if [ "${VALIDATE_HSM}" == true ]; then
        # Validate HSM Module
        validate_hsm_module

        # Validate HSM Slot ID
        validate_hsm_slotid

        # Validate HSM_CA KeyPair exists
        validate_hsm_ca_keypair

        # Validate HSM_OCSP KeyPair exists
        validate_hsm_ocsp_keypair

        # Validate HSM_INT KeyPair exists
        validate_hsm_int_keypair
    fi

    if [ "${VALIDATE_OPENSSL_CA}" == true ]; then
        # Validate OPENSSL_CA_CONF
        validate_openssl_ca_config

        # Validate OPENSSL_CA_PEM
        validate_openssl_ca_cert

        # Vaidate OPENSSL_CA_CERTINDEX
        validate_openssl_ca_certindex

        # Validate OPENSSL_CA_OCSP_PEM
        validate_openssl_ca_ocsp_cert
    fi

    if [ "${VALIDATE_OPENSSL_INT}" == true ]; then
        # Validate OPENSSL_INT_PEM
        validate_openssl_int_cert
    fi

    # Validate Vault Server
    if [ "${VALIDATE_VAULT_SERVER}" == true ]; then
        # check VAULT_TOKEN or enable vault dev
        validate_vault_server
    fi

    # Validate vault kubernetes authentication
    if [ "${VALIDATE_VAULT_K8S_AUTH}"  == true ]; then
        # enable kubernetes auth with token reviewer jwt
        validate_vault_k8s_auth
    fi

    # Validate vault admin role
    if [ "${VALIDATE_VAULT_ADMIN_K8S_AUTH}"  == true ]; then
        # enable k8s auth vault admin role and bind sa
        validate_vault_admin_k8s_auth
    fi

    # Validate Vault Agent
    if [ "${VALIDATE_VAULT_AGENT}" == true ]; then
        # check VAULT_TOKEN or enable vault agent from config
        validate_vault_agent
    fi
    
    # Validate Vault root CA
    if [ "${VALIDATE_VAULT_ROOT_CA}" == true ]; then
        # enable intermediate pki secrets engine, root and ocsp roles, and gen ca certs
        validate_vault_root_ca

        # enable k8s auth root ca policy, role and bind sa
        validate_vault_root_ca_k8s_auth

        # gen root ocsp cert and set ocsp url
        validate_vault_root_ca_ocsp
    fi

    # Validate Vault intermediate CA
    if [ "${VALIDATE_VAULT_INTR_CA}" == true ]; then
        # enable intermediate pki secrets engine, intr and ocsp roles, and gen ca certs
        validate_vault_intr_ca

        # enable k8s auth intermediate ca policy, role and bind sa
        validate_vault_intr_ca_k8s_auth

        # gen intermediate ocsp cert and set ocsp url
        validate_vault_intr_ca_ocsp
    fi

    # Validate Vault intermediate CA Client
    if [ "${VALIDATE_VAULT_INTR_CA_CLIENT}" == true ]; then
        # enable intermediate pki secrets engine, intr and ocsp roles, and gen ca certs
        validate_vault_intr_ca_client
    fi

    # Validate Vault
    if [ "${VALIDATE_VAULT_OCSP_K8S_AUTH}"  == true ]; then
        # enable k8s auth vault ocsp role and bind sa
        validate_vault_ocsp_k8s_auth
    fi

    # Initialize test pki secret
    if [ "${INIT_TEST_PKI_SECRET}" == true ]; then
        init_test_pki_secret
    fi

    # forground previous job (should be either vault dev server or agent)
    set -- printf "Init PKI completed successfully; returning previous job to forground: 'VALIDATE_VAULT_SERVER' [${VALIDATE_VAULT_SERVER}] or 'VALIDATE_VAULT_AGENT' [${VALIDATE_VAULT_AGENT}]\n"
    fg %-
elif [ "$1" = 'test' ]; then
    source $TEST_PKI_SECRET_ENV_FILE

    # Validate OpenSSL CA Source Type
    if [ "${TEST_PKI_OPENSSL_CA_SOURCE}" == true ] ; then
        # Test good response from OpenSSL CA OCSP URL
        test_pki_good_openssl_ca_source

        # Test revoked resposne from OpenSSL CA OCSP URL
        if [ "${TEST_PKI_OPENSSL_CA_REVOKE}" == true ]; then
            test_pki_revoked_openssl_ca_source
        fi

        # Test unknown response from OpenSSL CA OCSP URL
        test_pki_unknown_openssl_ca_source
    fi

    # Validate Vault CA Source Type
    if [ "${TEST_PKI_VAULT_CA_SOURCE}" == true ] ; then
        # Test good response from Vaut Root CA OCSP URL
        test_pki_good_vault_ca_source

        # Test revoked resposne from Vaut INTR CA OCSP URL
        if [ "${TEST_PKI_VAULT_CA_REVOKE}" == true ]; then
            test_pki_revoked_vault_ca_source
        fi

        # Test unknown response from OpenSSL CA OCSP URL
        test_pki_unknown_vault_ca_source

        set -- printf "Test PKI completed successfully with 'TEST_PKI_OPENSSL_CA_SOURCE' [${TEST_PKI_OPENSSL_CA_SOURCE}], 'TEST_PKI_OPENSSL_CA_REVOKE' [${TEST_PKI_OPENSSL_CA_REVOKE}], 'TEST_PKI_VAULT_CA_SOURCE' [${TEST_PKI_VAULT_CA_SOURCE}], and 'TEST_PKI_VAULT_CA_REVOKE' [${TEST_PKI_VAULT_CA_REVOKE}]\n"
    fi
elif [ "$1" = 'pcscd' ]; then
    # The SmartCard daemon has to be started to communicate with plugged in HSM devices
    # https://pcsclite.apdu.fr/
    rm -f /var/run/pcscd/*
    set -- pcscd --debug --foreground
fi

exec "$@"