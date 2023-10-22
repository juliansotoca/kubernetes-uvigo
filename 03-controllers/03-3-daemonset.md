# Otros Controllers
## DaemonSet
Vamos a ver los daemon sets que ya existen en el cluster:
```
kubectl get nodes
kubectl get daemonsets --namespace kube-system kube-proxy
```

Vamos a crear un DaemonSet según el manifiesto:
```
kubectl apply -f daemonset.yaml
```

Tendremos tantos pods como nodos en nuestro cluster:
```
kubectl get daemonsets
kubectl get daemonsets -o wide
kubectl get pods -o wide
```

Veamos el detalle del deaemon set:
```
kubectl describe daemonsets hello-world
```

Cada pod se genera con varios labels: controller-revision-hash y pod-template-generation:
```
kubectl get pods --show-labels
```

Si cambiamos el label a uno de nuestros pods, tendremos un nuevo pod lanzado por el daemonset controller:
```
MYPOD=$(kubectl get pods -l app=hello-world | grep hello-world | head -n 1 | awk {'print $1'})
echo $MYPOD
kubectl label pods $MYPOD app=not-hello-world --overwrite
kubectl get pods --show-labels
```

Podemos eliminar los recursos:
```
kubectl delete daemonsets hello-world
kubectl delete pods $MYPOD
```

Podemos crear daemonsets con Node Selectors, para que únicamente se ejecuten en unos determinados nodos.

```
kubectl apply -f daemonset-ns.yaml
kubectl get daemonsets.apps
```

Como no tenemos ningún nodo con ese label, no se está asignando a ningún nodo. Vamos a añadir el label a alguno de los nodos:
```
kubectl label node node1 node=hello-app-ns
```

Veremos que una vez hemos añadido el label se ha desplegado un pod en ese nodo:
```
kubectl get daemonsets
kubectl get daemonsets -o wide
kubectl get pods -o wide
```

Si eliminamos el label el pod se terminará:
```
kubectl label node node1 node-
```

En los eventos del daemonset veremos que se ha destruido el pod, y que está en el estado deseado:
```
kubectl describe daemonsets.apps
```

Ya podemos eliminar este daemonset:
```
kubectl delete daemonsets hello-app
```

Por último, vamos a actualizar un daemon set. Vamos a desplegar el daemonset original y luego actualizaremos a la v2:
```
kubectl apply -f daemonset.yaml
kubectl get daemonsets
```
Antes de actualizar vemos cual es la estrategia de actualización:
```
kubectl get daemonsets.apps hello-app -o yaml | grep -i update -A 5
```

Aplicaremos la actualización, donde únicamente se cambia la versión de la imagen y veremos el rollout:
```
kubectl apply -f daemonset.v2.yaml && \
kubectl rollout status daemonsets hello-app
```

Podemos ver en los eventos cómo se han ido desplegando los pods:
```
kubectl describe daemonsets
```

Podemos ver como los labels controller-revision-hash y pod-template-generation se han actualizado
```
kubectl get pods --show-labels
```

Ya podemos eliminar este daemonset
```
kubectl delete daemonsets.apps hello-app
```


## Jobs
### Simple job
Vamos a desplegar un job definido en un manifiesto:
```
kubectl apply -f job.yaml
```

Podemos ver el estado del job y tendremos información de si ha terminado o no:
```
kubectl get job --watch
```

Podemos listar los pods y veremos que se ha completado:
```
kubectl get pod
```

Vamos a ver en los detalles del job. Podemos ver el estado de los pods, los eventos, la duración, hora de inicio,labels y selectors:
```
kubectl describe job pi
```

El pod tendrá un label por el que podremos filtrar todos los jobs con ese label:
```
kubectl get pod -l job-name=pi
```

Podemos ver también los logs generados por ese pod mientras no borremos el job:
```
kubectl logs pi-g87hw
```

Finalmente podemos eliminar el job y se eliminarán también los pods:

```
kubectl delete job pi
kubectl get pod
```


### Gestion de fallos
A continuación vamos a ver cómo se comportan los jobs al modificar la restartPolicy y hacer que estos fallen. Vamos a lanzar los jobs, con unos comandos que van a dar error.
```
kubectl apply -f job-failure-never.yaml
```

Vemos que el pod entra en un backoffloop despues de varios fallos (configurado en el manifiesto)
```
kubectl get pods --watch
```
Los pods no se borran, de forma que podemos analizar porqué no arrancan:
```
kubectl get pods
```
Tampoco se elimina el job y muestra como que no se ha podido completar:
```
kubectl get jobs
```

Veamos los eventos del job:
```
kubectl describe jobs
```

Si repetimos lo mismo con job-failure-onfailure.yaml vemos varias diferencias. El pod se reinicia hasta llegar al backofflimit. En caso de error se borra el pod y el job queda como no completado.

### Paralelismo
Otra de las opciones que nos permiten los jobs es lanzar los container con paralelismo. Para ello especificamos los parámetros completions y parallelism. Vamos a aplicar un job con estos parámetros:
```
kubectl apply -f job-parallelism.yaml
```

Veremos en este caso que se ejecutan los jobs de 3 en 3 hasta completar las 10 ejecuciones:
```
kubectl get pod --watch
kubectl get jobs
```

Borraremos este job:
```
kubectl delete job pi-parallel
```



## Cronjobs

Vamos a aplicar el manifiesto del cronjob. Muy similar al del job pero con una programación:
```
kubectl apply -f cronjob.yaml
```

Veamos si se ha creado correctamente:
```
kubectl get cronjobs
kubectl describe cronjobs
```
Veremos que según la programación que hemos configurado, cada minuto se ejecutará el job:
```
kubectl get pods --watch
```

El controlador cronjob se encarga de manejar jobs, por tanto, este creará objetos jobs (parecido a los deployments y replicasets):
```
kubectl get jobs
```

Los pods se quedarán hasta que se llegue al successfulJobsHistoryLimit:
```
kubectl get cronjobs.batch pi-cronjob -o yaml | grep successfulJobsHistoryLimit
```

Finalmente podremos borrar el cronjob:
```
kubectl delete cronjob pi-cronjob
```

Los pods se habrán borrado:
```
kubectl get pod
```