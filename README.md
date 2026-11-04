<p align="center">
    <img src="docs/assets/logo.png" style="width:50%">
</p>

# Argo Flavors

Argo Flavors is a deployment framework for Argo CD environments that need to manage applications across many clusters. It enables you to define flavors and sub-flavors, reducing repetition while preserving precise control over cluster-specific settings.

## ✨ Features

- 🍨 Nested flavor inheritance
- 🌍 Cluster-specific overrides
- 🔧 Dynamic templating in application values
- 🔧 Explicit app defaults and overrides
- 🔒 Environment separation that maintains conformity to overall system definitions
- 📈 Designed for large-scale, multi-cluster deployments

## 🚀 How it works

Argo Flavors treats multiple YAML files as Helm values. Helm merges those files into a single rendered values document that defines your applications and deployment parameters.

See the [Avatar example](example-definitions/avatar/README.md) for a sample flavor structure.

## 👥 Who should use it?

This project is ideal for teams using Argo CD to manage tens or hundreds of clusters from a single Git repository. Argo Flavors helps maintain governance, reduce duplication, and keep configuration consistent.

## ⭐ Why choose Argo Flavors?

- ✅ Simplifies multi-cluster deployments
- ♻️ Reduces repeated configuration through inheritance
- 🎨 Makes environment boundaries explicit
- 🎯 Enables targeted customization per cluster

## 📚 Documentation

Documentation is available in the [docs/](docs/) directory:

- **[Architecture](docs/architecture.md)** - How Argo Flavors works
- **[Basic Usage](docs/basic-usage.md)** - A quickstart guide
- **[Advanced Guide](docs/advanced-guide.md)** - Explore features and complex usage of flavors
- **[Examples](example-definitions)** - Learn from included examples and see how flavors is used in different architectures

## 🚀 Quick Start

You can get started quickly with the avatar themed example in this repo. This example deploys apps to local cluster (Even though the project is intended for deploying to other clusters) to help you get started. so no cluster configuration is required other than a working argocd instance:
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
        value: example-definitions/avatar
    chart: clusterset
    repoURL: ghcr.io/poxelyric
    targetRevision: 1.0.0
EOF
```
See [README](example-definitions/avatar/README.md) for a walkthrough.

Check out the other [examples](docs/examples.md) to see how you can adapt this project to different architectures
