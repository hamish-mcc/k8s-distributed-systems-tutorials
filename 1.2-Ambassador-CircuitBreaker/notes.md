# 1.1 Ambassador (Single Node Pattern) - Circuit Breaker

_Deploying a Circuit Breaking ambassador with NGINX Ingress and Kubernetes_

Circuit Breaker pattern can help you prevent, mitigate and manage failures by:

- allowing failing services to recover, before sending them requests again
- re-routing traffic to alternative data sources
- rate limiting

With a Circuit Breaker, the Client will no longer be able to overload the Service with requests after the Circuit Breaker was "tripped" after a failure.

[More reading](https://www.nginx.com/blog/introducing-the-nginx-microservices-reference-architecture/) from NGINX - Microservices reference architecture.

## Steps

1. Verify local k8s configuration with `kubectl cluster-info`

   - Restart k3s for this lab using, `sh /usr/local/bin/k3s-killall.sh` then `sudo k3s server --node-external-ip 127.0.0.1`.

2. Create a container registry. The lab uses ACI, but I set up a local registry (using this [Docker guide](https://docs.docker.com/registry/deploying/)) instead.

   - Run local registry using `docker run -d -p 5000:5000 --restart=always --name registry registry:2`
   - Exampl tag `docker tag ubuntu:16.04 localhost:5000/my-ubuntu`
   - Example push `docker push localhost:5000/my-ubuntu`
   - Example pull `docker pull localhost:5000/my-ubuntu`

3. Build and push the Dummy service to the local container registry.

   - Copy the DummyServiceContainer from the lab [GitHub Repo](https://github.com/brendandburns/designing-distributed-systems-labs/tree/master/1.%20Single%20Node%20Pattern/1.2.%20Circuit%20Breaker)
     - Has a a `/fakeerrormodeon` endpoint so we can make the service health check on `/ready` fail and trigger the Circuit Breaker. There is also a `/fakeerrormodeoff` endpoint to reverse it.
   - Build and push the container
     - `cd DummyServiceContainer`
     - `docker build . -t localhost:5000/dummyservice`
     - `docker push localhost:5000/dummyservice`

4. Deploy the DummyService

   - livenessProbe configuration, tells k8s to check the container's health status by calling the /alive endpoint on our container every 10 seconds
   - Deploy `kubectl create -f dummy-deployment.yaml`
   - Expose `kubectl expose deployment dummy-deployment --port=8080 --target-port=80 --type=LoadBalancer --name dummy-deployment`
   - Verify `kubectl get pods --output=wide` and `kubectl get services`
   - Test the `/alive` endpoint `curl http://127.0.0.1:8080/alive`. Retuns 'OK'.
     - `/ready` should return 'OK'
     - `/` should return 'SOMERESPONSE'

5. Deploy the Backup DummyServiceContainer
   - Process all the requests when the dummy-deployment server becomes unhealthy.
   - Deploy `kubectl create -f backup-deployment.yaml`
   - Expose `kubectl expose deployment backup-deployment --port=8080 --target-port=80 --type=LoadBalancer --name backup-deployment`
   - Verify `kubectl get pods --output=wide` and `kubectl get services`

6. Deploy the circuit breaker
    - NGINX Plus provides out-of-the-box features for Circuit Breaking (most of these features are only available in the commercial version of NGINX Plus).
    - [Build an NGINX Plus image](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/)
