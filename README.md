# Ghidra Server Image for OpenNebula

This [Packer](https://www.packer.io/) template creates a KVM Image running a Ghidra Server and OpenNebula Context Daemon, within an Ubuntu 20.04. It uses an JAAS/LDAP for autentication of Ghidra Users, and the Public Key injected via Open Nebula OneContext for SSH authentication.

## How to use

1. Clone this repo
2. Copy `custom.auto.pkrvars.hcl.TEMPLATE` to `custom.auto.pkrvars.hcl` and modify as needed (especially the `hostname` variable)
3. Copy `jaas.conf.TEMPLATE` to `jaas.conf` and modify as needed. The current layout assumes a [FreeIPA](https://www.freeipa.org/page/Main_Page) LDAP structure.
4. `packer build .`
5. Upload the image to your OpenNebula instance and instanciate it

**Note:** The Packer template variables are documented in `ghidra-server.pkr.hcl`. You should *not* edit the default values there and instead modify the `pkrvars` file.

## VM structure

Ghidra is installed as a SystemD service, and can be restarted using `systemctl (start|stop) ghidraSvr`. The logs are stored in `/home/ghidra/repository/server.log` and in the journal. The repository itself is located in `/home/ghidra/repository`, while the configuration can be found at `/home/ghidra/ghidra/server/log`.

The `ghidra` user account is locked after image creation, and used by the SystemD service. If you need to access it, then login to the VM via the credentials that you have configured in OpenNebula to be propagated into the VM, and then `sudo -i -u ghidra` (although this should not be neccessary, as the service can be controlled via SystemD anyways).

This implies that you can only use this image on OpenNebula instances. Otherwise, there will be no account that you can log into, as OneContext relies on the OpenNebula API for account creation. This also means that your credentials are not part of the image (which means you can share it without concern), and will only be injected at runtime.

## Updating

If you want to update to a newer Ghidra version, go to the [Ghidra Releases page](https://github.com/NationalSecurityAgency/ghidra/releases/) and look for the newest version. You will need the version number, and the name of the ZIP file (including `.zip`). Then modify the version and filename variables in `custom.auto.pkrvars.hcl` using these new values.
Generate the image, then launch it in parallel to your existing image, and rsync the repositories folder.