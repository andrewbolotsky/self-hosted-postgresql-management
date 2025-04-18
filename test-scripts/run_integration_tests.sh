#!/bin/bash
TEST_DIRECTORY="./test-volume"
BEFORE=$DOCKER_VOLUME_DIRECTORY
export DOCKER_VOLUME_DIRECTORY=$TEST_DIRECTORY

docker compose -f compose.yml -f compose.test.yml up --abort-on-container-exit --force-recreate --build
TEST_EXIT_CODE=$?
DOCKER_VOLUME_DIRECTORY=$BEFORE
sudo rm -rf $TEST_DIRECTORY
docker compose -f compose.yml -f compose.test.yml down -v
echo "Cleaning up test environment..."
exit $TEST_EXIT_CODE