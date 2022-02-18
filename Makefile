CODENAME ?= bullseye
DEV_REGISTRY ?= docker.io
DRYCC_REGISTRY ?= ${DEV_REGISTRY}
IMAGE = "${DRYCC_REGISTRY}"/drycc/base:"${CODENAME}"-"$(shell dpkg --print-architecture)"
WORK_DIR = /workspace/"${CODENAME}"

SHELLCHECK_PREFIX := docker run --rm -v ${CURDIR}:/workdir -w /workdir ${DRYCC_REGISTRY}/drycc/go-dev shellcheck
SHELL_SCRIPTS = $(shell find . -name '*.sh') $(wildcard debootstrap/*/rootfs/*/bin/*) $(wildcard debootstrap/*/rootfs/*/sbin/*)

SHELL=/bin/bash -o pipefail

clean:
	@rm -rf "${WORK_DIR}" "${WORK_DIR}".tar.gz

mkimage:
	./scripts/mkimage.sh minbase "${CODENAME}"

build: mkimage
	@docker build . \
	  --tag ${IMAGE} \
	  --build-arg BASE_LAYER=$(shell docker import ${WORK_DIR}.tar.gz) \
	  --file Dockerfile

publish: test-style	build
	@docker push "${IMAGE}"
	@echo -e "\\033[32m---> Build image $codename complete, enjoy life...\\033[0m"

test-style:
	${SHELLCHECK_PREFIX} $(SHELL_SCRIPTS)