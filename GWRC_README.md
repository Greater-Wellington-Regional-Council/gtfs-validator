# Greater Wellington GTFS Standard Validaton Container Update Guide

## Overview

This repository is a fork of [MobilityData/gtfs-validator](https://github.com/MobilityData/gtfs-validator), maintained by Greater Wellington Regional Council. The fork includes custom modifications to accommodate GW's validation requirements.

**Why forked:** The upstream validator imposes limits (50-row HTML reports, 100m stop-to-shape distance tolerance) that are too restrictive for GW's use case. Our fork increases these limits so a user can see more warnings in the report and so a looser spatial tolerance is applied.

## The Operational Change Process

This container is used for running standard validation process over GTFS files, where warnings are preseneted in the form of an html report in the He Hapori interface.

A container with the `latest` tag is used by the live operational change process. For testing the `nonprod` tag is used. The `nonprod` tag is referenced in the dev, tst and uat fabric notebooks.

**What this document covers:** 

This guide walks through the complete update process for the container:

 - Syncing upstream updates
 - Applying GW-specific patches
 - Building Docker image
 - Deploying to Azure container registry for testing
 - Deploying to Azure Container Registry for use in production

## Syncing Upstream Updates

1. Navigate to the forked repository on GitHub
2. Click **Sync Fork** to pull the latest changes from MobilityData/gtfs-validator
3. Pull the synced changes to your local master branch:
   ```bash
   git checkout master
   git pull origin master
   ```
4. Checkout the specific version tag you want to upgrade to:
   ```bash
   git checkout v7.2.0
   ```
5. Create a new branch for the GW-specific version (this will include GWRC_README.md and push-image-to-acr.sh from master):
   ```bash
   git switch -c gw-v7.2.0
   git checkout master -- GWRC_README.md push-image-to-acr.sh
   ```

## Applying GW-specific patches

After syncing, apply GW's custom patches. 

**Patch 1: Increase HTML report row limit**
- File: `main/src/main/resources/report.html`
- Change: Replace 50-row limit with 15000 rows

**Patch 2: Increase stop-to-shape distance tolerance**
- File: `main/src/main/java/org/mobilitydata/gtfsvalidator/util/shape/StopToShapeMatcherSettings.java`
- Change: Update `DEFAULT_MAX_DISTANCE_FROM_STOP_TO_SHAPE_IN_METERS` from `100.0` to `1100.0`

N.B. You can reference previous branches (e.g., `gw-v7.1.0`) to locate where changes are needed.

Commit and push changes to your forked repository.

## Building the Container Image

**Prerequisites:** Docker Desktop, Azure CLI, access to ACR `dataplatform1commcrfabricaz2`

1. Clone the repository:
   ```bash
   git clone https://github.com/Greater-Wellington-Regional-Council/gtfs-validator.git
   ```

2. Build the Docker image locally:
   ```bash
   docker build -t gtfs-validator .
   ```

3. Verify the image was created:
   ```bash
   docker image ls gtfs-validator
   ```

## Deployment to Azure Container Registry for testing

From your laptop, start a BASH shell (within LINUX/WSL) and start the script 'push-image-to-acr.sh' with two parameters

First parameter - is the name of the local image (optionally with a suffix of ':tag').
Example: gtfs-validator:7.2.0

Second parameter - is the name of the target repository, within the Azure container registry. This should be 'gtfs-validator'. The script will push with the `nonprod` tag by default.

e.g. Push the image with the `nonprod` tag for testing in dev/tst/uat environments:

```bash
./push-image-to-acr.sh gtfs-validator:7.2.0 gtfs-validator
```

This uploads to `dataplatform1commcrfabricaz2.azurecr.io/gtfs-validator:nonprod`.

**Testing procedure:**

Pass to a metlink business user for UAT validation in the uat environment. They should:

   - Run the Operational Change standard validation process in UAT
   - Verify that an HTML report is generated with expected warnings

## Production Deployment to Azure Container Registry

After successful UAT validation, deploy to production via the change management process:

1. Tag and push the image as `prod` to create the `latest` tag in ACR:
   ```bash
   docker tag gtfs-validator:7.2.0 gtfs-validator:prod
   ./push-image-to-acr.sh gtfs-validator:prod gtfs-validator
   ```
   This uploads to `dataplatform1commcrfabricaz2.azurecr.io/gtfs-validator:latest`.

2. After deployment, communicate to stakeholders that the new version is live in production.
