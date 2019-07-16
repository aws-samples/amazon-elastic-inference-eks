#!/bin/bash

TAG=$(git log -1 --pretty=%H)

echo EI APP --------------------------------------------------------------------

APP_REPOSITORY=rnzdocker1/eks-elastic-inference-app

python -m py_compile test.py

docker build --tag $APP_REPOSITORY:$TAG .

docker push $APP_REPOSITORY:$TAG

echo EI TensorFlow Serving -----------------------------------------------------

SERVING_REPOSITORY=rnzdocker1/eks-elastic-inference-serving

docker build --file Dockerfile_tf_serving --tag $SERVING_REPOSITORY:$TAG .

docker push $SERVING_REPOSITORY:$TAG


