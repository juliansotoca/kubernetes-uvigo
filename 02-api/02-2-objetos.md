# Gestión de Objetos

## Namespaces
Los objetos se organizan en namespaces. Para listarlos todos:
```
kubectl get namespaces
```

Ya vimos que algunos recusos se aplican a un namespace y otros no (son recursos de cluster):
```
kubectl api-resources --namespaced=true | head
kubectl api-resources --namespaced=false | head
```

Los namespaces tienen estado (Active y Terminating), podemos verlo en la descripción del mismo:
```
kubectl describe namespaces
```
Para obener cierto tipo de recurso en todos los namespaces podemos utilizar la opción `--all-namespaces` o `-A`:
```
kubectl get pods --all-namespaces
kubectl get pods -A
```

Podemos obtener todos los recursos de todos los namespaces con:
```
kubectl get all --all-namespaces
kubectl get all -A
```

También podemos solicitar recursos de un namespace específico y que no sea el que tengamos activo en ese momento:
```
kubectl get pods --namespace kube-system
```

Como todo en kubernetes, podemos crear los namespaces imperativamente o declarativamente:
```
kubectl create namespace playground1
kubectl apply -f namespace.yaml
```

Verificamos que se han creado los nuevos namespaces:
```
kubectl get namespaces
```

Vamos a arrancar un deployment en el namespace playground1:
```
kubectl apply -f deployment-namespace.yml
```

También crearemos algún recurso de manera imperativa:
```
kubectl run hello-world-pod --image=gcr.io/google-samples/hello-app:1.0 --namespace playground1
```

Si verificamos los pods que tenemos no vemos nada:

```
kubectl get pods
```

Debemos especificar el namespace:
```
kubectl get pods --namespace playground1
kubectl get pods -n playground1
```

Podemos listar todos los recursos de este nuevo namespace:
```
kubectl get all --namespace=playground1
```

Con el filtro de namespace podemos eliminar todos los recursos, por ejemplo los pods:
```
kubectl delete pods --all --namespace playground1
```

Al existir un deployment, este nos recreará los pods. En cualquier caso, podemos eliminar el namespace:
```
kubectl get all --namespace=playground1
```
Ahora si que veremos que no existe ningún recurso de los que había en `playground1`
```
kubectl get all
kubectl get all -A
```

## Labels

Vamos a crear una serie de pods con labels asignados a cada uno:
```
kubectl apply -f podLabels.yaml
```

Para ver los labels que tiene asignado cada pod ejecutamos con la opción `--show-labels`:
```
kubectl get pods --show-labels
```

Vamos a ver los detalles de uno de estos pods:
```
kubectl describe pod nginx-pod-1
```

Podemos hacer las peticiones filtrando por estos labels:
```
kubectl get pods --selector tier=prod
kubectl get pods --selector tier=qa
kubectl get pods -l tier=prod
kubectl get pods -l tier=prod --show-labels
```

Podemos utilizar varios labels en el filtro y hacer alguna expresión mas compleja:
```
kubectl get pods -l 'tier=prod,app=webapp' --show-labels
kubectl get pods -l 'tier=prod,app!=webapp' --show-labels
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'
```

También podemos modificar la salida de nuestro comando típico para añadir una columna con el valor de un determiando label:
```
kubectl get pods -L tier
kubectl get pods -L tier,app
```

### Modificando Labels
Para modificar un determinado label usaremos la opción `--overwirte`
```
kubectl label pod nginx-pod-1 tier=non-prod --overwrite
kubectl get pod nginx-pod-1 --show-labels
```
Para añadir un label usaremos `kubectl label`
```
kubectl label pod nginx-pod-1 another=Label
kubectl get pod nginx-pod-1 --show-labels
```
De la misma manera, para eliminarlo, especificaremos el label con el símbolo `-`
```
kubectl label pod nginx-pod-1 another-
kubectl get pod nginx-pod-1 --show-labels
```

Podremos modificar en una selección de pods un label en contreto:
```
kubectl get pod -L tier
kubectl label pod --all tier=non-prod --overwrite
kubectl get pod --show-labels
kubectl get pod -L tier
```

Y podemos utilizar esos selectores para eliminar todos los pods que cumplan la condición:
```
kubectl delete pod -l tier=non-prod
kubectl get pod -L tier
```

## Gestión de recursos

Vamos a desplegar un deployment junto con su servicio:
```
kubectl apply -f deployment-labels.yaml
```

Vamos a analizar los labels y selectores que tenemos en cada recurso:
```
kubectl describe deploy whoami-labels
kubectl describe rs whoami-labels
kubectl get pod --show-labels
```
Como vemos, los pods tienen un label que corresponde con el hash del template que se usa. Eso lo asigna el replica set.

Podemos editar este label para sacarlo del replica set y realizar tareas de debug, por ejemplo:
```
kubectl label pod <pod-name> pod-template-hash=DEBUG --overwrite
kubectl get pod --show-labels
```

Veremos que automáticamente ha creado un pod nuevo mientras que el otro se mantiene

Vamos a analizar ahora el servicio que hemos creado
```
kubectl get service
kubectl describe service whoami-labels
kubectl describe endpoints whoami-labels
```

podemos ver los labels y selectores que utilizan los servicios. Como el selector es únicamente por app el pod que hemos reetiquetado como DEBUG sigue en el balanceo.

Para eliminar este pod del balanceo deberemos actualizar el label de app:
```
kubectl get pod -o wide
kubectl get pod --show-labels
kubectl label pod <pod-name> app=DEBUG --overwrite
```

Volveremos a chequear el servicio y el endpoint y veremos que ya no forma parte del balanceo:
```
kubectl describe service whoami-labels
kubectl describe endpoints whoami-labels
```

## Asignación de un pod a un nodo
`Ejecutar en un entorno con mas de 1 workers`

Una de los usos mas prácticos de los labels esla de asignación de pods a nodos específicos. Vamos a ver los labels que tenemos asignados en nuestros nodos:
```
kubectl get nodes --show-labels
```
Vamos a asignar labels diferentes a dos de los nodos:
```
kubectl label node node2 disk=ssd
kubectl label node node3 hardware=gpu
```
Vamos  confirmar los labels que tenemos asignados:
```
kubectl get node -L disk,hardware
```

Vamos a desplegar algunos pods con la propiedad de NodeSelector:
```
kubectl apply -f nodeSelectorPod.yaml
```

Vamos a ver dónde se han desplegado dichos pods:
```
kubectl get node -L disk,hardware
kubectl get pods -o wide
```

Eliminamos los labels para no dejarlo como estaba inicialmente:
```
kubectl label node node2 disk-
kubectl label node node3 hardware-
```

Podemos eliminar los recursos:
```
kubectl delete -f nodeSelectorPod.yaml
```