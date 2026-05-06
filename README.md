<p align="center">
    <img src="docs/assets/logo.png" style="height:50vh;">
</p>

# Argo Flavors

Argo Flavors is a deployment framework for Argo CD environments that need to manage applications across many clusters. It enables you to define flavors and sub-flavors, reducing repetition while preserving precise control over cluster-specific settings.

## Features

- Nested flavor inheritance
- Cluster-specific overrides
- Dynamic templating in application values
- Environment separation that maintains conformity to overall system definitions
- Designed for large-scale, multi-cluster deployments

## How it works

Argo Flavors treats multiple YAML files as Helm values. Helm merges those files into a single rendered values document that defines your applications and deployment parameters.

See the [Avatar example](example-definitions/avatar/README.md) for a sample flavor structure.

## Who should use it?

This project is ideal for teams using Argo CD to manage tens or hundreds of clusters from a single Git repository. Argo Flavors helps maintain governance, reduce duplication, and keep configuration consistent.

## Why choose Argo Flavors?

- Simplifies multi-cluster deployments
- Reduces repeated configuration through inheritance
- Makes environment boundaries explicit
- Enables targeted customization per cluster
