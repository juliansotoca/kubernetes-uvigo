# Configurando DNS
## Verificando configuración
kubectl get service --namespace kube-system


Se instalan dos répicas, los argumentos indican la ubicación del fichero de configuración que es gestionado por un ConfigMap montado como un volumen
```
kubectl describe deployment coredns --namespace kube-system | more
```

```
kubectl get configmaps --namespace kube-system coredns -o yaml | more
```



## Uso de custom Frowarders

kubectl apply -f CoreDNSConfigCustom.yaml --namespace kube-system

kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow


dig teleco.uvigo.es
dig www.google.com

kubectl apply -f CoreDNSConfigDefault.yaml --namespace kube-system

## Modificando la resolución de DNS en un Pod

kubectl apply -f DeploymentCustomDns.yaml

PODNAME=$(kubectl get pods --selector=app=nginx-customdns -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME

kubectl delete -f DeploymentCustomDns.yaml

