# Service Discovery
## Exponer un deployment con ClusterIP

Vamos a crear un deployment con la imagen hello-app:
```
kubectl create deployment hello-world-clusterip \
    --image=gcr.io/google-samples/hello-app:1.0
```

Lo expondemos para crear el servicio con:
```
kubectl expose deployment hello-world-clusterip \
    --port=80 --target-port=8080 --type ClusterIP
```

Listaremos los servicios viendo el tipo de seervicio que se ha creado:
```
kubectl get service
```

Guardamos la IP del servicio en una variable
```
SERVICEIP=$(kubectl get service hello-world-clusterip -o jsonpath='{ .spec.clusterIP }')
echo $SERVICEIP
```

Desde dentro del cluster podemos acceder a la IP de servicio:
```
curl http://$SERVICEIP
```

Listamos los endpoints del servicio:
```
kubectl get endpoints hello-world-clusterip
kubectl get pods -o wide
```

Escalaremos el deployment y los nuevos elementos del endpoint se registrarán automáticamente:
```
kubectl scale deployment hello-world-clusterip --replicas=6
kubectl get endpoints hello-world-clusterip
```

El servicio seguirá respondiendo correctamente:
```
curl http://$SERVICEIP
```

Como hemos visto, los endpoints matchean los labels que se han configurado al crear el deployment:
```
kubectl describe service hello-world-clusterip
kubectl get pods --show-labels
```

Podemos limpiar los recursos creados:
```
kubectl delete deployments hello-world-clusterip
kubectl delete service hello-world-clusterip
```

## Exponer un deployment con NodePort
Crearemos ahora un deployment y lo expondremos con un servicio del tipo NodePort:
```
kubectl create deployment hello-world-nodeport \
    --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-world-nodeport \
    --port=80 --target-port=8080 --type NodePort
```
Verificamos el servicio creado:
```
kubectl get service
```

Almacenaremos en variables la IP del servicio, el puerto de la aplicación y el nodeport que nos ha creado:
```
CLUSTERIP=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.clusterIP }')
PORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].port }')
NODEPORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].nodePort }')
```

Verificamos los pods creados:
```
kubectl get pods -o wide
```

Podremos llegar al servicio conectándonos a la IP de cualquier nodo del cluster en el puerto que nos ha asignado el servicio:
```
curl http://node1:$NODEPORT
curl http://node2:$NODEPORT
```

Podemos verificar que también nos funcionará la conexión a la IP del cluster y al puerto:
```
echo $CLUSTERIP:$PORT
curl http://$CLUSTERIP:$PORT
```

Liberamos los recursos creados:
```
kubectl delete service hello-world-nodeport
kubectl delete deployment hello-world-nodeport
```