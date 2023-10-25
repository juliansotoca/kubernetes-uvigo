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

## Afinidad y antiafinidad
Vamos a desplegar una aplicación donde vamos a establecer una afinidad entre los servidores web y los nodos de cache:
```
kubectl apply -f deployment-affinity.yaml
```

Vamos a analizar los labels que tienen nuestros nodos, especialmente el `kubernetes.io/hostname`
```
kubectl describe nodes node1
kubectl get nodes --show-labels
```

Si escalamos el deploy los pods se repartiran uniformemente por el cluster:
```
kubectl scale deployment hello-world-web --replicas=2
kubectl get pods -o wide
```

si escalamos los de cache se asignaran al mismo nodo que los de web:
```
kubectl scale deployment hello-world-cache --replicas=2
kubectl get pods -o wide
```

finalmente podemos borrar el deployment:
```
kubectl delete -f deployment-affinity.yaml
```

Vamos a hacer lo mismo, en este caso con antiafinidad:
```
kubectl apply -f deployment-antiaffinity.yaml
```
Escalaremos el deployment a 4 replicas:
```
kubectl scale deployment hello-world-web --replicas=4
```

Vemos que se han creado 4 pods para el deployment web pero tenemos 2 pending porque por la regla de antiafinidad no se puede asignar a ningún nodo. Vamos a modificar la regla del deployment a preferredDuringSchedulingIgnoredDuringExecution y volveremos a escalar a 4 nodos:
```
kubectl apply -f deployment-antiaffinity-fix.yaml
kubectl scale deployment hello-world-web --replicas=4
kubectl get pods -o wide
```

Vemos que ahora si se han asignado todos los pods. Si tuviesemos mas nodos se habían asignado a otros, pero en este caso al menos se han asignado.

Podemos limpiar los deployments:
```
kubectl delete deployments.apps hello-world-web
kubectl delete deployments.apps hello-world-cache
```

## Taints y tolerations
Vamos a añadir un taint al nodo2:
```
kubectl taint nodes node2 key=MyTaint:NoSchedule
```

Podemos ver en la descripción del nodo que tiene una restricción en la seccion de Taints:
```
kubectl describe node node2
```

Vamos a crear un deployment con 3 replicas
```
kubectl apply -f deployment.yaml
```

como vemos, los pods se han asignado a nodos node no está la restricción:
```
kubectl get pods -o wide
```

Vamos a añadir un deployment con tolerations:
```
kubectl apply -f deployment-tolerations.yaml
```

En este caso los pods se habrán asignado a todos los nodos, incluso el node2:
```
kubectl get pods -o wide
```

Para eliminar el taint del nodo:
```
kubectl taint nodes node2 key=MyTaint:NoSchedule-
kubectl describe node node2 | grep -i taint
```

Podemos eliminar los deployments:
```
kubectl delete -f deployment-tolerations.yaml
kubectl delete -f deployment.yaml
```

## Cordoning
Vamos a desplegar de nuevo el deployment con 3 replicas:
```
kubectl apply -f deployment.yaml
```
Los pods se habrán asignado en todos los nodos:
```
kubectl get pods -o wide
```
Vamos a poner en mantenimiento el nodo3 con cordon:
```
kubectl cordon node3
```

Esto no movera los pods a otro nodo,
```
kubectl get pods -o wide
```
pero si escalamos el deployment no permitirá la asignación de nuevas réplcias del pod a este nodo:
```
kubectl scale deployment hello-world --replicas=6
kubectl get pods -o wide
```

Si el nodo que está "cordon" le ejecutamos un "drain" si que moverá los pods a otro nodo:
```
kubectl drain node3
```

Esto nos dará un error porque tenemos daemonsets corriendo en ese nodo. Deberemos ejecutar el drain ignorándo los daemonsets ya que no se pueden asignar a otros nodos:
```
kubectl drain node3 --ignore-daemonsets
```

Como vemos, ahora ese nodo ya no tendrá pods asignados:
```
kubectl get pods -o wide
```

Para eliminar el nodo de mantenimiento deberemos ejecutar el `uncordon`
```
kubectl uncordon node3
```

No se asignarán pods existentes a este nodo:
```
kubectl get pods -o wide
```

Pero si los nuevos que se vayan creando:
```
kubectl scale deployment hello-world --replicas=9
kubectl get pods -o wide
```

Borraremos el deployment:
```
kubectl delete deployment hello-world
```

## Asignación manual
La última opción que vamos a ver a la hora de modificar el comportamiento del scheduler es la asignación manual. Vamos a desplegar un pod donde especificamos el nodeName en su manifiesto:
```
kubectl apply -f pod.yaml
```
Vemos que se ha asignado al nodo que habíamos especificado:
```
kubectl get pod -o wide
```

Vamos a eliminar el pod, como no hay un controlador por encima, no se va a recrear:
```
kubectl delete pod hello-world-pod
```

Vamos aejecutar un cordon en el nodo2 y recrear el pod:
```
kubectl cordon node2
kubectl apply -f pod.yaml
```

Al haber hecho una asignación manual, sobre este nodo no podremos ejecutar un drain:
```
kubectl drain node2 --ignore-daemonsets
```

Borraremos el pod y ejecutaremos el uncordon del nodo2:
```
kubectl delete pod hello-world-pod
kubectl uncordon node2
```