# Resource manager

Resource management utility for FiveM and RedM.

![test](https://i.imgur.com/MeeP6nx.png)

# Requirements

- [httpmanager](https://github.com/kibook/httpmanager)

# Installation

1. Place in a folder named `resourcemanager` in your resources directory.

   Example: `resources/[local]/resourcemanager`

2. Add the following to `server.cfg`:

   ```
   exec resources/[local]/resourcemanager/permissions.cfg
   start resourcemanager
   ```
   
   Adjust the path to `permissions.cfg` based on where you installed this resource.
   
3. Configure authorization in httpmanager if necessary.

4. Restart your server.

5. Access the resourcemanager web UI at:

   ```
   http://<server IP>:<server port>/resourcemanager/
   ```
   or
   ```
   https://<owner>-<server ID>.users.cfx.re/resourcemanager/
   ```
