#!/usr/bin/bash
kubectl create -f dummy-deployment.yaml
kubectl expose deployment dummy-deployment --port=8080 --target-port=80 --type=LoadBalancer --name dummy-deployment

kubectl create -f backup-deployment.yaml
kubectl expose deployment backup-deployment --port=8080 --target-port=80 --type=LoadBalancer --name backup-deployment

kubectl create -f nginx-configmap.yaml

kubectl create -f circuitbreaker.yaml

kubectl get pods --output=wide
kubectl get services --watch