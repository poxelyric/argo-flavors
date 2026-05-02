# myargo example definitions

This example is intentionally focused on patching an existing app definition using the same app name across multiple levels.

## What is demonstrated

- Root level defines the base set of apps in `example-definitions/myargo/_apps.yaml`.
- Flavor-level files modify the same app names from the root.
- Environment-level `_apps.yaml` files are kept empty to keep the demo simple.
- Cluster files still have the highest precedence and can make the final, cluster-specific patch.

## Root apps

The root file defines three apps:

- `podinfo-four-nations` (Helm repo chart)
- `podinfo-git` (Git repo chart path)
- `podinfo-multi-source` (multiple `sources:` entries)

## Flavor patching

- Earth flavor patches `podinfo-four-nations` for the Earth Kingdom.
- Fire flavor patches `podinfo-four-nations` for the Fire Nation and removes `podinfo-git`.
- Water and Wind flavors patch `podinfo-four-nations` with their own messages.
- `fire/lightning` is a subflavor of Fire that inherits Fire behavior and adds lightning-specific capabilities.

## Environment and cluster precedence

This demo uses a small set of files so users can see the layering without overload:

1. `example-definitions/myargo/_apps.yaml`
2. `example-definitions/myargo/<flavor>/_apps.yaml`
3. `example-definitions/myargo/<flavor>/<env>/_apps.yaml` (empty)
4. `example-definitions/myargo/<flavor>/<env>/<cluster>.yaml`

The environment `_apps.yaml` files exist but do not introduce additional app logic in this example.

## Avatar theme

- `earth/staging/toph.yaml`
- `fire/staging/zuko.yaml`
- `fire/prod/iroh.yaml`
- `fire/lightning/prod/azula.yaml`
- `water/staging/katara.yaml`
- `wind/staging/aang.yaml`

Each cluster file can patch the existing `podinfo-four-nations` app to show how final overrides work.
