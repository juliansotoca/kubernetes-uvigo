## Investigando la Red

Añadiendo la salida extendida podemos ver la IP de nuestros nodos:
```
kubectl get nodes -o wide
```

Vamos a desplegar un deployment y exponer un servicio:
```
kubectl apply -f Deployment.yaml
```
Veremos la IP de los pods que se han arrancado:
```
kubectl get pods -o wide
```

Vamos a seleccionar uno de ellos y nos conectaremos a él:
```
PODNAME=$(kubectl get pods --selector=app=nginx -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME
kubectl exec -it $PODNAME -- /bin/sh
```
Ya dentro del pod veremos la configuración de red que tiene:
```
apt update && apt install -y iproute2
ip addr
exit
```

Podemos ver mas detalles de los nodos:
```
kubectl describe node node2 | more
```

Si nos conectamos a uno de los nodos podremos ver la configuración de red y rutas que nuestro plugin de CNI ha creado:
```
ssh node2
ip addr
route
```
Finalmente borramos el deployment:
```
kubectl delete -f Deployment.yaml
```