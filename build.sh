#!/bin/bash
set -x

echo "Building gvtg kernel, this may take some time"
echo "Run this command to follow the logs: "
echo "docker logs -f building-gvtg"
cwd=$(pwd)
profiledir="$(dirname "$0")"

if [ ! -z "${http_proxy}" ]; then
  docker build --env http_proxy=${http_proxy} --env https_proxy=${https_proxy} --env HTTP_PROXY=${http_proxy} --env HTTPS_PROXY=${https_proxy} --env NO_PROXY=localhost,127.0.0.1 -t builder-gvtg --build-arg cwd=$cwd $profiledir
  docker run --rm --env http_proxy=${http_proxy} --env https_proxy=${https_proxy} --env HTTP_PROXY=${http_proxy} --env HTTPS_PROXY=${https_proxy} --env NO_PROXY=localhost,127.0.0.1 --name building-gvtg -v $cwd:$cwd -e profiledir=$profiledir builder-gvtg
else
  docker build -t builder-gvtg --build-arg cwd=$cwd $profiledir
  docker run --rm --name building-gvtg -v $cwd:$cwd -e profiledir=$profiledir builder-gvtg
fi