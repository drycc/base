ARG BASE_LAYER
FROM ${BASE_LAYER}
ENV LANG C.UTF-8
RUN ln -sf /bin/bash /bin/sh
ENTRYPOINT ["init-stack"]
