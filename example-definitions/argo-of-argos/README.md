# Argo of Argos

This example demonstrate the use of Argo Flavors to manage multiple clusters where each cluster has its own argocd instance to ease the load from the main argocd. Instead of using argocd agent here we sync application manifests to the spoke clusters by deploying them with the main argocd

```mermaid
flowchart TD
    subgraph hub ["Hub Cluster"]
        A(["clusterset"])
        B(["serviceset"])
        C(["Cluster Application"])
        A --> B
        B --> C
    end

    subgraph spoke ["Spoke Cluster"]
        E["Arcocd Core"]
        D(["serviceset"])
        F(["cluster applications"])
        E <-.-> D

        E <-.-> F
        D --> F
    end

    C --> D
    C --> E

    style hub fill:#0d2238,stroke:#58a6ff,color:#f0f6fc
    style spoke fill:#271b38,stroke:#bc8cff,color:#f0f6fc
    classDef apps fill:#1f6feb,stroke:#58a6ff,color:#f0f6fc
    classDef workload fill:#238636,stroke:#3fb950,color:#f0f6fc
    class A,B,C,D,F apps
    class E workload
```

> [!NOTE]
> It is reccomended to use argocd agent with this project to get a cleaner deployment

# Environment set up
To deploy this example you will need an argocd instance connected to two clusters. The connected clusters don't have an argocd instance initially. If you don't already have an argocd instance, this part guides you through setting up a demo using vcluster.

## Requirements
- vcluster cli
- argocd cli
- kubectl
- a k8s cluster

### create vclusters
create vclusters and set up portforwarding.

set variables:
```shell
vcluster disconnect #just in case
MAIN_CTX=`kubectl config current-context`
MANAGER_NAME=hub
MANAGER_NS=vcluster-$MANAGER_NAME
ARGOCD_VERSION=v3.4.1
SPOKE_CLUSTERS_NAMES=(spoke0 spoke1)
SPOKE_CLUSTERS_NS=()
SPOKE_CLUSTERS_CONTEXTS=()
```

create workload clusters (wait patiently for vcluster):
```shell
for SPOKE_CLUSTER_NAME in ${SPOKE_CLUSTERS_NAMES[@]}; do
  SPOKE_CLUSTER_NS=vcluster-$SPOKE_CLUSTER_NAME
  SPOKE_CLUSTERS_NS+=($SPOKE_CLUSTER_NS)
  vcluster create --context $MAIN_CTX $SPOKE_CLUSTER_NAME -n $SPOKE_CLUSTER_NS --connect=false --upgrade \
    --set controlPlane.service.spec.type=ClusterIP
  SPOKE_CLUSTERS_CONTEXTS+=(`vcluster connect $SPOKE_CLUSTER_NAME -s -- kubectl config current-context`)
  vcluster connect --context $MAIN_CTX $SPOKE_CLUSTER_NAME --background-proxy=false -s &
done
```
create manager (wait patiently for vcluster):
```shell
# Attach spoke clusters api
params=()
for i in ${!SPOKE_CLUSTERS_NAMES[@]}; do
    svc="${SPOKE_CLUSTERS_NS[$i]}/${SPOKE_CLUSTERS_NAMES[$i]}"
    params+=(
        "--set networking.replicateServices.fromHost[$i].from=$svc"
        "--set networking.replicateServices.fromHost[$i].to=$svc"
    )
done
vcluster create --context $MAIN_CTX -n $MANAGER_NS --upgrade --connect=false ${params[@]} $MANAGER_NAME

# set up context variable and background connection
MANAGER_CONTEXT=`vcluster connect $MANAGER_NAME -s -- kubectl config current-context`
vcluster connect --context $MAIN_CTX $MANAGER_NAME --background-proxy=false -s &
```
### Install argocd
install argocd in manager:
```shell
ARGOCD_VERSION=v3.4.1
kubectl create namespace argocd --context $MANAGER_CONTEXT
kubectl apply --context $MANAGER_CONTEXT -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml
```

wait for argocd to be ready:
```shell
watch kubectl --context $MANAGER_CONTEXT get po -n argocd
```

attach spoke clusters:
```shell
kubectl config set-context $MANAGER_CONTEXT --namespace argocd
kubectl config use-context $MANAGER_CONTEXT
# login
argocd login --core
# attach clusters
for i in ${!SPOKE_CLUSTERS_NAMES[@]}; do
  argocd cluster add ${SPOKE_CLUSTERS_CONTEXTS[$i]} --name ${SPOKE_CLUSTERS_NAMES[$i]}
  #get secret name created in manager by argo cli
  secret_name=`kubectl get secrets -n argocd -o jsonpath="{range .items[?(@.data.name==\"$(echo -n ${SPOKE_CLUSTERS_NAMES[$i]} | base64)\")]}{.metadata.name}{\"\n\"}{end}"`
  # Edit url so argocd can access cluster
  kubectl patch secret $secret_name -n argocd --type='json' -p="[{\"op\": \"replace\", \"path\": \"/data/server\", \"value\": \"$(echo -n "https://${SPOKE_CLUSTERS_NAMES[$i]}.${SPOKE_CLUSTERS_NS[$i]}" | base64)\"}]"
done
```

### Log in to ui and test
Get the initial argocd admin password:
```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context $MANAGER_CONTEXT | base64 -d && echo
```
Expose the argocd-server svc however you want to or use port-forwarding:
```shell
kubectl port-forward svc/argocd-server --context $MANAGER_CONTEXT 9999:80
# Access at localhost:9999
```
you can verify the connection by deploying an app:
```shell
cat << EOF | kubectl apply -f - --context $MANAGER_CONTEXT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: guestbook
  destination:
    name: ${SPOKE_CLUSTERS_NAMES[0]}
    namespace: guestbook
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
EOF
```

# Deploy Flavors
Apply this manifest to create a clusterset in the manager:
```shell
cat << EOF | kubectl apply -f - --context $MANAGER_CONTEXT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: clusterset-prod-argo-of-argos
  namespace: argocd
  labels:
    type: clusterset
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  project: default
  source:
    helm:
      parameters:
      - name: definitionsRepo.repoURL
        value: https://github.com/poxelyric/argo-flavors.git
      - name: definitionsRepo.targetRevision
        value: HEAD
      - name: definitionsRepo.basePath
        value: example-definitions/argo-of-argos/definitions
      - name: env
        value: prod
    path: clusterset
    repoURL: https://github.com/poxelyric/argo-flavors.git
    targetRevision: HEAD
EOF
```

Open the manager argocd ui and see your app has been created:
<p align="center">
    <img src="../../docs/assets/argo-of-argos/apps.png">
</p>

sync the app:
<p align="center">
    <img src="../../docs/assets/argo-of-argos/clusterset.png">
</p>

An application has been created for each cluster. We can enter one of them and sync it too:

<p align="center">
    <img src="../../docs/assets/argo-of-argos/spoke0-apps.png">
</p>

A single app has been created, this is the app we defined under "apps" key in [_apps.yaml_](definitions/_apps.yaml). If more apps would be defined then we would have seen them here as well. If we enter the app we can see that it deploys argocd core components into the destination spoke cluster as well as an application manifest that references the [serviceset](../../serviceset/) chart:

<p align="center">
    <img src="../../docs/assets/argo-of-argos/argocd-core-spoke0.png">
</p>

If we try to enter the serviceset app we will reach a "fail to load" screen because unlike the apps so far, this one is deployed to the spoke cluster and is managed by the spoke argocd.

<p align="center">
    <img src="../../docs/assets/argo-of-argos/failed-to-load.png">
</p>

To view it we shall use the argocd cli:
```shell
kubectl config set-context ${SPOKE_CLUSTERS_CONTEXTS[0]} --namespace argocd
kubectl config use-context ${SPOKE_CLUSTERS_CONTEXTS[0]}
# login
argocd login --core
# set up tunnel
argocd admin dashboard
```

Open your browser at localhost:8080 and interact with the app:
<p align="center">
    <img src="../../docs/assets/argo-of-argos/serviceset.png">
</p>

You can see that the deployed apps are the ones under "spokeApps" key in [_apps.yaml_](definitions/_apps.yaml) and not "apps". This is possible because we can control which key holds the apps with the parameter "appDictKey" passed to the serviceset app.

<p align="center">
    <img src="../../docs/assets/argo-of-argos/guestbook-ui.png">
</p>
