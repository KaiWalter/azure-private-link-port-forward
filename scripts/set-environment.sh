#!/bin/bash

set -e

azd env set SSH_PUBLIC_KEY "$(cat ~/.ssh/id_rsa.pub)"
azd env set CLOUD_INIT_ONPREM "$(cat ./infra/modules/onprem-server/cloud-init.txt | base64 -w 0)"
azd env set CLOUD_INIT_FWD "$(cat ./infra/modules/forwarder/cloud-init.txt | base64 -w 0)"
