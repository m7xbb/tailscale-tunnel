# Run an internal load balanced service using Tailscale Tunnel mode
This can be used to host a service across multiple Tailscale nodes.

**Unles properly locked down, this will allow all traffic to a node behind the service**

You will need to use an ACL to lock down to necessary ports only

**Setup:**

1. Go to [Tailscale Admin Console → Settings → OAuth clients](https://login.tailscale.com/admin/settings/oauth)
2. Create a new OAuth client with scope `api_access_tokens, services:read`



**Installation:**

***Configure Tailscale services:***

1. Go to [Tailscale Admin Console → Services](https://login.tailscale.com/admin/services)
2. Create a service for each set of nodes you want to expose in tunnel mode with a tag of `tag:pihole`
3. Configure ACL auto-approvers (see [Auto approve ACL Configuration](#acl-configuration))
4. Configure Ports and Protocols (see [Ports ACL Configuration](#ports-acl-configuration))
4. tag each Tailscale node with `tag:pihole-server`

***Configure Hosts:***

1. copy tailscale-tun.sh and tailscale-service.env to /etc

    update tailscale-service.env with OAUTH ID, OAUTH Secret, TAILNET ID, and Service name as variables

    then run

    `chmod 600 tailscale-service.env`  
    `chmod +x tailscale-tun.sh`

2. copy scripts to /etc/systemd/system 

    run the following

    `systemctl enable --now tailscale-link-up.path`  
    `systemctl enable tailscale-link-up.service`

    start tailscale

    copy the json file and change the SERVICENAME 

    `tailscale serve --service=<SERVICENAME> --tun /etc/serve.json; tailscale serve advertise <SERVICENAME>`






### Auto approve ACL Configuration

Configure Auto approve ACLs in your [Tailscale Access Controls](https://login.tailscale.com/admin/acls):

```json
{
  "autoApprovers": {
    "services": {
      "tag:pihole-server": ["tag:pihole"]
    }
  }
}
```

### Ports ACL Configuration

Configure ports and proctocol access in your [Tailscale Admin Console → Access Controls → General Access Rules](https://login.tailscale.com/admin/acls/visual/general-access-rules):

```json
{
	"src": ["*"],
	"dst": ["tag:pihole", "pihole-server"],
	"ip":  ["udp:53", "tcp:53"],
}
```
This allows machines tagged `tag:pihole-server` to advertise services tagged `tag:pihole`




if Tailscale is in a docker container then this needs to be run on the host. 


  



## Links

- [Tailscale Services Documentation](https://tailscale.com/kb/1552/tailscale-services)
