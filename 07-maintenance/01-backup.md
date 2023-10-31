# ETCD Backup
Vamos a obtener información clve de la configuración de etcd: imagen, tag, comando, dorectorio, mounts, volúmenes:
```
kubectl -n kube-system describe pod etcd-node1
```

Esta configuración viene del manifiesto del pod estático:
```
more /etc/kubernetes/manifests/etcd.yaml
```

Se pueden ver los valores de la instancia que corre actualmente con:
```
ps -aux | grep etcd
```

Verificamos qué versión estamos ejecutando
```
kubectl exec -it etcd-node1 -n kube-system -- /bin/sh -c 'ETCDCTL_API=3 /usr/local/bin/etcd --version' | head
```

```
yum install wget
export RELEASE="3.5.7"
wget https://github.com/etcd-io/etcd/releases/download/v${RELEASE}/etcd-v${RELEASE}-linux-amd64.tar.gz
tar -zxvf etcd-v${RELEASE}-linux-amd64.tar.gz
cd etcd-v${RELEASE}-linux-amd64
cp etcdctl /usr/local/bin
```

Verificamos que se ha instalado correctamente:
```
ETCDCTL_API=3 etcdctl --help | head
```

Crearemos un secreto que borraremos y recuperaremos mas adelante
```
kubectl create secret generic test-secret \
    --from-literal=username='svcaccount' \
    --from-literal=password='Galic14Calidad3!'
```

Definimos una variable con el endpoint de etcd
```
ENDPOINT=https://127.0.0.1:2379
```

Verificamos que nos conectamos al cluster correcto:
```
ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINT \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list
```

Vamos a hacer un backup y guardarlo en /var/lib/dat-backup.db:
```
ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINT \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    snapshot save /var/lib/dat-backup.db
```

Veamos los metadatos de nuestro snapshot:
```
ETCDCTL_API=3 etcdctl --write-out=table snapshot status /var/lib/dat-backup.db
```

Vamos a borrar el objeto que acabábamos de crear:
```
kubectl delete secret test-secret
```

Vamos a restaruar el bakcup en un directorio diferente:
```
cd /var/lib
ETCDCTL_API=3 etcdctl snapshot restore /var/lib/dat-backup.db
```
Confirmamos que nuestros datos estan en este nuevo directorio:
```
ls -l
```

Actualizamos el manifiesto del pod estático en estas tres líneas:
```
    #    - --data-dir=/var/lib/default.etcd
    #...
    #   volumeMounts:
    #    - mountPath: /var/lib/default.etcd
    #...
    #   volumes:
    #    - hostPath:
    #        name: etcd-data
    #        path: /var/lib/default.etc

cp /etc/kubernetes/manifests/etcd.yaml .
vi /etc/kubernetes/manifests/etcd.yaml
```

Al detectar el kubelet que se ha modificado el manifiesto reiniciará el pod de etcd. Esperamos hasta que arranque y verificamos si volvemos a tener el secreto:
```
kubectl get secret test-secret
```


