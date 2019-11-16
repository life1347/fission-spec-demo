#!/bin/bash

set -euxo

id="xxxxx-yyyyyy-zzzzz"

# clean up
if [ -d "spec-test" ]; then
    pushd spec-test/
    fission spec destroy
    rm -rf spec-test/
fi

mkdir spec-test

cp -r nodejs-example spec-test/

pushd spec-test

# create a spec directory with the same deploy id
fission spec init --deployid ${id}

# create a v1 interface environment (only supports single file function)
fission env create --spec --name nodejs --image fission/node-env:1.6.0 --period 5

# create a package with single source file function
fission pkg create --spec --name dummy-1 --env nodejs --code \
    https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js --keepurl

fission fn create --spec --name hello1 --env nodejs --pkg dummy-1

pushd nodejs-example
npm install
zip -r fn.zip .
popd

mv nodejs-example/fn.zip .

# create a v2 interface environment (supports to load function with given entrypoint)
fission env create --spec --name nodejsv2 --image fission/node-env:1.6.0 --builder fission/node-builder:1.6.0 --version 2  --period 5

fission pkg create --spec --name dummy-2 --env nodejsv2 --deploy fn.zip

fission fn create --spec --name hello2 --env nodejsv2 --pkg dummy-2 --entrypoint "helloworld"

fission spec apply

set +x

echo ""

echo "Test function hello1"
fission fn test --name hello1

echo ""

echo "Test function hello2"
fission fn test --name hello2

echo ""
echo ""

set -x

fission spec destroy

popd