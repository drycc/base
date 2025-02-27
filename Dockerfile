ARG BASE_LAYER
FROM ${BASE_LAYER}
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive
RUN ln -sf /bin/bash /bin/sh
ENTRYPOINT ["init-stack"]
