#!/usr/bin/bash
kubectl delete service circuitbreaker
kubectl delete deployment circuitbreaker

kubectl delete configmap nginx-configuration

kubectl delete service dummy-deployment
kubectl delete deployment dummy-deployment

kubectl delete service backup-deployment
kubectl delete deployment backup-deployment
