# Usage
With argo flavors you define your app specifications in a directry tree strored in git. You can look at these [examples](../example-definitions/) for a reference, specifically the avatar example focuses on the definitions. This guide walks you through creating your definitions repo and deploying clusterset.

## Definitions repo
Start by creating a git repository to store your app configurations. The directory structure must conform to the following rules:

1. Every directory must contain one `_apps.yaml` file.
   This file stores the app configurations. The name of the file may be changed through values of the clusterset application. It may be empty but it must exist.

2. Every yaml file other than `_apps.yaml` files is named after a cluster (`<cluster_name>.yaml`) and is stored under a directory with a name of an environment.
   Files that aren't inside a directory named after the env will not be picked up by the git generator.

**example structure:**
```
my-definitions/                   # Base path
├── _apps.yaml
├── flavor1/
│   ├── _apps.yaml
|   └── staging/
│       ├── _apps.yaml
|       └── cluster1.yaml
└── flavor2/
    ├── _apps.yaml
    ├── staging/
    │   ├── _apps.yaml
    │   └── cluster1.yaml
    └── subflavor/
        ├── _apps.yaml
        └── prod/
            ├── _apps.yaml
            └── cluster2.yaml
```
### Configuration Files Structure
Both `_apps.yaml` and `<cluster-name>.yaml` files have the same structure and are used as values for the final app generation. Special fields must obey a certain structure, specifically the fields specified in the [serviceset values](../serviceset/values.yaml). Other than that you may specify arbitrary fields to be used for advanced app templating.
|value                              |functionality       |
|---                                |---                 |
|`apps`                             | a dictionary specifying applications configuration. Each key in the dict can be named in any way and will be used for templating the application name. The values of these keys must be in the structure of an argocd application definition (possibly partial)|
|`defaults`                         | A default application definition. The value of this key must be in the structure of an argocd application definition (possibly partial)|
|`overrides`                        |  The value of this key must be in the structure of an argocd application definition (possibly partial). It will override definitions made in the `defaults` key or `apps` |

> [!NOTE]
> It is okay to specify mutualy exclusive values in the defaults or overrides key. Argo flavors will pick up the correct one based on the specified app definition

In order to have apps point to different destinations, edit the defaults key in your root _apps.yaml file:
```yaml
defaults:
  spec:
    destination:
      name: "{{ .Values.clusterName }}"
      #alternativly:
      #server: "https://api.{{ .Values.clusterName }}.my.domain"
```


## Clusterset
When deploying the clusterset there are special values you need to set in order to control the application deployment:
|value                              |functionality       |
|---                                |---    |
|`definitionsRepo.repoURL`          |This configures the url for the git repo that stores your definitions| 
|`definitionsRepo.targetRevision`   |Configures targetRevision of definitions|
|`definitionsRepo.basePath`         |Your repo might contain multiple definitions or unrelated directories. This configures the basePath your definitions are stored|
|`env`                              |argo flavors will only deploy clusters that reside under a directory named like the env value. This creates seperation between workloads of different envs|

To use the project you must start by creating a clusterset application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: clusterset-<your env>
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: <your applicationset namespace (usualy argocd)>
  project: <your argocd project>
  source:
    helm:
      parameters:
      - name: definitionsRepo.repoURL
        value: <url of your git repo>
      - name: definitionsRepo.targetRevision
        value: <ref of definitions repo> # recommended to use HEAD
      - name: definitionsRepo.basePath
        value: <path to directory of definitons>
    chart: clusterset
    repoURL: ghcr.io/poxelyric
    targetRevision: 1.0.0
```
> [!WARNING]
> Make sure argocd can access your definition repos

sync the app and sync the created applications if not set to auto sync.

# Next steps
check out [architecture](architecture.md) doc for an explanation of how flavors is built
check out [advanced usage](advanced-usage.md) doc to explore different features