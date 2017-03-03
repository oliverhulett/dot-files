## Export CA certificate bundle to the environment
export CA_BUNDLE="/etc/pki/tls/certs/ca-bundle.crt"
export REQUESTS_CA_BUNDLE="$CA_BUNDLE"
export CURL_CA_BUNDLE="$CA_BUNDLE"
