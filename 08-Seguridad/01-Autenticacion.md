# Autenticación
## Revisar autenticación basada en certificados

Podemos verificar la configuración actual que tenemos cargada:
```
kubectl config view
kubectl config view --raw
```

Vamos a leer la información del certificado que tiene nuestro fichero kubeconfig. En el sujeto CN será el nombre de usuario y también aparecerá el grupo al que pertenece:
```
kubectl config view --raw -o jsonpath='{ .users[*].user.client-certificate-data }' | base64 --decode > admin.crt
openssl x509 -in admin.crt -text -noout | head

kubectl config view --raw -o jsonpath='{ .users[1].user.client-certificate-data }' | base64 --decode | openssl x509 -text -noout
```


## Service Accounts

Veamos los Service Accounts que tenemos en nuestro sistema:
```
kubectl get serviceaccounts -A
```

Crearemos un nuevo service account:
```
kubectl create serviceaccount mysvcaccount1
```
Este service account contendrá su própio secreto:

#This new service account will get it's own secret.
kubectl describe serviceaccounts mysvcaccount1


#Create a workload, this uses the defined service account myserviceaccount
kubectl apply -f nginx-deployment.yaml
kubectl get pods


#You can see the pod spec gets populated with the serviceaccount. If we didn't specify one, it would get the default service account for the namespace.
#Use serviceAccountName as serviceAccount is deprecated.
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl get pod $PODNAME -o yaml

#The secret is mounted in the pod. See Volumes and Mounts
kubectl describe pod $PODNAME


## Acceder al API Server desde un Pod

PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl exec $PODNAME -it -- /bin/bash
ls /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/token


#Load the token and cacert into variables for reuse
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

curl --cacert $CACERT -X GET https://kubernetes.default.svc/api/
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/

#But it doesn't have any permissions to access objects...this user is not authorized to access pods
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/v1/namespaces/default/pods
exit

#We can also use impersonation to help with our authorization testing
kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1
kubectl get pods -v 6 --as=system:serviceaccount:default:mysvcaccount1
