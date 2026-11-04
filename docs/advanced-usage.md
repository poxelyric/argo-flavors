# Advanced Guide

This guide covers advanced features and configuration patterns for complex ArgoCD deployments using Argo Flavors.

## Advanced Flavor Hierarchies

When you use Argo Flavors, configuration files are combined as helm value files. The cluster file and `_apps.yaml` files in its parent directories are combined into one values.

**Benefits:**
- Reduces configuration duplication
- Maintains consistency across similar environments
- Allows progressive customization

### Nested Flavors

Create complex inheritance hierarchies with multiple levels of flavors.

The final directory in a branch path must always be the environment folder containing the cluster file. You may add nested flavors and subflavors anywhere above that final environment folder, but the cluster definition YAML must live inside the environment directory such as `staging/` or `prod/`.

**Example Structure:**
```
example-definitions/
├── _apps.yaml                    # Global defaults
├── enterprise/
│   ├── _apps.yaml               # Enterprise flavor overrides
│   ├── us-west/
│   │   ├── _apps.yaml          # US West subflavor settings
│   │   └── prod/
│   │       └── prod-us-west-01.yaml # Cluster file in prod environment
│   └── eu-central/
│       ├── _apps.yaml          # EU Central subflavor settings
│       └── prod/
│           └── prod-eu-central-01.yaml # Cluster file in prod environment
└── staging/
    ├── _apps.yaml               # Staging-specific settings
    └── staging-global-01.yaml   # Cluster file in staging environment
```

To remove a key in a lower precedence value file set the key to null

### Flavor-Specific Application Removal

Remove applications from specific flavors by setting them to `null`. For example if debug-app is defined in a `_apps.yaml` file with lower precedence, setting this definition will remove it:

```yaml
apps:
  debug-app: null  # Remove debug app from production
```

## 🌍 Cluster-Specific Overrides

The cluster file itself also serves as a configuration file, allowing you to apply final, cluster-specific modifications that take precedence over all other configurations.

**Use Cases:**
- Cluster-specific configration accross all application
- Environment-specific feature flags

## 🔧 Dynamic Templating

Argo Flavors will pass your application configuration through a tpl function. This means you can use values from the configuration files in addition to special injected values to configure applications.

**Special Variables:**
- `{{ .Values.clusterName }}` - Target cluster name. The name of the cluster file: `<cluster name>.yaml`
- `{{ .Values.flavor }}` - The flavor directories the cluster is in joined with a "-"
- `{{ .Values.env }}` - Environment (staging, prod, etc)
- `{{ .appName }}` - Application name. This is equal to the key of the application

**Example:**
```yaml
apps:
  webapp:
    spec:
      destination:
        namespace: "{{ .Values.appName }}" # results in: "webapp"
      source:
        helm:
          valuesObject:
            environment: "{{ .Values.env }}"
            cluster: "{{ .Values.clusterName | lower }}" # you can use helm functions
```

### Complex Template Logic

Because `_apps.yaml` files are parsed as regular YAML values before templating, Helm template logic must be embedded inside string values. Top-level YAML control flow statements are not valid in the raw `_apps.yaml` file. You can still use conditionals and loops, but they must be rendered inside a string value.

```yaml
myOwnValue: random-data

apps:
  webapp:
    spec:
      source:
        helm:
          valuesObject:
            replicaCount: "{{ if eq .Values.env \"production\" }}3{{ else }}1{{ end }}"
            environment: "{{ .Values.env }}"
            cluster: "{{ .Values.clusterName }}"
            databaseHost: "{{ .Values.clusterName }}-db.internal"
            additionalData: "{{ .Values.myOwnValue}}
```

## 🎯 Explicit Defaults and Overrides

Define base application configurations with explicit override mechanisms.

Precedence is in this order from lowest to highest:

- defaults
- app definition
- overrides

while an app definition allows for editing one app, defaults and overrides act on all applications. So defaults can be useful for injecting all applications with a specific default value, while overrides can be used to make sure all apps conform to a certain requirement.

**Configuration Structure:**
```yaml
defaults:     # Base configuration applied to all apps
  spec:
    source:
      path: "."


overrides:    # Global overrides. This example makes sure all applications are on manual sync
  spec:
    syncPolicy: null

apps:         # Application-specific configurations
  myapp:
    spec:
      source:
        repoURL: https://github.com/myorg/myapp
```

>[!IMPORTANT]
>while overrides have the highest precedence, they can still be changed by configuration files with higher precedence


### Mutualy exclusive values
some fields in argocd application can't be specified together, for example `spec.source.helm` and `spec.source.kustomize`. Argo Flavors automaticaly select only one of these fields according to the specific app definition. If an app definition does not specify any of these fields a default one will be selected. This is true for both overrides and defaults.
**example**
```yaml
defaults:
  spec:
    source:
      helm:
        values: |
          default: default
      kustomize:
        namePrefix: default-

apps:
  myapp:
    spec:
      source:
        repoURL: https://github.com/myorg/myapp
        helm: {}

# resulting app:
spec:
  source:
    repoURL: https://github.com/myorg/myapp
    helm: 
      values: |
        default: default
```
The mutually exclusive fields are controlled through the `mutuallyExclusiveFields` value of serviceset repo. To override it you can write it in the apps configuration file:
```yaml
mutuallyExclusiveFields: [
  [
  spec.sources,
  spec.source
  ],
  [
  spec.source.kustomize,
  spec.source.directory,
  spec.source.plugin,
  spec.source.helm
  ]
]

apps:
...
```

The last value in each list is the default field used when the app definition does not specify it.

## 🔒 Environment Separation

Argo Flavors maintains seperation of development clusters and production clusters while allowing them to exist in the same eco system. Both environments can inerit the same application configuration while still being deployed in seperate application trees. This is done by placing different environment clusters in directories of their respective environment.