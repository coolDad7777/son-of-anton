# Welcome to Son of Anton!

![CI Status](https://img.shields.io/badge/CI-passing-brightgreen?style=flat-square)

Son of Anton is a small, configuration-driven home NAS foundation built from
[SaltStack](https://saltproject.io/), ZFS, Samba, and NFS. It is intentionally
not a turnkey appliance: you provide the disks, network policy, users, and
shares, and the states apply only that configuration.

If you're using Parallels on macOS there is a Packer build that will automate the build by using a golden image. See the wiki for help.

## Quickstart (Debian 13)

1. Install a clean Debian 13 host or VM with Salt-compatible networking.
2. Identify the intended whole disks with `lsblk` and
   `/dev/disk/by-id`. Never configure `/dev/sdX` names.
3. Edit `pillar/zfs/pool.sls` with the pool layout and stable device IDs.
4. Add datasets in `pillar/zfs/dataSets.sls`, then explicitly configure Samba
   users/shares and any restricted NFS exports.
5. Run `DRY_RUN=true ./bootStrap/bootStrap.sh` and inspect the Salt output.
6. Only after verifying the devices, run
   `DRY_RUN=false ALLOW_DESTRUCTIVE=true CONFIRM_DESTRUCTIVE=CREATE_ZFS_POOLS ./bootStrap/bootStrap.sh`.

Pool creation is disabled by default. To enable it, `zfs.safety` must contain
`allow_pool_creation: true` and `confirmation: CREATE_ZFS_POOLS`. The validation
state rejects missing, mounted, duplicate, non-whole, and non-`by-id` devices.
ZFS pool creation is irreversible; backups and a tested recovery plan are your
responsibility.

The checked-in pillar files contain no demo users, passwords, or open NFS
exports. Keep real credentials out of Git and provide them through a protected
pillar or secrets workflow.
