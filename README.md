# THIS WILL ALLOW ALL TRAFFIC TO THE TAILSCALE NODE

if Tailscale is in a docker container then this needs to be run on the host. 

Use an ACL to lock this down to necessary ports

Configure Tailscale Service Tunnel Mode

1. Create Service in Tailscale and enable auto approval 
2. configure OAUTH client in Tailscale
3. Add OAUTH ID, OAUTH Secret, TAILNET ID, and Service name as variables

copy tailscale-tun.sh and tailscale-service.env to /etc then run

`chmod 600 tailscale-service.env`  
`chmod +x tailscale-tun.sh`

copy scripts to /etc/systemd/system 

run the following

`systemctl enable --now tailscale-link-up.path`  
`systemctl enable tailscale-link-up.service`

start tailscale

copy the json file and change the SERVICENAME 

`tailscale serve --service=<SERVICENAME> --tun /etc/serve.json; tailscale serve advertise <SERVICENAME>`
