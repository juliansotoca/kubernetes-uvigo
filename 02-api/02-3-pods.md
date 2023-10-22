# Ejecutando y gestionando Pods

## Eventos al desplegar pods
Vamos a dejar lanzado en background un get events, para ver que va pasando en nuestro cluster en tiempo real:
```
kubectl get events --watch &
```

Vamos a crear un pod y veremos los eventos que se generan (scheduled, pulled, created, started)
```
kubectl apply -f pod.yaml
```

Repetiremos con un deployment de 1 réplica
```
kubectl apply -f deployment-nginx-single.yaml
```
Aqui vems como se crea el deployment, el replica set, como se escala y finalmente los mismos eventos que con el pod. A continuación escalamos el deployment:
```
kubectl scale deployment nginx --replicas=2
```
Vamos a devolverlo a su estado original:
```
kubectl scale deployment nginx --replicas=1
kubectl get pods
```

Finalmente podemos conectarnos al pod, veremos las peticiones a la api que se hacen para establecer la sesión:
```
kubectl -v 6 exec -it nginx-xxxx-xxx -- /bin/sh
ls
exit
```

Vamos a conectarnos por ssh a alguno de los workers y ver desde el punto de vista del sistema operativo cómo se ven. Primero obtendremos el nombre del nodo donde se ejecuta el pod y a continuación nos conectamos al nodo:
```
kubectl get pods -o wide
ssh nodo2 // minikube ssh
ps aux | grep nginx
docker ps
exit
```

Nuestro pod esta escuchando en el puerto 80, podemos lanzar el comando port-forward para conectarnos a este puerto:
```
kubectl port-forward nginx-xxxx-xxx  80:80
```

Esto nos fallará al ser un puerto privilegiado, Vamos a hacerlo de nuevo, pero con el puerto 8080.
```
kubectl port-forward nginx-xxxx-xxx  8080:80
```

Ahora podemos hacer un curl al puerto 8080 y se redirigirá al puerto 80 del pod:
```
curl http://localhost:808
```

Para cerrar el port forwarding:
```
fg
ctrl+c
```

Limpiamos los recuros:
```
kubectl delete -f pod.yaml
kubectl delete -f deployment-nginx-single.yaml
```

y matamos el kubectl get events
```
fg
ctrl+c
```

## Pods Multicontainer

Vamos a desplegar un Pod con varios contenedores:
```
kubectl apply -f multicontainer-pod.yaml
```

Nos conectaremos al pod, sin especificar un nombre. Por defecto se conectará al primero contenedor del manifiesto:
```
kubectl exec -it multicontainer-pod -- /bin/sh
ls -la /var/log
tail /var/log/index.html
exit
```

A continuación nos conectaremos a un container específico:
```
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh
ls -la /usr/share/nginx/html
tail /usr/share/nginx/html/index.html
exit
```

Vamos a hacer un port forwarding para conectarnos al puerto 80 de nuestro pod y lanzaremos el curl:
```
kubectl port-forward multicontainer-pod 8080:80 &
curl http://localhost:8080
```

Recuperamos el control del port forward y lo matamos, finalmente borramos el pod:
```
fg
ctrl+c
kubectl delete -f multicontainer-pod.yaml
```

## Ciclo de vida de los pods

Arrancaremos de nuevo el kubectl get events para ver lo que está pasando en el cluster a medida que desplegamos pods:
```
kubectl get events --watch &
```

Crearemos un pod y veremos los eventos que se generan en su arranque:
```
kubectl apply -f nginxpod.yaml
```

Vamos a abrir una sheel y ejecutar cualquier programa dentro del contenedor. Vamos a instalar el paquete procps para poder lanzar el comando pkill y mataremos el proceso de nginx:
```
k exec -it nginx-pod -- /bin/bash
apt update && apt install -y procps
pkill nginx
```

Veremos que el container se ha reiniciado, en el contador de reinicios se ha incrementado:
```
kubectl get pod
```

Si vemos el detalle del Pod podemos ver el estado y el último estado, así como el código de salida y la fecha de terminación:
```
kubectl describe pod nginx-pod
```

Limpiamos los recursos creados:
```
fg
ctrl+c
kubectl delete -f nginxpod.yaml
```

### Cambio de la restart policy
Con explain podemos ver las opciones que tenemos para la definición de objetos. Vamos a ver lo que nos devuelve sobre la restartPolicy
```
kubectl explain pods.spec.restartPolicy
```

Vamos a crear unos pods con diferentes restart policies:
```
kubectl apply -f restart-policy-pod.yaml
```
El comando que lanza el pod tiene como código de salida 1, por tanto, kubernetes interpretará que ha terminado con error.

Verificamos que los pods se han creado correctamente y que el contador de reinicios es 0
```
kubectl get pod --watch
```

Pero tras unos segundos pasarán a error

El pod con restart policy a never no se reiniciará, el contador de reinicios permanecerá en 0. El otro pod se irá reiniciando aumentando cada ved mas el tiempo entre reinicios.
Podemos ver los detalles de ambos pods:
```
kubectl describe pod busybox-never-pod
kubectl describe pod busybox-onfailure-pod
```

Finalmente borramos los pods:
```
kubectl delete -f restart-policy-pod.yaml
```

## Probes
Arrancaremos de nuevo el kubectl get events para ver lo que está pasando en el cluster a medida que desplegamos pods:
```
kubectl get events --watch &
```

Vamos a desplegar un pod con sondas configuradas:
```
kubectl apply -f container-probes.yaml
```

Vemos en los eventos que tras 10 segundos las sondas fallan. La Liveness matará el contenedor y recreará uno nuevo. Si listamos los pods vemos que ninguno está ready (0/1) y que el cntador de reinicios va aumentando.

Vamos a ver que está mal en los pods:
```
kubectl describe pods
```

Editamos el manifiesto y corregimos el puerto de las sondas. Aplicaremos de nuevo el manifiesto y se actualizarán:
```
vi container-probes.yaml
kubectl apply -f container-probes.yaml
```

Confirmamos que los pods arrancan ahora sin problema:
```
kubectl get pods
```

Eliminamos el deployment una vez confirmado que funciona:
```
kubectl delete -f container-probes.yaml
```