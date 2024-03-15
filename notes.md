### Install Nginx Ingress 

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm -n ingress-nginx install ingress-nginx ingress-nginx/ingress-nginx --create-namespace
kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller
```

### Cert Manager

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
cert-manager jetstack/cert-manager \
 --namespace cert-manager \
 --create-namespace \
 --version v1.8.0 \
 --set installCRDs=true

kubectl get pods --namespace cert-manager
```


