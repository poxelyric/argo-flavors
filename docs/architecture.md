# Architecture Overview

Argo Flavors is a deployment framework that simplifies managing ArgoCD applications across multiple clusters by using hierarchical configuration with inheritance and overrides.

## Core Concepts

### Flavors and Inheritance

Argo Flavors organizes configurations hierarchically using **flavors** - logical groupings that represent different deployment patterns or environments. Flavors support inheritance, allowing child flavors to inherit and override settings from parent flavors.

The final directory in a branch path is always the environment folder containing the cluster file. You may create as many nested subflavors as needed, but the cluster definition YAML must live in the environment folder (for example `staging/` or `prod/`).

```
example-definitions/
├── _apps.yaml                    # Root/base applications
├── flavor1/
│   ├── _apps.yaml               # Flavor-specific overrides
│   ├── staging/
│   │   ├── _apps.yaml          # Environment overrides
│   │   └── cluster1.yaml       # Cluster-specific overrides (staging env)
│   └── prod/
│       └── cluster2.yaml       # Cluster-specific overrides (prod env)
└── flavor2/
    └── staging/
        └── cluster3.yaml       # Cluster-specific overrides (staging env)
```

### Configuration Hierarchy

Configuration precedence is dictated by the location of the file in the directory structure. The closer a file is to the cluster file the higher its precedence. In the example above, the files used as values for cluster1 are these with the later files having higher precedence:
1. example-definitions/_apps.yaml
2. example-definitions/flavor1/_apps.yaml
3. example-definitions/flavor1/staging/_apps.yaml
4. example-definitions/flavor1/staging/cluster1.yaml

### Application Generation

Argo Flavors uses two Helm charts:

#### ClusterSet Chart
- Creates an ArgoCD ApplicationSet
- Generates one application per cluster
- Discovers clusters by scanning for YAML files in the definitions repository

#### ServiceSet Chart
- Deploys the actual applications to each cluster
- Uses Helm templating to merge configurations
- Supports dynamic value injection

## How It Works

### 1. Definition Discovery

The ClusterSet ApplicationSet scans your Git repository for cluster definitions. In Argo Flavors, the environment folder is always the final directory containing the cluster file, while any number of intermediate directories may represent nested subflavors.

```yaml
generators:
- git:
    repoURL: https://github.com/your-org/your-repo
    files:
    - path: "example-definitions/**/staging/[^_]*.yaml"
```
This pattern finds cluster files under the `staging` environment folder and allows arbitrary subflavors above it. The ApplicationSet ignores files starting with `_`; only non-underscore YAML files in the final environment folders are treated as cluster files. The prefix is configurable through clusterset values.

### 2. Application Creation

For each discovered cluster file, an ArgoCD Application is created. The application is a multisource app that sources:
- **serviceset** - the helm chart
- **definitionrepo** - _apps.yaml files are used as values for the serviceset

### 3. Configuration Merging

Value files from definition repo are merged by helm in a hierarchical way:

```yaml
#  example-definitions/_apps.yaml
apps:
  myapp:
    spec:
      source:
        repoURL: https://github.com/myorg/myapp
        path: chart

#  example-definitions/flavor1/_apps.yaml
apps:
  myapp:
    spec:
      source:
        targetRevision: v1.2.3  # Override version for this flavor

# example-definitions/flavor1/staging/_apps.yaml
apps:
  myapp:
    spec:
      source:
        targetRevision: dev  # Override version for this flavor

# Final result: merged configuration with flavor override applied

apps:
  myapp:
    spec:
      source:
        repoURL: https://github.com/myorg/myapp
        path: chart
        targetRevision: dev
```

## Key Benefits

### Reduces Duplication
Instead of maintaining separate ArgoCD applications for each cluster, you define base configurations once and override only what's different.

### Maintains Governance
Common settings are defined at higher levels, ensuring consistency while allowing necessary customization.

### Scales Efficiently
Adding a new cluster requires only a small cluster-specific YAML file, not a complete application definition.

### Enables Dynamic Configuration
Template variables allow configurations to adapt automatically based on cluster, flavor, and environment context.