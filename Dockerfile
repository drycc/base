ARG BASE_LAYER
FROM ${BASE_LAYER}
ENV PATH "/opt/drycc/*/bin:/opt/drycc/*/sbin:$PATH"