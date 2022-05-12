# K8s Export Namespace

Export all non-generated objects from a Kubernetes namespace. This script was
only tested on RHEL 8. This script will have issues running on MacOS.

This script requires the following krew plugins:

- `$ kubectl krew install get-all`
- `$ kubectl krew install neat`
- `$ kubectl krew install slice`

Install krew here: https://krew.sigs.k8s.io/docs/user-guide/setup/install

## Usage

```bash
./export-namespace.sh NAMESPACE
```
