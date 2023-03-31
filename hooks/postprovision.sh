#!/bin/bash

set -e

source <(azd env get-values | grep NAME)

az container stop -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container stop -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
