#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/../..; pwd)"
ENV_CODE=${1:-${ENV_CODE}}

if [[ -z "$1" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

set -ae
ENV_NAME=${ENV_NAME:-"stac-${ENV_CODE}"}
STAC_FASTAPI_VERSION=${STAC_FASTAPI_VERSION:-"2.4.0"}
PROCESSING_RESOURCE_GROUP=${PROCESSING_RESOURCE_GROUP:-"${ENV_CODE}-processing-rg"}

ACR_NAME=$(az acr list -g ${PROCESSING_RESOURCE_GROUP} \
    --query "[?tags.environment && tags.environment == '$ENV_NAME'].name" -otsv)

az acr build --registry $ACR_NAME --image stac-event-consumer ${PRJ_ROOT}/src/stac_ingestion/stac_to_pg/
az acr build --registry $ACR_NAME --image generate-stac-json ${PRJ_ROOT}/src/stac_ingestion/generate_stac_item/
az acr build --registry $ACR_NAME --image stac-collection ${PRJ_ROOT}/src/stac_ingestion/stac_collection/

# build stac-fastapi from https://github.com/stac-utils/stac-fastapi/archive/refs/tags/${STAC_FASTAPI_VERSION}.tar.gz
STAC_FASTAPI_SRC_DIR=${STAC_FASTAPI_SRC_DIR:-"${PRJ_ROOT}/src/stac_fastapi_k8s/src"}
STAC_FASTAPI_RELEASE_URI=${STAC_FASTAPI_RELEASE_URI:-"https://github.com/stac-utils/stac-fastapi/archive/refs/tags/${STAC_FASTAPI_VERSION}.tar.gz"}
mkdir -p $STAC_FASTAPI_SRC_DIR
# wget $STAC_FASTAPI_RELEASE_URI -P $STAC_FASTAPI_SRC_DIR
# tar xvf ${STAC_FASTAPI_SRC_DIR}/${STAC_FASTAPI_VERSION}.tar.gz -C ${STAC_FASTAPI_SRC_DIR}
# az acr build --registry $ACR_NAME --image stac-fastapi ${STAC_FASTAPI_SRC_DIR}/stac-fastapi-${STAC_FASTAPI_VERSION}

# Released versions of stac-fastapi are broken because of an unreleased fix https://github.com/stac-utils/stac-fastapi/pull/466
# Using github master branch for the build as of now
# TODO: Uncomment the code above and comment/remove this code which pulls stac-fastapi from master branch
git clone https://github.com/stac-utils/stac-fastapi $STAC_FASTAPI_SRC_DIR/stac-fastapi
CURRENT_WORKING_DIRECTORY="$(pwd)"
cd $STAC_FASTAPI_SRC_DIR/stac-fastapi
git reset --hard 926698034f836ed4db13e03c9c33257c4a86020a
cd $CURRENT_WORKING_DIRECTORY
az acr build --registry $ACR_NAME --image stac-fastapi ${STAC_FASTAPI_SRC_DIR}/stac-fastapi
rm -rf ${STAC_FASTAPI_SRC_DIR}