# Drycc Base Image

[![Build Status](https://drone.drycc.cc/api/badges/drycc/base/status.svg)](https://drone.drycc.cc/drycc/base)

A slimmed-down Debian-based container image used as the basis of [Drycc Workflow](https://github.com/drycc/workflow) and other components.

## Usage

Start your Dockerfile with this line:

```
FROM docker.io/drycc/base:bullseye
```

There isn't a `:latest` tag, because each debian version is a tag.

## Install Stack

This base image supports drycc stack installation, its usage is:

```
install-stack postgresql 14.1 /opt/drycc
```

All stacks currently supported by drycc are in the [stacks](https://github.com/drycc/stacks) project.
You can view and use them.

## Install Packages

These images also include an `install-packages` command that you can use instead of apt. This takes care of some things for you:
  * Install the named packages, skipping prompts etc.
  * Clean up the apt metadata afterwards to keep the image small.
  * Retrying if apt fails. Sometimes a package will fail to download due to a network issue, and this may fix that, which is particularly useful in an automated build pipeline.

  For example:
  ```
  $ install-packages apache2 memcached
  ```