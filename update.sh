#!/bin/bash -e

SRC_ORG='jdcloud-api'
DEST_ORG='go-acme'

SRC_REPO_NAME='jdcloud-sdk-go'
DEST_REPO_NAME='jdcloud-sdk-go'

#LIB_VERSION=v1.64.0
LIB_VERSION=$(curl -s https://api.github.com/repos/${SRC_ORG}/${SRC_REPO_NAME}/releases/latest | jq -r '.tag_name')

SRC_REMOTE="git@github.com:${SRC_ORG}/${SRC_REPO_NAME}.git"
DEST_REMOTE="git@github.com:${DEST_ORG}/${DEST_REPO_NAME}.git"

DEST_BRANCH=modifiedclient

SRC_DIR=$(mktemp -d)
DEST_DIR=$(mktemp -d)

#############

## Fake fork remote

# DEST_REMOTE=$(mktemp -d)
#
# git init -q --bare ${DEST_REMOTE}
#
# DEST_TEMP=$(mktemp -d)
# git clone -q ${DEST_REMOTE} ${DEST_TEMP}
#
# cd ${DEST_TEMP}
# git switch -q -c ${DEST_BRANCH}
# git commit -q -m "Initial empty commit" --allow-empty
# git push -q -u origin ${DEST_BRANCH}
# cd ..
#
# rm -rf ${DEST_TEMP}

## Prepare the fork
# git clone -q --single-branch git@github.com:${DEST_ORG}/${DEST_REPO_NAME}.git /tmp/${DEST_REPO_NAME}
# cd /tmp/${DEST_REPO_NAME}
# git checkout --orphan ${DEST_BRANCH}
# git rm -rf .
# git commit -m "chore: initial empty commit." --allow-empty
# git push origin ${DEST_BRANCH}
# exit 0

#############

rm -rf ${SRC_DIR}

git clone -c advice.detachedHead=false -q --branch ${LIB_VERSION} --single-branch --depth 1 "${SRC_REMOTE}" ${SRC_DIR}

rm -rf ${SRC_DIR}/.git

## Clone destination repository

rm -rf ${DEST_DIR}

git clone -q --branch ${DEST_BRANCH} --single-branch ${DEST_REMOTE} ${DEST_DIR}

cd ${DEST_DIR}

## Remove all files
git rm -f -r --ignore-unmatch '*'

## Copy the code from the sources
cp -r ${SRC_DIR}/. .


## Remove unsed files
rm .travis.yml
rm -rf demo
cd ./services/
for dir in *; do
    [ "$dir" = "domainservice" ] && continue
    rm -rf "$dir"
done
cd -

## Create the module
go mod init github.com/${DEST_ORG}/${DEST_REPO_NAME}

## Replace all the imports
find . -type f -name "*.go" -exec sed -i "s/github.com\/${SRC_ORG}\/${SRC_REPO_NAME}/github.com\/${DEST_ORG}\/${DEST_REPO_NAME}/g" {} +

## Convert the code
sed -E '
# --- Transform receiver (client *Client) to parameter ---

s|\(c \*DomainserviceClient\) ([^(]+)\(request|\1(c *DomainserviceClient, request|
' services/domainservice/client/DomainserviceClient.go > services/domainservice/client/DomainserviceClient_modified.go

rm services/domainservice/client/DomainserviceClient.go

## Check compilation
go mod tidy -go=1.23.0
golangci-lint fmt -Egofmt
go build ./services/domainservice/...

## Commit and Push

git add .
git commit -q -m "feat: update to ${LIB_VERSION}"

git push -q origin ${DEST_BRANCH}
git tag ${LIB_VERSION}
git push -q origin ${LIB_VERSION}

cd ..

rm -rf ${SRC_DIR}
rm -rf ${DEST_DIR}

##########################

# echo ${DEST_DIR}
#
# rm -rf ${DEST_REMOTE}
#
# cd /home/ldez/sources/go-acme/lego
#
# go mod edit -dropreplace github.com/${SRC_ORG}/${SRC_REPO_NAME}
# go mod edit -replace github.com/${SRC_ORG}/${SRC_REPO_NAME}=${DEST_DIR}
# go mod tidy
