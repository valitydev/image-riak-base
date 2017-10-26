#!/bin/sh
cat <<EOF
FROM scratch
LABEL com.rbkmoney.$SERVICE_NAME.parent=null \
	com.rbkmoney.$SERVICE_NAME.branch=$BRANCH \
	com.rbkmoney.$SERVICE_NAME.commit_id=$COMMIT \
	com.rbkmoney.$SERVICE_NAME.commit_number=`git rev-list --count HEAD`

WORKDIR /

COPY /portage-root/ /

CMD ["/bin/bash"]
EOF
