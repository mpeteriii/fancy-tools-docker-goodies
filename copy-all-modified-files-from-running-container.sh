#!/bin/bash

IMAGE_NAME=$1
CONTAINER_ID=$2
DEST_DIR=$3

# Ensure the image name, container ID and destination directory are not empty
if [[ -z "${IMAGE_NAME}" ]]; then
    echo "You must provide an image name as the first argument."
    exit 1
fi

if [[ -z "${CONTAINER_ID}" ]]; then
    echo "You must provide a container ID as the second argument."
    exit 1
fi

if [[ -z "${DEST_DIR}" ]]; then
    echo "You must provide a destination directory as the third argument."
    exit 1
fi

# Ensure the destination directories exist
mkdir -p "${DEST_DIR}/modified"
mkdir -p "${DEST_DIR}/original"

# Start a new container from the same image in the background
CLEAN_CONTAINER_ID=$(docker run -d "${IMAGE_NAME}" tail -f /dev/null)

# Get the list of changed files
CHANGED_FILES=$(docker diff ${CONTAINER_ID} | while read line; do FILE=$(echo $line | cut -c3-); docker exec ${CONTAINER_ID} bash -c "if test -f \"$FILE\"; then echo $line; fi"; done)
#$(docker diff "${CONTAINER_ID}" | awk '{print $2}')

# Copy each file from the modified and clean containers
for file in ${CHANGED_FILES}; do
    echo "$file"
    mkdir -p "${DEST_DIR}/modified/${file}"
    mkdir -p "${DEST_DIR}/original/${file}"
    rm -rf "${DEST_DIR}/modified/${file}"
    rm -rf "${DEST_DIR}/original/${file}"
    docker cp "${CONTAINER_ID}:${file}" "${DEST_DIR}/modified/${file}"
    docker cp "${CLEAN_CONTAINER_ID}:${file}" "${DEST_DIR}/original/${file}"
done

# Stop and remove the clean container
docker stop "${CLEAN_CONTAINER_ID}"
docker rm "${CLEAN_CONTAINER_ID}"

