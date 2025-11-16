# GW update instructions

This repo has been forked from MobilityData/gtfs-validator.

To Build and Publish the container image to ACR, follow these steps:

Requires: Docker Desktop, Azure CLI, access to the ACR `dataplatform1commcrfabricaz2`.

1. Clone this repo to your local machine

```git clone
git clone https://github.com/Greater-Wellington-Regional-Council/gtfs-validator.git
```

2. Build the image

```
docker build -t gtfs-validator .
```

3. Use the script `push-image-to-acr.sh` with the name of your container:

```bash
./push-image-to-acr.sh gtfs-validator
```

The script uses defaults of pushing to the ACR `dataplatform1commcrfabricaz2` and tagging the image as `nonprod`.

The `latest` tag is used by the live operational change process. For testing use the `nonprod` tag. The `nonprod` tag is referenced in the dev, tst and uat fabric notebooks.

To upgrade to a new version follow these steps:

1. Go to github, into the forked repo and click 'Sync Fork'
2. Checkout the tag of the version you want to upgrade to, e.g.

   ```
   git checkout v7.2.0
   ```

3. create a new branch for the upgrade, e.g.
   ```
   git switch -c gw-v7.2.0
   ```
4. Make our custom changes (specified below) to the codebase.

5. Commit and push your changes to your forked repo.
6. Follow the instructions above for building and publishing the image to ACR.

## Our Custom Changes

There are currently two changes and there are details below how to apply each:

a. Open the main/src/main/resources/report.html file and change the places imposing a 50 row limit in the html report to 15000 rows.

b. Open the main\src\main\java\org\mobilitydata\gtfsvalidator\util\shape\StopToShapeMatcherSettings.java file, and change the value for 'public static final double DEFAULT_MAX_DISTANCE_FROM_STOP_TO_SHAPE_IN_METERS' from 100.0 to 1100.0.

You can check the previous branch (e.g. gw-v7.1.0) for where these changes need to occur.

# Testing

Prior to starting, ensure that you have access to the He Hapori folders used by the business to place their schedule files.

To test a new version of the gtfs-validator, the process is basically:

- download the latest software
- apply our internal patches (take care - the line numbers may have changed)
- run that patched version against the same input file as the previous version (this will be be 'zip' file produced by the business)
- compare the outputs (that the exist, and that the filesize is approximately the same)

## Rules

1. After running gtfs file, the container should output an html file to the expected lakehouse file location.
2. The file size should be approximately the same size as previous runs with the same gtfs file.

For a manual check - for now
a. Check that there is an html file in the lakehouse folder, main/src/main/resources
b. Check that the size of this html file is approximately the same size as that produced by the previous run

# Pass to business user to run gtfs validation in the uat environment, confirm the output is as expected.

# Deploy to production through change management process.

1. Publish the container image to ACR with the `latest` tag (See shell script operation notes below).
2. After production deployment, confirm the output is as expected by business.

# Shell script operation

From your laptop, start a BASH shell (within LINUX/WSL) and start the script 'push-image-to-acr.sh' with two parameters

First parameter - is the name of the local image (optionally with a suffix of ':tag').
Example: gtfs-validator:7.2.0

Second parameter - is the name of the target repository, within the Azure container registry. This should be 'gtfs-validator'

## Notes

1. The image tag value of 'prod' will result in the uploaded image tag of 'latest'. All other tags will upload an image with the tag 'nonprod'

Examples:

> push-image-to-acr.sh gtfs-validator:7.2.0 gtfs-validator
> .. will upload the '7.2.0' tagged image as gtfs-validator tag 'nonprod'

> push-image-to-acr.sh gtfs-validator:prod gtfs-validator
> .. will upload the 'prod' tagged image as gtfs-validator tax 'latest'
