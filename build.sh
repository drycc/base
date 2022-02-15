#!/bin/bash

# Build a base image
DRYCC_REGISTRY=${DRYCC_REGISTRY:-${DEV_REGISTRY:-docker.io}}

for codename in "$@"
do
    ./mkimage.sh minbase "${codename}"
    image="${DRYCC_REGISTRY}"/drycc/base:"${codename}"-"$(dpkg --print-architecture)"
    docker build . \
      --tag $image \
      --build-arg CODENAME="${codename}" \
      --build-arg BASE_LAYER=$(docker import /workspace/"${codename}".tar.gz) \
      --file Dockerfile

    docker push "${image}"
    rm -rf /workspace/"${codename}" /workspace/"${codename}".tar.gz
    echo -e "\\033[32m---> Build image $codename complete, enjoy life...\\033[0m"
done
