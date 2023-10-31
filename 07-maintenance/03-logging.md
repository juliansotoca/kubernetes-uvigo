# Logging
## Pods

Verificar los logs de un pod con un contenedor
```
kubectl create deployment nginx --image=nginx
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME
kubectl logs $PODNAME
```

Eliminamos el deployment
```
kubectl delete deployment nginx
```

Vamos a crear un pod multicontenedor que va a ir escribiendo contínuamente en los logs:
```
kubectl apply -f multicontainer-pod.yaml
```



Vamos a obtener los logs de un pod en concreto:
```
PODNAME=$(kubectl get pods -l app=loggingdemo -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME
```

Pod fecto nos mostrará los logs del primer contenedor:
```
kubectl logs $PODNAME
```

Podemos especificar sobre qué contenedor queremos obtener los logs:
```
kubectl logs $PODNAME -c container1
kubectl logs $PODNAME -c container2
```


Podemos acceder a los logs de todos los contenedores:
```
kubectl logs $PODNAME --all-containers
```

Podemos seguir los logs de uno o todos los contenedores con `--follow`:
```
kubectl logs $PODNAME --all-containers --follow
ctrl+c
```

También podemos obtener los logs de todos los pods y de todos los contenedores filtando por un determinado label:
```
kubectl get pods --selector app=loggingdemo
kubectl logs --selector app=loggingdemo --all-containers
kubectl logs --selector app=loggingdemo --all-containers  > allpods.txt
```

Finalmente podemos añadir un `--tail` para obtener las últimas líneas de los logs:
```
kubectl logs --selector app=loggingdemo --all-containers --tail 5
```


## Nodos
Podemos obtener información sobre el servicio de kubelet, asegurarnos de que está activo y corriendo y verificar sus logs.
```
systemctl status kubelet.service
```

Si queremos ver los logs del servicio, podemos usar journalctl con `-u` para indicar la unidad de systemd.
```
journalctl -u kubelet.service
```
Con Journalctl podemos buscar por errores o algún otro patrón:
```
journalctl -u kubelet.service | grep -i ERROR
```

También podemos acotar la búsqueda en el tiempo, por ejemplo:
```
journalctl -u kubelet.service --since today --no-pager
```

## Plano de control
Podemos listar los pods del plano de control usando un selector:
```
kubectl get pods --namespace kube-system --selector tier=control-plane
```

Podemos obtener los logs de los pods del plano de control usando kubectl:
```
kubectl logs --namespace kube-system kube-apiserver-node1
```

Si el plano de control está caido tendremos que ir a mas bajo nivel para saber que está pasando. Por ejemplo con docker:
```
CONTAINER_ID=$(docker ps | grep k8s_kube-apiserver | awk '{ print $1 }')
echo $CONTAINER_ID
docker logs $CONTAINER_ID
```

Si docker no está disponible, deberíamos ver los logs del contenedor en `/var/log/containers`:
```
ls /var/log/containers
tail /var/log/containers/kube-apiserver-c1-master1*
```




## Eventos
En los eventos se registra toda la actividad del cluster, como creación de objetos, escalado de deployments, etc:
```
kubectl get events
```

Se puede ordenar la salida por tiempo:
```
kubectl get events --sort-by='.metadata.creationTimestamp'
```

(la opción de ordenado `--sort-by` se puede usar en otro tipo de comandos)

Vamos a crear un deployment con una imagen que no existe:
```
kubectl create deployment nginx --image nginps
```

Podemos filtrar los eventos con el selector de campo, incluso filtros con varios campos:
```
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Warning,reason=Failed
```

Podemos monitorizar los evetos a medida que suceden:
```
kubectl get events --watch &
kubectl scale deployment loggingdemo --replicas=5
fg
ctrl+c
```
