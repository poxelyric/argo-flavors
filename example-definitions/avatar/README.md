# Avatar Example Definitions

This example is intentionally focused on patching an existing app definition using the same app name across multiple levels.

> [!NOTE]
> This example doesn't deploy to remote clusters in order to simplify getting started. You can edit the `defaults` field in the root `_apps.yaml` file in order to template a url or name for destination:
> ```yml
> defaults:
>   spec:
>     destination:
>       server: "https://{{ .Values.clusterName }}.example.com"
> ```

## Requirements
- a working argocd instance

## Deploy Staging Clusterset
```shell
cat << EOF | kubectl apply -f - -n argocd
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: clusterset-staging
  labels:
    type: clusterset
spec:
  destination:
    server: "https://kubernetes.default.svc"
  project: default
  source:
    helm:
      parameters:
      - name: definitionsRepo.repoURL
        value: "https://github.com/poxelyric/argo-flavors.git"
      - name: definitionsRepo.targetRevision
        value: HEAD
      - name: definitionsRepo.basePath
        value: example-definitions/avatar
    path: clusterset
    repoURL: "https://github.com/poxelyric/argo-flavors.git"
    targetRevision: HEAD
EOF
```

Login to the argocd UI and sync the app. You should see an applicationset being created which will create five differet apps.
<p align="center">
    <img src="../../docs/assets/avatar/clusterset-staging.png" style="width:100%">
</p>

## Explore Cluster Applications
Enter sokka-apps application and sync it.

you can filter applications based on flavor by a label which is automatically added. see bottom left:
<p align="center">
    <img src="../../docs/assets/avatar/label-filter.png" style="width:100%">
</p>

You can see how this label is added by going to [serviceset values](../../serviceset/values.yaml) and looking at `defaults` key.

### Removed app

Go into zuko apps. There are only two of them, unlike the other flavors. This is because fire flavor [removes one of the apps](fire/_apps.yaml)

## Deploy Prod Clusterset
```shell
cat << EOF | kubectl apply -f - -n argocd
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: clusterset-prod
  labels:
    type: clusterset
spec:
  destination:
    server: "https://kubernetes.default.svc"
    namespace: argocd
  project: default
  source:
    helm:
      parameters:
      - name: definitionsRepo.repoURL
        value: "https://github.com/poxelyric/argo-flavors.git"
      - name: definitionsRepo.targetRevision
        value: HEAD
      - name: definitionsRepo.basePath
        value: example-definitions/avatar
      - name: env
        value: prod
    path: clusterset
    repoURL: "https://github.com/poxelyric/argo-flavors.git"
    targetRevision: HEAD
EOF
```
You can see that only azula and iroh were deployed. This is because they are the only clusters under a directory named prod.

<p align="center">
    <img src="../../docs/assets/avatar/clusterset-prod.png" style="width:100%">
</p>

Sync azula's applications and look at their labels. The flavor label is different than iroh and zuko, this is because azula is in a sub flavor of lightning.
<p align="center">
    <img src="../../docs/assets/avatar/azula-labels.png" style="width:100%">
</p>
