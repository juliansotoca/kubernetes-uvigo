# Scheduler

Vamos a crear un deployment con 3 réplicas:
```
kubectl apply -f deployment.yaml
```

Los pods se habrán ido asignando en los diferentes nodos del cluster:
```
kubectl get pods -o wide
```

Podemos ver en los eventos del pod ver al scheduler tomas sus decisiones sobre el nodo asignado:
```
kubectl describe pods
```

Si escalamos el deployment los pods se irán asignando de uniformemente:
```
kubectl scale deployment hello-world --replicas=6
kubectl get pods -o wide
```

En los detalles del pod podemos ver en que nodo se han asignado:
```
kubectl get pod hello-world-XXXXXX-YYYY -o yaml | grep nodeName
```

Eliminaremos el deployment:
```
kubectl delete -f deployment.yaml
```

A continuación vamos a crear un deploy donde los pods van a tener unos recursos de CPU asignado. Antes dejaremos en background un watch de los pods para ver los que se van creando:
```
kubectl get pods --watch &
kubectl apply -f deployment-requests.yaml
```
Podemos ver donde se han ido asignando los pods:
```
kubectl get pods -o wide
```

Vamos a escalar el deployment:
```
kubectl scale deployment hello-world-cpu --replicas=6
```

Como vemos, algunos se han quedado en estado pending:
```
kubectl get pods -o wide
```

Vamos a analizar alguno de los que se han quedado en pending:
```
kubectl describe pod hello-world-cpu-86c65dcb9c-hnnpg
```

En los enventos vemos la razón de porqué no se ha podido asingar a ningún nodo. Podemos ver en la descripción de un nodo cuantos recursos tiene asignados en cada momento:
```
 kubectl describe node node1
```

Borramos el deployment y paramos el watch:
```
kubectl delete deployments.apps hello-world-cpu
fg
ctrl+c
```