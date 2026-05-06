# avatar example definitions

This example is intentionally focused on patching an existing app definition using the same app name across multiple levels.

# NOTE
This example doesn't deploy to remote clusters in order to simplify getting started. You can edit the `defaults` field in the root `_apps.yaml` file in order to template a url or name for destination:
```yml
defaults:
  spec:
    destination:
      server: "https://{{ .Values.clusterName }}.example.com"
```

## What is demonstrated

- Root level defines the base set of apps in `example-definitions/avatar/_apps.yaml`.
- Flavor-level files modify the same app names from the root.
- Environment-level `_apps.yaml` files are kept empty to keep the demo simple.
- Cluster files still have the highest precedence and can make the final, cluster-specific patch.

## Root apps

The [root file](_apps.yaml) defines three apps:

- `podinfo-helm` (Helm repo chart)
- `podinfo-git` (Git repo chart path)
- `podinfo-multi-source` (multiple `sources:` entries)

## Flavor patching

- Earth flavor patches `podinfo-helm` for the Earth Kingdom.
- Fire flavor patches `podinfo-helm` for the Fire Nation and removes `podinfo-git`.
- Water and Wind flavors patch `podinfo-helm` with their own messages.
- `fire/lightning` is a subflavor of Fire that inherits Fire behavior and adds lightning-specific capabilities.

## Environment and cluster precedence

This demo uses a small set of files so users can see the layering without overload:

1. `example-definitions/avatar/_apps.yaml`
2. `example-definitions/avatar/<flavor>/_apps.yaml`
3. `example-definitions/avatar/<flavor>/<env>/_apps.yaml`
4. `example-definitions/avatar/<flavor>/<env>/<cluster>.yaml`
