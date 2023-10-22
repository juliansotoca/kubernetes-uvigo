# Controllers
## Controladores de sistema
Vamos a analizar los controladores que hay en el sistema. Estos son los que soportan todo el control plane:
```
kubectl get --namespace kube-system all
```
Estos objetos se han desplegado con static manifests.

Veamos alguno de ellos, por ejemplo coredns, que necesita 2 pods levantados en todo momento:
```
kubectl get --namespace kube-system deployments coredns
```

También tenemos otro dipo de controladores como daemonsets:
```
kubectl get --namespace kube-system daemonset
```

Tenemos tantos pods en el daemonset como nodos.
```
kubectl get nodes
```

## Deployments
Ya hemos deseplegado algunos deployments anteriormente, vamos a ver el proceso con detalle. Para crear un deployment de forma imperativa con un solo pod y luego escalarlo a 5 replicas ejecutaríamos:
```
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kubectl scale deployment hello-world --replicas=5
```

Veremos el estado de nuestro deployment con:
```
kubectl get deployment
```

Eliminaremos el deployment
```
kubectl delete deployment hello-world
```

Para hacerlo de forma declarativa primero necesitamos el manifiesto. Usaremos el mismo comando que antes pero en este caso haremos un dry-run para guardar la salida en un yaml.
```
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0 --dry-run=client -o yaml > deployment.yaml
```

Ediatmos el manifiesto e incrementamos las réplicas a 5. Ya con el manifiesto podemos aplicarlo para desplegar el deployment de forma declarativa:
```
kubectl apply -f deployment.yaml
```

Podemos ver si se ha creado correctamente:
```
kubectl get deployment hello-world
```

Cada deployment está asociado a un replica set:
```
kubectl get replicasets
```
Si vemos los pods que tenemos asociados al replica set, podremos identificarlos porque tienen el id del replica set como parte del nombre:
```
kubectl get pod
```

También podemos verlo en la propiedad `Controlled by` en la descripción del pod:

```
kubectl describe pods | grep Controlled
```

Si nos fijamos en los eventos del deployment, veremos en la columna from, que el deployment-controller es el responsable de mantener el estado deseado del deployment.
```
kubectl describe deployment
```

## Replica Sets

Vamos a analizar el replicaset que gstiona el deployment hello-world:
```
kubectl describe replicaset hello-world
```
Como vemos los labels seleccionan que pods forman parte de él.

Si borramos el deployment, se borrará también el replica set:
```
kubectl delete deployment hello-world
kubectl get replicaset
```

Vamos a desplegar un deployment con matchExpressions:
```
kubectl apply -f deployment-me.yaml
```

Verificaremos el estado de nuestro replicaset:
```
kubectl get replicaset
```

En este caso los selectores del pod template serán diferentes:
```
kubectl describe replicaset hello-world
```

La función principal de un replica set es la de mantener el número de pods especificado en la definición. Si borramos un pod, automáticamente se creará uno nuevo:
```
kubectl get pods
kubectl delete pod hello-world-XXXXXX-YYYY
kubectl get pods
```

Como vimos podemos editar los labels para "sacar" a un pod del replica set:
```
kubectl get pod --show-labels
kubectl label pod hello-world-XXXXXX-YYYY app=DEBUG --overwrite
kubectl get pod --show-labels
```

Si devolvemos el label a su valor original, ¿qué pasará?
```
kubectl label pod hello-world-XXXXXX-YYYY app=hello-world-pod-me --overwrite
kubectl get pod --show-labels
```

Un pod se eliminará, dejando manteniendo el estado deseado.

### Fallo de un nodo
Vamos a simular el fallo en uno de los nodos. Lo apagaremos y veremos que kubernetes tarda alrededor de un minuto en detectar el fallo:
```
ssh node3
sudo shutdown -h now
kubectl get nodes --watch
```

Si sacamos el listado de pods, es posible que alguno quede en ese nodo. Kubernetes se protege ante fallos transitorios y no lo dará por fallo hasta pasado un tiempo.
```
kubectl get pods -o wide
```

Arrancamos el nodo3 y vemos el estado de los nodos, ese pod detectará que no está corriendo y se arrancará otro en su lugar:
```
kubectl get nodes -o wide --watch
```

Si apagamos el nodo y esperamos mas tiempo, unos 5 minutos, el pod se marcará como huerfano y se arrancará en otro nodo:
```
ssh node3
sudo shutdown -h now
kubectl get pods -o wide --watch
```

