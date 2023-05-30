# test-maven-publish

[![Run tests](https://github.com/cpintado/test-maven-publish/actions/workflows/run-tests.yml/badge.svg)](https://github.com/cpintado/test-maven-publish/actions/workflows/run-tests.yml)

## Table of Contents

- [What does this tool do?](#what-does-this-tool-do)
- [Requirements](#requirements)
- [Setup](#setup)
- [How to use](#how-to-use)
- [Environment variables](#environment-variables)

## What does this tool do?

This is a docker image that when run publishes an empty package to the GitHub Packages Maven registry or to a GitHub Enterprise Server instance of your choice. In this way you can test if your GitHub Packages setup is properly configured without delving into the details of the package manager.

It accepts varios parameters, such as the package name and version, token to use for authentication, etc.

## Requirements

A Linux/Mac machine with Docker installed.

## Setup

Authenticate to the GitHub Container Registry as described in the [Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry). For example, you can go to the settings of your GitHub account, [create a personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with the `read:packages` scope, and then do the following:

```
export CR_PAT=YOUR_TOKEN
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

Once you are authenticated, you can install the tool like this:

```
docker pull ghcr.io/cpintado/test-maven-publish:v1.0.0
```

## How to use

The downloaded image can then be run using the `docker run` command. Parameters are passed to the image via environment variables.

For example, to publish a Maven package to the `cpintado-org/test-packages` repository in `github.com`, authenticating as the `cpintado` user with the <PAT> token, and setting the  GROUP_ID AND ARTIFACT_ID to 'com.example.app' and `testapp` respectively, it can be done like this:

```
docker run -e USER=cpintado -e TOKEN=<PAT> \
-e OWNER='cpintado-org' -e REPOSITORY='test-packages' \
-e GROUP_ID='com.example.app' -e ARTIFACT_ID=`testapp` \
ghcr.io/cpintado/test-maven-publish:v1.0.0
```

It can also be done by pre-defining the values of the environment variables, like this:


```
export USER=cpintado
export TOKEN=<PAT>
export OWNER='cpintado-org'
export REPOSITORY='test-packages'
export GROUP_ID='com.example.app'
export ARTIFACT_ID='testapp'
docker run -e USER -e TOKEN \
-e OWNER -e REPOSITORY \
-e GROUP_ID -e ARTIFACT_ID \
ghcr.io/cpintado/test-maven-publish:v1.0.0
```

Both of the above examples will publish to the `cpintado-org/testpackages` repository a package with the specified ARTIFACT_ID and GROUP_ID, with version number `1.0.0`.

This is the simplest example but you can use more environment variables to suit your use case.

## Environment variables

This is a reference of the environment variables that can be passed as arguments to the docker image.

| **Env variable** | **Required** | **Default value** | **Notes** |
|------------------|--------------|-------------------|-----------|
| USER | yes | N/A | Username of your personal account, as documented in [authenticating with a personal access token](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry#authenticating-with-a-personal-access-token) |
| TOKEN | yes | N/A | Personal access token with the necessary scopes (`write:packages`) |
| OWNER | yes | N/A | Owner of the repository to which the package will be published |
| REPOSITORY | yes | N/A | Name of the repository to which the package will be published |
| GROUP_ID | yes | N/A | [Maven groupId](https://maven.apache.org/guides/mini/guide-naming-conventions.html) of the package to be published/downloaded
| ARTIFACT_ID | yes | N/A | [Maven artifactId](https://maven.apache.org/guides/mini/guide-naming-conventions.html) of the package to be published/downloaded
| PACKAGE_VERSION | no | 1.0.0 | Version of the package to be published/downloaded
| MODE | no | publish | If set to `publish` it tries to publish the package, if set to `download` it tries to download a package with the same name instead |
| GHES_HOSTNAME | no | N/A | Fully qualified domain name of a GitHub Enterprise Server instance to which the package has to be published/downloaded. |
| SUBDOMAIN_ISOLATION | no | true | In case a GitHub Enterprise Server instance has been specified, a value of `true` indicates the instance has [subdomain isolation](https://docs.github.com/en/enterprise-server@3.8/admin/configuration/configuring-network-settings/enabling-subdomain-isolation) enabled. A value of `false` indicates that subdomain isolation is not enabled for the instance. This is used to determine the correct URL of the registry. 


