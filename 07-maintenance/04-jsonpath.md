# JSONPath
## Obtener información
Vamos a crear un deployment y escalarlo:
```
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kubectl scale  deployment hello-world --replicas=3
kubectl get pods -l app=hello-world
```

Con la salida en formato json podemos ver todos los detalles de un objeto:
```
kubectl get pods -l app=hello-world -o json > pods.json
```

Dentro de items tenemos una lista de objetos, en este caso pods. Con JSONPath odremos obtener únicamente uno de los campos:
```
kubectl get pods -l app=hello-world -o jsonpath='{ .items[*].metadata.name }'
```

Como vemos, la salida es todo en una línea. Podemos añadir un salto de línea al final para mejorar la legibilidad:
```
kubectl get pods -l app=hello-world -o jsonpath='{ .items[*].metadata.name }{"\n"}'
```
Se pueden añadir otras opciones de formato, como salto de línea despues de cada objeto. Mas adelante se indica cómo hacerlo.

Al ser una lista de objetos, podemos obtener la información de uno en concreto indicando el índice del mismo:
```
kubectl get pods -l app=hello-world -o jsonpath='{ .items[0].metadata.name }{"\n"}'
```

Para obtener las imágenes usadas por todos los objetos:
```
kubectl get pods --all-namespaces -o jsonpath='{ .items[*].spec.containers[*].image }{"\n"}'
```

## Filtros
Podemos filtrr por un valor específico en la lista. Por ejemplo, si tenemos una lista dentro de items y queremos acceder a un elemento de la lista:

* `?()` - Define un filtro
* `@` - El objeto actual

```
kubectl get nodes node1 -o json | more
kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}"
```

## Ordenación

Podemos usar `--sort-by` para definir sobre qué campo queremos ordenar la salida.
```
kubectl get pods -A -o jsonpath='{ .items[*].metadata.name }{"\n"}' --sort-by=.metadata.name
```
Ahora que podemos ordenar la salida, es posible ordenar un listado y ordenarlo por un campo que no es parte de la salida por defecto de kubectl, por ejemplo creationTimestamp. Podríamos lanzar el siguiente comando para añadir ese campo a nuestra salida:
```
kubectl get pods -A -o jsonpath='{ .items[*].metadata.name }{"\n"}' \
    --sort-by=.metadata.creationTimestamp \
    --output=custom-columns='NAME:metadata.name,CREATIONTIMESTAMP:metadata.creationTimestamp'
```

## Range

El operador range nos permite iterar por cada uno de los objetos de una lista. Util si queremos añadir un salto de línea tras cada objeto:
```
kubectl get pods -l app=hello-world -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

Podemos realizar ciertas combinaciones para obtener la información que deseamos:
```
kubectl get pods -l app=hello-world -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[*].image}{"\n"}{end}'
```

Podríamos añadir ademas sobre qué campo ordenar:
```
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' \
    --sort-by=".spec.containers[*].image"
```

Podemos usar range para tener una salida mas limpia:
```
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="Hostname")].address}{"\n"}{end}'
```



Podemos añadir espacios o tabuladores para hacer una salida mas legible:
```
kubectl get pods -l app=hello-world -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[*].image}{"\n"}{end}'
kubectl get pods -l app=hello-world -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

Podemos eliminar el deployment
```
kubectl delete deployment hello-world
```