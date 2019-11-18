#!/bin/bash

set -euxo

id="xxxxx-yyyyyy-zzzzz"

# clean up
if [ -d "spec-test" ]; then
    pushd spec-test/
    ls -1 | grep yaml | grep -v 'fission-deployment-config.yaml' | xargs -I@ kubectl -n default delete -f @
    popd
    rm -rf spec-test/
fi

mkdir spec-test

pushd spec-test

# create a spec directory with the same deploy id
fission spec init --deployid ${id}

# create a v1 interface environment (only supports single file function)
fission env create --spec --name nodejs --image fission/node-env:1.6.0 --period 5

# create a package with single source file function
fission pkg create --spec --name dummy-1 --env nodejs --code \
    https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js

fission fn create --spec --name hello1 --env nodejs --pkg dummy-1

# # create a v2 interface environment (supports to load function with given entrypoint)
fission env create --spec --name nodejsv2 --image fission/node-env:1.6.0 --builder fission/node-builder:1.6.0 --version 2  --period 5

# the creation of fn.zip, see demo.sh in with-fission-cli
fission pkg create --spec --name dummy-2 --env nodejsv2 --deploy https://raw.githubusercontent.com/life1347/fission-spec-demo/master/with-kubectl/fn.zip

fission fn create --spec --name hello2 --env nodejsv2 --pkg dummy-2 --entrypoint "helloworld"

# apply spec files with kubectl
pushd specs
ls -1 | grep yaml | grep -v 'fission-deployment-config.yaml' | xargs -I@ kubectl -n default apply -f @

set +x

echo ""

echo "Wait for environment image pulling"
sleep 15

echo ""

echo "Test function hello1"
fission fn test --name hello1

echo ""

echo "Test function hello2"
fission fn test --name hello2

echo ""
echo ""

set -x

ls -1 | grep yaml | grep -v 'fission-deployment-config.yaml' | xargs -I@ kubectl -n default delete -f @
popd

popd