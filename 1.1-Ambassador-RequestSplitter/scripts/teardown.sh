kubectl delete service ambassador-deployment
kubectl delete configmap ambassador-config
kubectl delete deployment ambassador-deployment

kubectl delete deployment web-deployment
kubectl delete deployment experiment-deployment
kubectl delete service web-deployment
kubectl delete service experiment-deployment