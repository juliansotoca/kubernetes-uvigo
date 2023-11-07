# Storage persistente

Nos conectamos a la máquina que funcionará como servidor NFS:
```
ssh root@nfs
```

Instalaremos el paquete `nfs-kernel-server` y crearemos unos directorios que luego compartiremos en kubernetes:
```
apt update && apt install -y nfs-kernel-server
mkdir -p /export/volumes/pod
```

Configuramos ese directorio en el fichero `/etc/exports` y reiniciamos el servicio para que detecte los camios
```
bash -c 'echo "/export/volumes *(rw,no_root_squash,no_subtree_check)" > /etc/exports'
cat /etc/exports
systemctl restart nfs-kernel-server.service
```

Salimos de ese nodo y nos conectamos a uno de los nodos de kubernetes:
```
ssh node1
```
Probaremos si la conexión NFS funciona montando el volumen en /mnt
```
mount -t nfs4 104.237.136.55:/export/volumes /mnt
```
Si funciona desmontamos el volumen:
```
umount /mnt
```

Vamos a definir el persistent volume en el cluster de kubernetes:
```
kubectl apply -f nfs.pv.yaml
```
Comprobamos si se ha creado correctamente y veremos sus características:
```
kubectl get persistentvolume pv-nfs-data
kubectl describe persistentvolume pv-nfs-data
```

A continuación creamos el Persistent Volume Claim
```
kubectl apply -f nfs.pvc.yaml
```
Verificamos también que se ha creado correctamente:
```
kubectl get persistentvolume
kubectl get persistentvolumeclaims
kubectl describe persistentvolumeclaims pvc-nfs-data
```

Vamos a crear un fichero dentro del volumen NFS, para ello volvemos a conectarnos al servidor nfs y creamos el fichero con el comando echo:
```
ssh nfs
 bash -c 'echo "hello from our NFS mount!!!" > /export/volumes/pod/demo.html'
more /export/volumes/pod/demo.html
```

Podemos desconectarnos y a continuación vamos a desplegar un Pod de nginx con el volumen configurado. También se creará un servicio:
```
kubectl apply -f nfs.nginx.yaml
kubectl get service nginx-nfs-service
SERVICEIP=$(kubectl get service | grep nginx-nfs-service | awk '{print $3}')
```

Verificamos si se ha creado correctamente el pod y hacemos un curl para ver si obtenemos el contenido del fichero `demo.html`
```
kubectl get pods
curl http://$SERVICEIP/web-app/demo.html
```

Vamos a conectarnos al pod y verificamos que el fichero existe:
```
kubectl exec -it nginx-nfs-deploment-XXXX-YYY -- /bin/bash
ls /usr/share/nginx/html/web-app
more  /usr/share/nginx/html/web-app/demo.html
exit
```

Vemos a ver dónde está ejecutándose el pod y nos conectamos al nodo
```
kubectl get pods -o wide
ssh nodeX
```

En el nodo podemos verificar si tenemos algún filesystem del tipo nfs montado:
```
mount | grep nfs
```

Vamos a eliminar el pod, como pertenece a un deployment se creará de nuevo. Si volvemos a hacer el curl deberíamos ver el mismo contenido:
```
kubectl delete pods nginx-nfs-deploment-[tab][tab]
curl http://$SERVICEIP/web-app/demo.html
```

Podemos eliminar ya el deployment, el service, el PV y PVC
```
kubectl delete -f nfs.pv.yaml
kubectl delete -f nfs.pvc.yaml
kubectl delete -f nfs.nginx.yaml
```