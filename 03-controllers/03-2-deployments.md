# Deployments
## Actualización de un deployment

Vamos a desplegar el deployment del ejercicio anterior y le aplicaremos una actualización:
```
kubectl apply -f deployment.yaml
```

Este deployment utiliza una imagen nueva de nuestro contenedor y despleiga mas réplicas:
```
kubectl apply -f deployment.v2.yaml
```

Podemos ver el estado de nuestro update con:
```
kubectl rollout status deployment hello-world
echo $?
kubectl get deployments.apps
```

La salida `0` nos indicará que el rollout se ha completado.

Vamos a analizar la descripción del deployment:
```
kubectl describe deployment hello-world
```
Ahí veremos que tenemos 2 campos de OldReplicaSets y NewReplicaSet donde veremos que se ha desplegado uno nuevo. En los eventos también veremos todo lo que se ha ido haciendo. En anotations veremos en que revisión estamos del deployment.

Los replicasets viejos se matnienen por si hay que hacer rollback:
```
kubectl get replicaset
```

Analicemos los replicasets que que tenemos:
```
kubectl describe replicaset hello-world-new
kubectl describe replicaset hello-world-old
```

Vamos a desplegar ahora una nueva versión, donde en la especificación le hemos indicado una imagen que no existe:
```
kubectl apply -f deployment.v3.yaml
```
observamos el comportamiento al no encontrar la nueva imagen:
```
kubectl rollout status deployment hello-world
echo $?
```

Tendremos 5 pods en estado ImagePullBackOff y el rollot se paró en 5. Se han quedado corriendo 8 pods en el deploy:
```
kubectl get pods
kubectl get deploy
kubectl describe deployments hello-world
```

Para solucionar el problema deberíamos hacer rollback del despliegue. vemos el historial:
```
kubectl rollout history deployment hello-world
```
En la descripción del deployment podemos ver en qué revisión estamos acutalmente
```
kubectl describe deployments hello-world | grep Annotati
```

Podemos ver también el detalle de los cambios en cada revision:
```
kubectl rollout history deployment hello-world --revision=4
kubectl rollout history deployment hello-world --revision=5
```

Para hacer el rollback ejecutaremos el `rollout undo` especificando la revisión a la que queremos ir:
```
kubectl rollout undo deployment hello-world --to-revision=4
kubectl rollout status deployment hello-world
echo $?
```

Si listamos los pods, vemos que ahora tenemos corriendo los 10 que habíamos especificado:

```
kubectl get pods
kubectl get deploy
```

Podemos eliminar el deployment:
```
kubectl delete deployment hello-world
```

## Deployment con sondas
Vamos a realizar algunos deployments donde tengamos configuradas sondas readiness para detectar cuando nuestros pods están listos para ser usados.  Vamos a aplicar el primer manifiesto. Añadiremos una anotación para tener mas información en el historial:

```
kubectl apply -f deployment.probe1.yaml
kubectl annotate deployment hello-world kubernetes.io/change-cause="Initial release"
```
Vamos a analizar el objeto, todos los pods deberían estar corriendo correctamente:
```
kubectl describe deployment hello-world
```

Vamos a actualizar el deployment a la versión 2. En este caso la anotación está en el manifiesto:
```
kubectl apply -f deployment.probe2.yaml
```

Se desplegará un nuevo replica set y los pods se irán creando y elimnando si no hay problemas:
```
kubectl get replicaset
kubectl describe deployment hello-world
```

Actualizaremos con la tercera versión del deploy:
```
kubectl apply -f deployment.probe3.yaml
```
Vamos a ver cómo va el despliegue:
```
kubectl rollout status deployment hello-world
```
Veamos el estado del deployment:
```
kubectl get replicaset
kubectl describe deployment hello-world
```

Vemos que la actualización no avanza, por tanto, volveremos a una versión anterior. Vemos el historial, donde veremos las anotaciones que hemos ido añadiendo en los deployments:
```
kubectl rollout history deployment hello-world
```
Volvamos a la revisión 2:
```
kubectl rollout history deployment hello-world --revision=3
kubectl rollout history deployment hello-world --revision=2
kubectl rollout undo deployment hello-world --to-revision=2
```

Verifiquemos que estamos en un estado estable:
```
kubectl get deployment
kubectl describe deployment hello-world
```

Por último podemos borrar el despliegue:
```
kubectl delete deployment hello-world
```