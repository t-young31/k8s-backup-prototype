# k8s-backup-prototype
> **Warning**
> Not production ready. Use at your own risk!

Prototype for [Longhorn](https://longhorn.io/) backed up kubernetes PVCs.

## Usage
1. Create a `.env` file from `.env.sample`

2. Run `make`

3. Login to the longhorn UI to create a backup target from the settings pane
    - **Backup Target**: _From terraform output_
    - **Backup Target Credential Secret**: aws-s3-longhorn
    - **Replica Node Level Soft Anti-Affinity**: Enable

4. SSH onto the EC2 instance and create a sample volume from a postgres DB to backup
```bash
helm install test-pg oci://registry-1.docker.io/bitnamicharts/postgresql
```
