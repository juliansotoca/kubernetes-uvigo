# Instalación de cluster
## IaaS en Linode
Despliegue de la infra
```
cd kubernetes_linode_terraform
terraform init
terraform plan
terraform apply
```

Instalación del cluster
```
ansible-playbook -i inventory k8s.yml -l k8s_master
ansible-playbook -i inventory k8s.yml -l k8s_workers
```

## Minikube
https://minikube.sigs.k8s.io/docs/start/

## Kops
https://kubernetes.io/docs/setup/production-environment/tools/kops/

## Kubespray
https://kubernetes.io/docs/setup/production-environment/tools/kubespray/

## AKS con Terraform

# Primeros pasos kubectl
https://kubernetes.io/docs/reference/kubectl/cheatsheet/

Nos logueamos en la áquina que ejecuta el Control Plane (master)


##Setup del autocomplete y alias
```
echo $SHELL
```
https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete

## Obtener información del cluster, nodos, pods, servicios, etc
```
kubectl cluster-info
```

### Obtener información de los Nodos
```
kubectl get nodes
```

### Obtener información extendida de los nodos
```
kubectl get nodes -o wide
```

### Lista de Pods en el namespace por defecto
```
kubectl get pods
```

### Lista de pods en el namespace kube-system
```
kubectl get pods --namespace kube-system
```

### Obtener información extendida de los pods en el namespace kube-system
```
kubectl get pods --namespace kube-system -o wide
```

### Obtener una lista de todo en todos los namespaces
```
kubectl get all --all-namespaces | more
kubectl get all -A | more
```

### Obtener una lista de todos los recursos que conoce
```
kubectl api-resources | head -n 10
```
Podremos ver el tipo de recurso, su nombre y su abreviatura, la versión de la API y si está asociado a un Namespace o no

Filtramos por ejemplo los que contengan Pod en su nombre:
```
kubectl api-resources | grep pod
```

Con Explain podremos obtener información detallada de cada tipo de recurso:
```
kubectl explain pod | more
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more
kubectl explain pod --recursive
```

Con describe obtendemos información detallada de cada recurso:
```
kubectl describe nodes master
kubectl describe nodes nodo
```

### Obtención de ayuda
```
kubectl -h | more
kubectl get -h | more
kubectl describe -h | more
```

## Desplegando aplicaciones
Vamos a trabajar con la imagen traefik/whoami que nos devuelve información relativa al pod donde está corriendo ademas de información del cliente.
Para crear un despliegue:
```
kubectl create deployment whoami --image=traefik/whoami
```

Si solo quisieramos desplegar un solo pod:
```
kubectl run whoami-pod --image=traefik/whoami
```

Verificaremos el estado de nuestros pods y despliegue:
```
kubectl get pods
kubectl get deployment
kubectl get pods -o wide
```

Vamos a conectarnos con un segundo terminal al worker y verificaremos que los pods se están ejecuntando como contenedores ahí:
```
ssh worker01
sudo docker ps
exit
```

Por defecto los contenedores loguean todo lo que la aplicación escribe en el stdout. Para obtener los logs de cualquier pod podemos ejecutar:
```
kubectl logs whoami-pod
```

### Acceso a un Pod
Podemos acceder a la shell de un pod (siempre y cuando tenga una shell instalada). En este caso utilizaremos la imagen de nginx que se basa en Debian y tiene bash instalado:

```
kubectl run nginx-pod --image=nginx
kubectl get pods nginx-pod -o wide
kubectl exec --stdin --tty nginx-pod -- /bin/bash
```
Una vez dentro podremos ejecutar cualquier comando que este disponible o incluso instalar software:
```
hostname
id
ls /
apt-get update
apt-get install iproute2
ip a
exit
```
## Obtener información detallada de un despliegue:
```
kubectl describe deployment whoami | more
```

### Acceso a la aplicación
Para poder acceder a la aplicación debemos exponerla. Para ello con el comando expose nos creará lo necesario para poder conectarnos a ella desde el exterior del cluster:
```
kubectl expose deployment whoami --port=80 --target-port=8080
```
Vamos a obtener infomraicón del servicio que ha creado:
```
kubectl get service whoami
kubectl describe service whoami
```

Ahora podremos acceder con curl a nuestra aplicación
```
curl http://${SERVICEIP}:${PORT}
```

También podemos acceder directamente a la aplicación en el pod, para ello verificamos el endpoint donde está publicado:
```
kubectl get endpoint whoami
curl http://${ENDPOINT}:${TARGETPORT}
```

> [!WARNING] Si usamos minikube debemos exponerlo con el tipo NodePort y luego abrir el tunel a minikube
> ```kubectl expose deployment whoami --type=NodePort --port=80
> minikube service whoami
> ```

## Podemos pedirle a la API mas información sobre el objeto service
```
kubectl explain service | more
```

### Investigando sobre los detalles podemos ver una explicación de lo que está disponible para este recurso
```
kubectl explain service.spec | more
kubectl explain service.spec.ports
kubectl explain service.spec.ports.targetPort
```

## Borrado de los recursos de modo imperativo
```
kubectl delete service whoami
kubectl delete deployment whoami
kubectl delete pod whoami-pod
kubectl delete pod nginx-pod
kubectl get all
```

## Despliegue declarativo
Para el despliegue declarativo deberemos crear el manifiesto, lo podemos obtener simulando un despliegue:
```
kubectl create deployment whoami --image=traefik/whoami --dry-run=client -o yaml > deployment-whoami.yml
```

Para desplegar el deployment ejecutaremos:
```
kubectl apply -f deployment-whoami.yml
```

De forma similar para el servicio:
```
kubectl expose deployment whoami --port=80 --target-port=8080 --dry-run=client -o yaml > service-deployment-whoami.yml
kubectl apply -f service-deployment-whoami.yml
```

Esto crea todos los recusos necesarios para poder acceder a nuestra aplicación desde fuera del cluster.
### Escalar un deplotment
Editaremos el fichero `deployment-whoami.yml` y cambiaremos las replicas de 1 a 2. Aplicaremos de nuevo el mismo fichero:
```
kubectl apply -f deployment-whoami.yml
```
Podemos verificar que es lo que nos ha creado
```
kubectl get deployment whoami
```

Repetiremos el curl contra la IP del servicio y veremos que cada vez nos devuelve la información de un Pod diferente.

```
kubectl get service whoami
kubectl get endpoint whoami
curl http://${SERVICEIP}:${PORT}
```

Podemos editar deployments que estén corriendo en ese momento con kubectl edit. Esto no se reflejará en el fichero yml pero si que será persistente en el cluster (usar con precaución). Podemos cambiar el número de replicas a 3 en este momento:
```
kubectl edit deployment whoami
```
```
kubectl get deployment whoami
kubectl get pods
```

Para eliminar los recursos
```
kubectl delete -f deployment-whoami.yml
kubectl delete -f service-deployment-whoami.yml
kubectl get all
```