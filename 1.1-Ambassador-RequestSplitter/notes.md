# 1.1 Ambassador (Single Node Pattern) - Request Splitter

[Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

[Reference GitHub Repo](https://github.com/brendandburns/designing-distributed-systems-labs/blob/master/1.%20Single%20Node%20Pattern/1.1.%20Request%20Splitter/README.md)

Use local K8s cluster (with [k3s](https://rancher.com/docs/k3s/latest/en/quick-start/)) because AKS isn't available on Free Tier. Methodology is similar beyond setup of the K8s CLI context.
    - Once installed it should restart whenever the machine boots.
    - Stop using `sh /usr/local/bin/k3s-killall.sh`
    - To use localhost as the External IP for Load Balancers, stop then start again with `sudo k3s server --node-external-ip 127.0.0.1`

## Quickstart

- With your kubectl context configured, deploy with `sh ./scripts/deploy.sh`
- Teardown with `sh ./scripts/teardown.sh`

## Steps

1. Check K8s configuration with `kubectl cluster-info`
    - List contexts `kubectl config get-contexts`
2. Create NGINX proxy configuration for the ambassador and generate K8s config map with `kubectl create configmap ambassador-config --from-file=conf.d`
   - [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) are the Kubernetes way to inject application pods with configuration data.
3. Implement web server dpeloyment using [MS "Hello World!" image](https://hub.docker.com/_/microsoft-azuredocs-aci-helloworld) in `web-development.yaml`
   - Docker image will process requests on port 80 and return a basic Hello World! HTML response.
   - Deploy with `kubectl create -f web-deployment.yaml` - automatically creates the pod.
     - Couldn't use `apiVersion: extensions/v1beta1`, find available suitable apiVersion using `kubectl api-resources | grep deployment`
     - Need to update `apiVersion` to `apps/v1`
     - Add [selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) and [resource limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) to satisfy K8s validation.
        - Selector in spec.selector.matchLabels needed to match spec.template.metadata.labels
   - Expose with `kubectl expose deployment web-deployment --port=80 --type=ClusterIP --name web-deployment`
4. Implement experiemntal web server in `experiment-deployment.yaml`
    - Similar process to above
    - Deploy with `kubectl create -f experiment-deployment.yaml`
    - Expose with `kubectl expose deployment experiment-deployment --port=80 --type=ClusterIP --name experiment-deployment`
5. Create K8s deployment in `ambassador-deployment.yaml` to deploy the load balancing service
    - Uses the ConfigMap for the custom NGINX config, created above:

            volumes:
            - name: config-volume
            configMap:
                name: ambassador-config

    - Need to update the apiVersion
    - Deploy with `kubectl create -f ambassador-deployment.yaml`
    - Expose with `kubectl expose deployment ambassador-deployment --port=8080 --targetPort=80 --type=LoadBalancer`
6. Confirm deployment
    - List pods with `kubectl get pods --output=wide`. We can see the replicas of our deployed conatiners.

            NAME                                     READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
            web-deployment-6d4764d879-stqsd          1/1     Running   0          47s   10.42.0.22   pop-os   <none>           <none>
            web-deployment-6d4764d879-slpkv          1/1     Running   0          47s   10.42.0.21   pop-os   <none>           <none>
            experiment-deployment-5699d86cb5-8pd7n   1/1     Running   0          26s   10.42.0.23   pop-os   <none>           <none>
            experiment-deployment-5699d86cb5-hw76z   1/1     Running   0          26s   10.42.0.24   pop-os   <none>           <none>
            ambassador-deployment-58d54f45-zlnt5     1/1     Running   0          12s   10.42.0.26   pop-os   <none>           <none>
            ambassador-deployment-58d54f45-j7nmb     1/1     Running   0          12s   10.42.0.25   pop-os   <none>           <none>
    
    - List deployments with `kubectl get services --watch` to get an IP address for our services

            NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
            kubernetes              ClusterIP      10.43.0.1       <none>        443/TCP          6m57s
            web-deployment          ClusterIP      10.43.154.17    <none>        80/TCP           5m46s
            experiment-deployment   ClusterIP      10.43.106.179   <none>        80/TCP           5m25s
            ambassador-deployment   LoadBalancer   10.43.166.216   127.0.0.1     8080:32587/TCP   5s

7. Test the deployment
    - Go to http://127.0.0.1:8080 (ambassador-depoyment External IP) once available
    - Run `sh ./scripts/test.sh`
    - Run `kubectl logs -l app=web-deployment` - You will see about 18 rows logged in the log-file
    - Run `kubectl logs -l app=experiment-deployment` - You will see about 2 rows logged in the log-file
                