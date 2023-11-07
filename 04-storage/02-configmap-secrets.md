# Configuración dinámica
## Variables de entorno

kubectl apply -f deployment-alpha.yaml
sleep 5
kubectl apply -f deployment-beta.yaml


#Let's look at the services
kubectl get service

kubectl get pod

PODNAME=$(kubectl get pods | grep nginx-alpha | awk '{print $1}' | head -n 1)
echo $PODNAME


Está la información de alpha pero no la de beta, ya que no existía cuando el pod se creó:
kubectl exec -it $PODNAME -- /bin/sh
printenv | sort
exit

#If you delete the pod and it gets recreated, you will get the variables for the alpha and beta service information.
kubectl delete pod $PODNAME

PODNAME=$(kubectl get pods | grep nginx-alpha | awk '{print $1}' | head -n 1)
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort"

kubectl delete deployment nginx-beta
kubectl delete service nginx-beta
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort"


kubectl delete -f deployment-alpha.yaml


## Secretos
kubectl create secret generic app1 \
    --from-literal=USERNAME=myuser1 \
    --from-literal=PASSWORD='Galic14Calidad3!'

kubectl get secrets

echo $(kubectl get secret app1 --template={{.data.USERNAME}} )
echo $(kubectl get secret app1 --template={{.data.USERNAME}} | base64 --decode )

echo $(kubectl get secret app1 --template={{.data.PASSWORD}} )
echo $(kubectl get secret app1 --template={{.data.PASSWORD}} | base64 --decode )

kubectl apply -f deployment-secrets-env.yaml

PODNAME=$(kubectl get pods | grep nginx-secrets-env | awk '{print $1}' | head -n 1)
echo $PODNAME

kubectl exec -it $PODNAME -- /bin/sh
printenv | grep ^app1
exit


kubectl apply -f deployment-secrets-files.yaml
PODNAME=$(kubectl get pods | grep nginx-secrets-files | awk '{print $1}' | head -n 1)
echo $PODNAME

kubectl describe pod $PODNAME

kubectl exec -it $PODNAME -- /bin/sh
ls /etc/appconfig
cat /etc/appconfig/USERNAME
cat /etc/appconfig/PASSWORD
exit

kubectl delete secret app1
kubectl delete deployment nginx-secrets-env
kubectl delete deployment nginx-secrets-files

## ConfigMaps

kubectl create configmap appconfigprod \
    --from-literal=DATABASE_SERVERNAME=sql.example.local \
    --from-literal=BACKEND_SERVERNAME=be.example.local

more appconfigqa
kubectl create configmap appconfigqa \
    --from-file=appconfigqa


kubectl get configmap appconfigprod -o yaml
kubectl get configmap appconfigqa -o yaml

kubectl apply -f deployment-configmaps-env-prod.yaml
PODNAME=$(kubectl get pods | grep nginx-configmaps-env-prod | awk '{print $1}' | head -n 1)
echo $PODNAME


kubectl exec -it $PODNAME -- /bin/sh
printenv | sort
exit

kubectl apply -f deployment-configmaps-files-qa.yaml

PODNAME=$(kubectl get pods | grep nginx-configmaps-files-qa | awk '{print $1}' | head -n 1)
echo $PODNAME


kubectl exec -it $PODNAME -- /bin/sh
ls /etc/appconfig
cat /etc/appconfig/appconfigqa
exit

kubectl get configmap appconfigqa -o yaml

kubectl edit configmap appconfigqa

kubectl exec -it $PODNAME -- /bin/sh
watch cat /etc/appconfig/appconfigqa
exit

kubectl delete deployment nginx-configmaps-env-prod
kubectl delete deployment nginx-configmaps-files-qa
kubectl delete configmap appconfigprod
kubectl delete configmap appconfigqa