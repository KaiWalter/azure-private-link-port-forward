#!/bin/bash

source <(azd env get-values | grep -E 'NAME|TOKEN')
ILBID=`az network lb list -g $RESOURCE_GROUP_NAME --query "[?contains(name, '$RESOURCE_TOKEN')].id" -o tsv`
ILBIP=`az network lb show --id $ILBID --query frontendIPConfigurations[0].privateIPAddress -o tsv`
az container start -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "curl http://$ILBIP:8000"
