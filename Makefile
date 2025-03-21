DEV_REGISTRY ?= registry.drycc.cc
DRYCC_REGISTRY ?= ${DEV_REGISTRY}
IMAGE = "${DRYCC_REGISTRY}"/drycc/base:"${CODENAME}"-"$(shell dpkg --print-architecture)"
BASE_LAYER = "${IMAGE}"-prebuild
WORK_DIR = /workspace/"${CODENAME}"

SHELLCHECK_PREFIX := podman run --rm -v ${CURDIR}:/workdir -w /workdir ${DRYCC_REGISTRY}/drycc/go-dev shellcheck
SHELL_SCRIPTS = $(shell find . -name '*.sh') $(wildcard debootstrap/*/rootfs/*/bin/*) $(wildcard debootstrap/*/rootfs/*/sbin/*)

SHELL=/bin/bash -o pipefail

clean:
	@rm -rf "${WORK_DIR}" "${WORK_DIR}".tar.gz

mkimage:
	./scripts/mkimage.sh minbase "${CODENAME}" "${SOURCES}"

podman-import:
	@podman import ${WORK_DIR}.tar.gz ${BASE_LAYER}

podman-build: mkimage podman-import
	@podman build . \
	  --tag ${IMAGE} \
	  --build-arg BASE_LAYER=${BASE_LAYER} \
	  --file Dockerfile

podman-immutable-push: test-style	build
	@podman push "${IMAGE}"
	@echo -e "\\033[32m---> Build image $codename complete, enjoy life...\\033[0m"

build: podman-build

publish: podman-immutable-push

test: test-style

test-style:
	${SHELLCHECK_PREFIX} $(SHELL_SCRIPTS)
