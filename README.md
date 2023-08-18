# k8s-backup-prototype


## Usage
1. Create a `.env` file from `.env.sample`

2. Run `make`

3. Login to the longhorn UI to create a backup target, following the
[docs](https://longhorn.io/docs/1.5.1/snapshots-and-backups/backup-and-restore/set-backup-target/)
and allow **Replica Node Level Soft Anti-Affinity**

4. SSH onto the EC2 instance and create a sample volume to backup
```bash
helm install test-pg oci://registry-1.docker.io/bitnamicharts/postgresql
```
