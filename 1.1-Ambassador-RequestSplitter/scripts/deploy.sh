#!/usr/bin/bash
kubectl create configmap ambassador-config --from-file=conf.d

kubectl create -f web-deployment.yaml
kubectl expose deployment web-deployment --port=80 --type=ClusterIP --name web-deployment

kubectl create -f experiment-deployment.yaml
kubectl expose deployment experiment-deployment --port=80 --type=ClusterIP --name experiment-deployment

kubectl create -f ambassador-deployment.yaml
kubectl expose deployment ambassador-deployment --port=8080 --target-port=80 --type=LoadBalancer

kubectl get services --watch