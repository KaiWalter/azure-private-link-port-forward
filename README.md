# Private Link Port Forwarder

## preparation

> this setup assumes it works with `~/.ssh/id_rsa` key pair - to use other key pairs adjust `./hooks/preprovision.sh`

```shell
ssh-keygen -m PEM -t rsa -b 4096
```

login to your subscription first

```shell
az login
azd login
```

## deployment

```shell
azd init
scripts/set-environment.sh
azd up
```

## check connectivity from hub network to on-prem server

```shell
source <(azd env get-values | grep NAME)
az container start -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "wget http://192.168.42.65:8000 -O -"
az container stop -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
```

## shell into hub network

```shell
source <(azd env get-values | grep NAME)
az container start -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "/bin/bash"
az container stop -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
```

use these statements to generate a block of commands to load private key into hub/spoke jump container

```shell
echo "cat > /root/.ssh/id_rsa <<EOL"
cat ~/.ssh/id_rsa
echo "EOL"
echo "chmod 600 ~/.ssh/id_rsa"
```

cat ~/.ssh/id_rsa | base64 -w 0

## check connectivity from spoke network to on-prem server

```shell
source <(azd env get-values | grep NAME)
az container start -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "curl http://onprem-server.internal.net:8000"
az container stop -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
```

## shell into spoke network

```shell
source <(azd env get-values | grep NAME)
az container start -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "/bin/bash"
az container stop -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
```

----

## helpers

### show iptables counters

```shell
sudo iptables -L -n -v
sudo iptables -L -n -t nat -v
```

in an endless loop

```shell
while true; do clear; iptables -L -n -v; iptables -L -n -v -t nat; sleep 1; done
```

## check cloud init log

```shell
cat /var/log/cloud-init-output.log
```

## check which version of cloud-init was used

```shell
cat /var/lib/waagent/ovf-env.xml | sed -n -e 's/.*<ns1:CustomData>\(.*\)<\/ns1:CustomData>.*/\1/p' | base64 --decode
```

## delete VMSS for retesting

```shell
source <(azd env get-values | grep NAME)
az vmss delete --id $(az vmss list -g $RESOURCE_GROUP_NAME --query '[].id' -o tsv) --force-deletion true
```

## check cloud init in deployment parameter

```shell
source <(azd env get-values | grep CLOUD)
echo $CLOUD_INIT_FWD | base64 --decode
```

## reference information

- [simple idea to make iptables persistent across reboots](https://dev.to/oryaacov/3-ways-to-make-iptables-persistent-4pp)

<https://learn.microsoft.com/en-us/azure/load-balancer/backend-pool-management#limitations>

<https://jensd.be/343/linux/forward-a-tcp-port-to-another-ip-or-port-using-nat-with-iptables>

<https://en.m.wikipedia.org/wiki/Iptables#/media/File%3ANetfilter-packet-flow.svg>

<https://learn.microsoft.com/en-us/azure/load-balancer/skus#skus>

<https://stackoverflow.com/questions/75910542/backendaddresspool-in-azure-load-balancer-with-only-ip-addresses-does-not-deploy>

----
## failed attempt directly with Load Balancer w/o forwarder VMSS

source <(azd env get-values)

az network lb delete -g $RESOURCE_GROUP_NAME --name ilb-$RESOURCE_TOKEN

az network lb create -g $RESOURCE_GROUP_NAME --name ilb-$RESOURCE_TOKEN --sku Standard \
--backend-pool-name direct \
--subnet $(az network vnet subnet show -g $RESOURCE_GROUP_NAME -n shared --vnet-name vnet-hub-$RESOURCE_TOKEN --query id -o tsv)

az network lb probe create -g $RESOURCE_GROUP_NAME --lb-name ilb-$RESOURCE_TOKEN -n direct --protocol tcp --port 8000

az network lb address-pool create -g $RESOURCE_GROUP_NAME --lb-name ilb-$RESOURCE_TOKEN -n direct \
--backend-address name=server65 ip-address=192.168.42.65 \
--backend-address name=server66 ip-address=192.168.42.66 \
--vnet $(az network vnet show -g $RESOURCE_GROUP_NAME  -n vnet-hub-$RESOURCE_TOKEN --query id -o tsv)

az network lb rule create -g $RESOURCE_GROUP_NAME --lb-name ilb-$RESOURCE_TOKEN -n direct --protocol tcp \
--frontend-ip LoadBalancerFrontEnd --backend-pool-name direct \
--frontend-port 8000 --backend-port 8000 \
--probe direct

az network lb show -g $RESOURCE_GROUP_NAME --name ilb-$RESOURCE_TOKEN

## iptables CBL before reconfiguration

Chain INPUT (policy DROP 4 packets, 208 bytes)
 pkts bytes target     prot opt in     out     source               destination
    2   196 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
   26 15432 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22

Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
   42  6695 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0
Chain PREROUTING (policy ACCEPT 4 packets, 208 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 9 packets, 564 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 9 packets, 564 bytes)
 pkts bytes target     prot opt in     out     source               destination
 
