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
azd up
```

## check connectivity from hub network to on-prem server

```shell
source <(azd env get-values | grep NAME)
az container start -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "wget http://192.168.42.65:8000 -O -"
az container stop -n $HUB_JUMP_NAME -g $RESOURCE_GROUP_NAME
```

## initial non-forwarded check connectivity from spoke network to on-prem server

```shell
source <(azd env get-values | grep NAME)
az container start -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
az container exec -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME --exec-command "wget http://192.168.42.65:8000 -O -"
az container stop -n $SPOKE_JUMP_NAME -g $RESOURCE_GROUP_NAME
```


----

## helpers

### show iptables rule file (on VMSS node VM)

```shell
sudo cat /etc/iptables/rules.v4
```

### show iptables counters

```shell
sudo iptables -L -n -v
sudo iptables -L -n -t nat -v
```

### load from saved iptables

```shell
sudo service netfilter-persistent reload
```

## check cloud init log

```shell
cat /var/log/cloud-init-output.log
```

## reference information

<https://jensd.be/343/linux/forward-a-tcp-port-to-another-ip-or-port-using-nat-with-iptables>

<https://en.m.wikipedia.org/wiki/Iptables#/media/File%3ANetfilter-packet-flow.svg>

<https://stackoverflow.com/questions/75910542/backendaddresspool-in-azure-load-balancer-with-only-ip-addresses-does-not-deploy>