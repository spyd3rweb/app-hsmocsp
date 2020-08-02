# Hardware Security Module (HSM) Online Certificate Status Protocol (OCSP)

This [cloud-native application](https://cloud.google.com/blog/products/application-development/kubernetes-development-simplified-skaffold-is-now-ga) deploys an [OCSP](https://en.wikipedia.org/wiki/Online_Certificate_Status_Protocol) server that is capable of using a physical [PKCS#11 HSM](https://en.wikipedia.org/wiki/PKCS_11), such as the [NitroKey HSM](https://shop.nitrokey.com/shop/product/nk-hsm-2-nitrokey-hsm-2-7), as the signer for the ocsp responder.  When properly configured, the [hsmocsp](https://github.com/spyd3rweb/hsmocsp) server will return a signed response signifying that the certificate specified in the request is 'good', 'revoked', or 'unknown'. If it cannot process the request, it will return an error code.

## Supported [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority) Sources

The hsmocsp server currently supports two source types which implement the [cfssl ocsp responder interface](https://github.com/cloudflare/cfssl/blob/master/ocsp/responder.go) to verify certificates; additional support for cfssl certdb and response file sources could likely easily be added.

|  Source Type  |                         Description                         |
|---------------|-------------------------------------------------------------|
|[OpenSslSource](https://github.com/spyd3rweb/hsmocsp)|Uses the [OpenSSL](https://github.com/openssl/openssl) [ca db](https://pki-tutorial.readthedocs.io/en/latest/cadb.html) and crl files; optionally supports hosting ca issuer and crl static files
|[VaultSource](https://github.com/T-Systems-MMS/vault-ocsp)|Uses the [Vault PKI Engine](https://www.vaultproject.io/docs/secrets/pki) ca and crl urls and cert api|

 ## Example [PKI](https://pki-tutorial.readthedocs.io/en/latest/) Hierarchy

       [ OpenSSL Root CA ]
                |
       [ Vault Root CA 1]
                |
      [ Vault Int Dev CA 1]

A continerized pki helper script is provided to create a working PKCS#11 HSM PKI environment *for development purposes only*; it includes configurable steps to automatically validate and initialize:
* Certificates and Keypairs for the [OpenSSL Root CA](https://www.openssl.org/docs/man1.0.2/man1/ca.html)
* Vault PKI Secrets engines and intermediate CA certificates properly signed and chained with the OpenSSL ca-keypair
* Keypairs for OCSP server certificates for both OpenSSL and Vault CA sources for app-hsmocsp to consume

|PKI Level| Cert |HSM Key|Vault Key|File Key|
|--------|:-----|:-----:|:-------:|:------:|
|1|OpenSSL CA|x|||
|1|OpenSSL CA OCSP|x|||
|2|Vault Root CA||x||
|2|Vault Root CA OCSP|x|||
|3|Vault Int Dev CA||x||
|3|Vault Int Dev CA OCSP|x|||
|3|Vault Int Dev CA Client|||x|

## [Continuous Development](https://skaffold.dev/docs/workflows/dev/)
### For development, it is highly recommended to use [Google's Cloud Code](https://cloud.google.com/code/docs/vscode/debug) for [vscode](https://code.visualstudio.com/docs/languages/go); a [skaffold configuration](https://skaffold.dev/docs/references/yaml/) is provided with two profiles for build and deployment configurations as described in the following sections.

\* *validated with [kind](https://kind.sigs.k8s.io/docs/user/using-wsl2/) on [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)*

### [Skaffold Builders](https://skaffold.dev/docs/pipeline-stages/builders/)
* [Docker](https://skaffold.dev/docs/pipeline-stages/builders/docker/): In the images directory there are two [Dockerfiles](https://docs.docker.com/engine/reference/builder/):
  * app-hsmocsp - compiles the app-hsmocsp server; by default the container uses a config.yaml file from the '.config/hsmocsp/' dir for configuration.

  * app-pki - shell script which uses a PKCS#11 HSM, default [SoftHSMv2](https://github.com/opendnssec/SoftHSMv2), to create the example PKI Hierarchy; container uses environment variables for configuration in addition to a default ca.conf file in the '.config/pki' dir.

\* *sharing of a physical HSM, across containers within the pod, is accomplished using [pcscd](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/7/html/tuning_guide/the_pc_card_daemon) through a [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) volume mount to /var/run/pcscd/; this requires the app-hsmocsp-pcscd container to run as a privileged container in order to create /var/run/pcscd/pcscd.pid*

### [Skaffold Deployers](https://skaffold.dev/docs/pipeline-stages/deployers/)
Each of the following skaffold profiles deploys both the app-hsmocsp and app-pki containers, and uses a shared volume between them for sharing the hsm tokens and configured certificates

* [kubectl](https://skaffold.dev/docs/pipeline-stages/deployers/kubectl/): The provided [skaffold debug profile](https://skaffold.dev/docs/environment/profiles/) includes a set of [K8S manifests](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/) to create a [skaffold debug](https://skaffold.dev/docs/workflows/debug/) configuration capable of remote go debugging

* [Helm](https://skaffold.dev/docs/pipeline-stages/deployers/helm/): The provided [skaffold dev profile](https://skaffold.dev/docs/environment/profiles/) includes a [Helm Chart](https://helm.sh/docs/topics/charts/) to more easily override templated deployment configurations. 

\* *Note the Helm chart's default values use a [helm pre-install hook](https://helm.sh/docs/topics/charts_hooks/) to ensure the [vault-auth](https://www.vaultproject.io/docs/auth/kubernetes) service account is created prior to the other resources; this has the unfortunate side effect of sticking around after deployment/delete as [any resource that implements a hook is considered to be self-managed](https://github.com/helm/helm/issues/4434#issuecomment-410540722)*

## Testing
```
~$ POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=app-hsmocsp" -o jsonpath="{.items[0].metadata.name}")
~$ kubectl exec -it -n default ${POD_NAME} -c app-hsmocsp-pki -- /app/scripts/pki-entrypoint.sh test
Verifying 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM [/app/.config/pki/ocsp.cert.pem] with 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp]
WARNING: no nonce in response
Response verify OK
/app/.config/pki/ocsp.cert.pem: good
        This Update: Aug  2 04:19:51 2020 GMT
        Next Update: Aug  2 05:19:51 2020 GMT
Verified 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CERT_PEM [/app/.config/pki/ocsp.cert.pem] with 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_GOOD_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp]
Verifying 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM' [/app/.config/pki/int.cert.pem] with 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp] and 'TEST_OPENSSL_REVOKE' [true]
WARNING: no nonce in response
Response verify OK
/app/.config/pki/int.cert.pem: revoked
        This Update: Aug  2 04:19:51 2020 GMT
        Revocation Time: Aug  2 04:18:51 2020 GMT
Verified 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CERT_PEM' [/app/.config/pki/int.cert.pem] with 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_REVOKED_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp] and 'TEST_OPENSSL_REVOKE' [true]
Verifying 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [/app/.config/pki/ca.cert.pem] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp]
Error querying OCSP responder
139847006811968:error:27076072:OCSP routines:parse_http_line1:server response error:crypto/ocsp/ocsp_ht.c:260:Code=500,Reason=Internal Server Error
Warning unable to verify 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CERT_PEM [/app/.config/pki/ca.cert.pem] with 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.cert.pem] and 'TEST_PKI_UNKNOWN_OPENSSL_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/ocsp]
Verifying 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/ocsp.pki.cert.pem] with 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki.cert.pem].fullchain and 'TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki/ocsp]
WARNING: no nonce in response
Response verify OK
/app/.config/pki/ocsp.pki.cert.pem: good
        This Update: Aug  2 04:19:51 2020 GMT
        Next Update: Aug  2 05:19:51 2020 GMT
Verified 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/ocsp.pki.cert.pem] with 'TEST_PKI_GOOD_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki.cert.pem].fullchain and 'TEST_PKI_GOOD_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki/ocsp]
Verifying 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/user.pki_int_development.cert.pem] with 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki_int_development.cert.pem].fullchain and 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki_int_development/ocsp] and 'TEST_VAULT_REVOKE' [true]
WARNING: no nonce in response
Response verify OK
/app/.config/pki/user.pki_int_development.cert.pem: revoked
        This Update: Aug  2 04:19:51 2020 GMT
        Revocation Time: Aug  2 04:18:59 2020 GMT
Verified 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/user.pki_int_development.cert.pem] with 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki_int_development.cert.pem].fullchain and 'TEST_PKI_REVOKED_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki_int_development/ocsp] and 'TEST_VAULT_REVOKE' [true]
Verifying 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/ca.pki.cert.pem] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki.cert.pem].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki/ocsp]
WARNING: no nonce in response
Response verify OK
/app/.config/pki/ca.pki.cert.pem: ERROR: No Status found.
Warning unable to verify 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CERT_PEM' [/app/.config/pki/ca.pki.cert.pem] with 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_CA_PEM' [/app/.config/pki/ca.pki.cert.pem].fullchain and 'TEST_PKI_UNKNOWN_VAULT_CA_SOURCE_OCSP_URL' [http://app-hsmocsp/pki/ocsp]
Test PKI completed successfully with 'TEST_PKI_OPENSSL_CA_SOURCE' [true], 'TEST_PKI_OPENSSL_CA_REVOKE' [true], 'TEST_PKI_VAULT_CA_SOURCE' [true], and 'TEST_PKI_VAULT_CA_REVOKE' [true]
```

## Troubleshooting/Manual Deployment
If using the default app-pki container's example CA Hierarchy, it takes a minute or so to initialize all the certificates and Vault PKI Secrets Engines; the app-hsmocsp container should continue to restart until all requried certificates and hsm keypairs are successfully found in the shared volume.

### Manual/CLI Deployment with Skaffold
```
~$ SKAFFOLD_DEFAULT_REPO=<myrepo> ~/.cache/cloud-code/installer/google-cloud-sdk/bin/skaffold dev -v debug --port-forward --rpc-http-port 42535 --filename skaffold.yaml
```

### Manual/CLI Build with Docker
```
~$ SKAFFOLD_DEFAULT_REPO=<myrepo>
~$ docker build -t ${SKAFFOLD_DEFAULT_REPO}/app-hsmocsp -f images/Dockerfile.app-hsmocsp .

~$ docker build -t ${SKAFFOLD_DEFAULT_REPO}/app-pki -f images/Dockerfile.app-pki .

~$ docker push ${SKAFFOLD_DEFAULT_REPO}/app-hsmocsp:latest

~$ docker push ${SKAFFOLD_DEFAULT_REPO}/app-pki:latest
```


### Manual/CLI Deployment with Helm
```
~$ helm --kube-context kind-wslkind install --debug --name app-hsmocsp ./ --namespace default --set-string "image=${SKAFFOLD_DEFAULT_REPO}/app-hsmocsp:latest","extraImages.appPki=${SKAFFOLD_DEFAULT_REPO}/app-pki:latest","imageConfig.pullPolicy=Always" -f values.yaml
```

```
~$ helm delete --purge app-hsmocsp
```

If a skaffold kubectl or helm deployment fails and you want to remove all the default app-hsmocsp resources from your cluster, use the following commands
```
~$ kubectl delete all -l 'app.kubernetes.io/name'=app-hsmocsp -n default
pod "app-hsmocsp-XXXXXXXXX-XXXXX" deleted
deployment.apps "app-hsmocsp" deleted
replicaset.apps "app-hsmocsp-XXXXXXXXX" deleted

~$ kubectl delete configmaps,secrets,service,serviceaccounts,roles,clusterroles,rolebindings,clusterrolebindings -l 'app.kubernetes.io/name'=app-hsmocsp -n default
configmap "app-hsmocsp-config" deleted
configmap "app-hsmocsp-pki-config" deleted
configmap "app-hsmocsp-softhsm2-config" deleted
secret "app-hsmocsp-secret" deleted
secret "app-hsmocsp-test-pki-secret" deleted
secret "vault-auth-secret" deleted
service "app-hsmocsp" deleted
serviceaccount "app-hsmocsp" deleted
serviceaccount "vault-auth" deleted
rolebinding.rbac.authorization.k8s.io "app-hsmocsp-edit-binding" deleted
warning: deleting cluster-scoped resources, not scoped to the provided namespace
clusterrolebinding.rbac.authorization.k8s.io "role-tokenreview-binding" deleted
```

### Example for adding a kubernetes [extended resource](https://kubernetes.io/docs/tasks/administer-cluster/extended-resource-node/) for the Nitrokey HSM
Ref: https://banzaicloud.com/blog/vault-hsm/#kubernetes-node-setup
```
~$ kubectl proxy &

~$ NODE=minikube

~$ curl --header "Content-Type: application/json-patch+json" \
     --request PATCH \
     --data '[{"op": "add", "path": "/status/capacity/nitrokey.com~1hsm", "value": "1"}]' \
     http://localhost:8001/api/v1/nodes/${NODE}/status
```

