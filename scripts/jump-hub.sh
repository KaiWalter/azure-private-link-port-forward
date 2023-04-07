#!/bin/bash

source <(azd env get-values | grep NAME)
az container start -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "/bin/bash"
