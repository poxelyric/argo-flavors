This example demonstrate the use of Argo Flavors to manage multiple clusters where each cluster has its own argocd instance to ease the load from the main argocd.

> [!NOTE]
> It is reccomended to use argocd agent with this project to get a cleaner deployment

# Environment set up
To deploy this example you will need an argocd instance connected to two clusters. The connected clusters don't have an argocd instance initially. If don't you already have an argocd instance, this part guides you through setting up a demo using vcluster.

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
EDGE_CLUSTERS_NAMES=(edge0 edge1)
EDGE_CLUSTERS_NS=()
EDGE_CLUSTERS_CONTEXTS=()
```

create workload clusters:
```shell
for EDGE_CLUSTER_NAME in ${EDGE_CLUSTERS_NAMES[@]}; do
  EDGE_CLUSTER_NS=vcluster-$EDGE_CLUSTER_NAME
  EDGE_CLUSTERS_NS+=($EDGE_CLUSTER_NS)
  vcluster create --context $MAIN_CTX $EDGE_CLUSTER_NAME -n $EDGE_CLUSTER_NS --connect=false --upgrade \
    --set controlPlane.service.spec.type=ClusterIP
  EDGE_CLUSTERS_CONTEXTS+=(`vcluster connect $EDGE_CLUSTER_NAME -s -- kubectl config current-context`)
  vcluster connect --context $MAIN_CTX $EDGE_CLUSTER_NAME --background-proxy=false -s &
done
```
create manager:
```shell
# Attach edge clusters api
params=()
for i in ${!EDGE_CLUSTERS_NAMES[@]}; do
    svc="${EDGE_CLUSTERS_NS[$i]}/${EDGE_CLUSTERS_NAMES[$i]}"
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
kubectl --context $MANAGER_CONTEXT get po -n argocd
```

attach edge clusters:
```shell
kubectl config set-context $MANAGER_CONTEXT --namespace argocd
kubectl config use-context $MANAGER_CONTEXT
# login
argocd login --core
# attach clusters
for i in ${!EDGE_CLUSTERS_NAMES[@]}; do
  argocd cluster add ${EDGE_CLUSTERS_CONTEXTS[$i]} --name ${EDGE_CLUSTERS_NAMES[$i]}
  #get secret name created in manager by argo cli
  secret_name=`kubectl get secrets -n argocd -o jsonpath="{range .items[?(@.data.name==\"$(echo -n ${EDGE_CLUSTERS_NAMES[$i]} | base64)\")]}{.metadata.name}{\"\n\"}{end}"`
  # Edit url so argocd can access cluster
  kubectl patch secret $secret_name -n argocd --type='json' -p="[{\"op\": \"replace\", \"path\": \"/data/server\", \"value\": \"$(echo -n "https://${EDGE_CLUSTERS_NAMES[$i]}.${EDGE_CLUSTERS_NS[$i]}" | base64)\"}]"
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
you can verify the agent by deploying an app:
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
    name: ${EDGE_CLUSTERS_NAMES[0]}
    namespace: guestbook
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
EOF
```

### Deploy Flavors
Apply this manifest to create a clusterset in the manager:
```shell
cat << EOF | kubectl apply -f - --context $MANAGER_CONTEXT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: clusterset-prod
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