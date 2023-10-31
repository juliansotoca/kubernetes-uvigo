# Ingress
## Ingress

## IngressRoute (traefik)
Basado en ejemplos de https://github.com/justmeandopensource/kubernetes.git

Instalaremos Helm si no lo tenemos ya instalado
```
brew install helm
```
Configuramos el repositorio de traefik
```
helm repo add traefik https://traefik.github.io/charts\n
helm repo list
helm search repo traefik
```

Instalaremos traefik en un nuevo namespace:
```
helm install traefik traefik/traefik -n traefik --create-namespace
```

Verificamos los pods que se han creado y los nuevos api resources:
```
k get pod -A
k api-resources | grep traefik
```

Podemos ver detalles de los valores por defecto con los que se isntala traefik:
```
helm list -n traefik
helm show values traefik/traefik
```

Expondremos el puerto 9000 que es por donde por defecto escucha la Dashboard:
```
kubectl -n traefik port-forward $(kubectl -n traefik get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

Crearemos un deployment con la imagen de nginx y lo exponemos en el puerto 80:
```
k apply -f nginx-deploy-main.yaml
k expose deployment nginx-deploy-main --port 80
```

Definiremos un ingressroute:
```
kubectl apply -f simple-ingress-routes/1-ingressroute.yaml
```