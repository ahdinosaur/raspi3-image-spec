#!/bin/bash -e

DOCKER="docker"
set +e
$DOCKER ps >/dev/null 2>&1
if [ $? != 0 ]; then
	DOCKER="sudo docker"
fi
if ! $DOCKER ps >/dev/null; then
	echo "error connecting to docker:"
	$DOCKER ps
	exit 1
fi
set -e

CONTAINER_NAME=${CONTAINER_NAME:-raspi_work}
CONTINUE=${CONTINUE:-0}
PRESERVE_CONTAINER=${PRESERVE_CONTAINER:-0}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	cat >&2 <<EOF
Usage:
    build-docker.sh [options]
Optional environment arguments: ( =<default> )
    CONTAINER_NAME=raspi_work  set a name for the build container
    CONTINUE=1                 continue from a previously started container
    PRESERVE_CONTAINER=1       keep build container even on successful build
EOF
	exit 1
fi

CONTAINER_EXISTS=$($DOCKER ps -a --filter name="$CONTAINER_NAME" -q)
CONTAINER_RUNNING=$($DOCKER ps --filter name="$CONTAINER_NAME" -q)
if [ "$CONTAINER_RUNNING" != "" ]; then
	echo "The build is already running in container $CONTAINER_NAME. Aborting."
	exit 1
fi
if [ "$CONTAINER_EXISTS" != "" ] && [ "$CONTINUE" != "1" ]; then
	echo "Container $CONTAINER_NAME already exists and you did not specify CONTINUE=1. Aborting."
	echo "You can delete the existing container like this:"
	echo "  $DOCKER rm -v $CONTAINER_NAME"
	exit 1
fi

$DOCKER build -t raspi .
if [ "$CONTAINER_EXISTS" != "" ]; then
	trap "echo 'got CTRL+C... please wait 5s'; $DOCKER stop -t 5 ${CONTAINER_NAME}_cont" SIGINT SIGTERM
	time $DOCKER run --rm --privileged \
		--volumes-from="${CONTAINER_NAME}" --name "${CONTAINER_NAME}_cont" \
                -v /dev:/dev \
		raspi \
		bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static &&
        cd /raspi && ./build.sh &&
        echo wait &&
	cp work/build.log output/" &
	wait "$!"
else
	trap "echo 'got CTRL+C... please wait 5s'; $DOCKER stop -t 5 ${CONTAINER_NAME}" SIGINT SIGTERM
	time $DOCKER run --name "${CONTAINER_NAME}" --privileged \
                -v /dev:/dev \
		"${config_file[@]}" \
		raspi \
		bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static;
        cd /raspi && ./build.sh &&
        echo wait &&
	cp work/build.log output/" &
	wait "$!"
fi
echo "copying results from output/"
$DOCKER cp "${CONTAINER_NAME}":/raspi/output .
ls -lah output

# cleanup
if [ "$PRESERVE_CONTAINER" != "1" ]; then
	$DOCKER rm -v $CONTAINER_NAME
fi

echo "Done! Your image(s) should be in output/"
