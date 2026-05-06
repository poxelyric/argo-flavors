![logo](docs/assets/logo.png)
# What is Argo Flavors?
A deployment scheme for environments with hundreds of clusters.
Argo Flavors allows you to group clusters into flavors and sub flavors to deploy your apps with minimal text and maximal control.

## Features
* inheritance and sub flavors
* specific cluster configuration
* dynamic templating inside app definition
* environment seperation

# How does it work?
Argo Flavors is built around using multiple yaml files as values for a helm app. Helm will merge the files to create a final rendered values that contains your applications definitions.
See [avater example](example-definitions/avatar/README.md) for the Avatar-themed flavor example.

# Who is this for?
Anyone who deploys applications in argocd can make use of this project, but it was created to handle projects that manage many many clusters. If you deploy applications to tens or hundreds of clusters and want to manage it all from a single git repo, this project might be use full for you. When governance is required but divercity is inevitable, Argo Flavors comes to the rescue.