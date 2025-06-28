
# Defining a function
- Define a flask endpoint with `functions` framework
- The name of the function is important as it will be used later in deploy

# Deploying a cloud run function via gcloud cli
- In order to deploy our gcloud function, we need the following information:
  - source code
  - function name (`hello_world_get` in our case)
  - base image (`python312` in our case)
  - region (`europe-west3` in our case)
  - Since we plan to make it accessible to all, we also pass the `allow-unauthenticated` tag

  > `gcloud run deploy example-cloud-run-function --source . --function hello_world_get --base-image python312 --region europe-west3 --allow-unauthenticated`



# How to terraform it?
- As of now (2025), terraform does not yet have support for cloud run functions without using a docker container
  - This is what we did with cli before using the `--function` & `--base-image` flags
- We need to first create a container image from our function

## `Build`ing a function
1. Write a dockerfile
2. Use Google Cloud Buildpacks
  - automatically builds an optimized container for us, without having to write a Dockerfile
  - I could not get this to work with cloud run function
  - `gcloud builds submit --pack image=<location>-docker.pkg.dev/<project-id>/<repo-name>/<image-name>`

### Create a repository in Google Artifact Registry to hold our images
- `gcloud artifacts repositories create <repo name> --location=<region> --project=<project-id>`
- Create a repo named tds-workshop: `gcloud artifacts repositories create tds-workshop --repository-format=docker --location=europe-west3 --project=thmd-playground-munam`

### Build & Push the container image
There are two ways, with the same end goal but different process:
1. Using gcloud builds:
- Everything happens on the cloud.
`gcloud builds submit --tag europe-west3-docker.pkg.dev/thmd-playground-munam/tds-workshop-repo/example .`

2. Using docker
- Build and tag the container image locally and then push it to the artifact registry.
- Since my platform was mac, Docker created a linux/arm64 image by default. However, Google Cloud Run executes containers on servers with linux/amd64 (also known as x86_64) processors. My uploaded image was fundamentally incompatible and failed to start on Cloud Run's infrastructure. (took me 30 mins to figure this out :'()
- `docker build --platform linux/amd64 . --tag europe-west3-docker.pkg.dev/thmd-playground-munam/tds-workshop-repo/example`
- `docker push europe-west3-docker.pkg.dev/thmd-playground-munam/tds-workshop-repo/example:latest`


At this point, we should have an image already in the artifact registery. We can pull this information
using terraform, and use it in our cloudrun configuration.
## Terraform it
1. We fetch the uploaded container image. It contains all the code.
2. We use this image to trigger the cloud run service
