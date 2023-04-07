#!/bin/bash

source <(azd env get-values | grep NAME)
az container start -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "/bin/bash"
