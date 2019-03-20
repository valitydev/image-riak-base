#!/bin/sh
cat <<EOF
FROM ${REGISTRY}/${ORG_NAME}/build:${BUILD_IMAGE_TAG} as build
RUN rm /etc/portage/repos.conf/*.conf
COPY files/portage/ /etc/portage
COPY portage/ /usr/portage
COPY overlays/ /var/lib/layman

COPY files/install.sh /
RUN /install.sh

FROM scratch 
COPY --from=build /tmp/portage-root/ /
RUN busybox --install
LABEL com.rbkmoney.${SERVICE_NAME}.parent=null \
    com.rbkmoney.${SERVICE_NAME}.parent_tag=null  \
    com.rbkmoney.${SERVICE_NAME}.branch=${BRANCH}  \
    com.rbkmoney.${SERVICE_NAME}.commit_id=${COMMIT}  \
    com.rbkmoney.${SERVICE_NAME}.commit_number=`git rev-list --count HEAD`
EOF
