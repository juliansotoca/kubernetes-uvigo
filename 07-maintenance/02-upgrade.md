# Actualización de kubernetes
Se recomienda solo actualizar de una minor version a la siguiente. Siempre es recomendable leer antes las notas de actualización.

En las últimas notas se indica que hay que utilizar un nuevo repositorio de software: https://v1-27.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/

Una vez hemos actualizado el repositorio, para ver qué versión tenemos disponible podemos ejecutar:

```
apt update
apt-cache policy kubeadm
```
Confirmaremos en qué versión está nuestro cluster actualmente:
```
kubectl version --short
kubectl get nodes
```

Primero actualizaremos el kubeadm en el master. Reemplazamos por la versión a la que queramos actualizar:

```
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm=1.26.5-00
apt-mark hold kubeadm
```
Verificamos si kubeadm se ha actualizado
```
kubeadm version
```
A continuación vamos a mover los pods del master node:
```
kubectl drain master --ignore-daemonsets
```

Vamos a lanzar el upgrade plan, para verificar que la actualización se puede llevar a cabo.
```
kubeadm upgrade plan
```

Si todo es correcto lanzamos la actualización. Para cada componente se descarga un nuevo manifiesto estático y guarda los antiguos en `/etc/kubernetes/tmp`. Esto hará que el kubelet reinicie los pods del plano de control.

```
kubeadm upgrade apply v1.26.5
```

Cuando termine nos dará un mensaje de que ha finalizado correctamente.

Ya podemos habilitar de nuevo el nodo con `uncordon`:
```
kubectl uncordon master
```
Ahora ya podemos actualizar kubelet y kubectl en el master:
```
apt-mark unhold kubelet kubectl
apt-get update
apt-get install -y kubelet=1.26.5-00 kubectl=1.26.5-00
apt-mark hold kubelet kubectl
```

Verificamos que se ha actualizado
```
kubectl version --short
kubectl get nodes
```

A continuación ya podemos actualizar los nodos. Hay que repetir el mismo procedimiento en todos los nodos uno a uno. Primero evacuaremos los pods que estan corriendo en cada nodo y nos conectaremos a él por ssh:
```
kubectl drain node1 --ignore-daemonsets
ssh node1
```

Primero actualizaremos kubeadm
```
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm=1.26.5-00
apt-mark hold kubeadm
```

Y a continuación actualizamos el nodo:
```
kubeadm upgrade node
```

Por último actualizamos el kubelet
```
sudo apt-mark unhold kubelet
sudo apt-get update
sudo apt-get install -y kubelet=1.26.5-00
sudo apt-mark hold kubelet
```


Una vez finalizado podemos verificar si se ha actualiado el nodo correctamente:
```
kubectl get nodes
```

Si está todo correcto habilitamos de nuevo el nodo:
```
kubectl uncordon c1-node[XX]
```

