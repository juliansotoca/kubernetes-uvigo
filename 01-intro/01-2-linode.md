

terraform apply

cd ansible
ansible-playbook k8s.yml -i inventory -l master,k8s_workers


kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version 1.26.5

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config



kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml


kubeadm join 45.56.65.40:6443 --token yphggk.qwimlr93t5tcehos \
        --discovery-token-ca-cert-hash sha256:40cd992557bcf759b032ea344b92daf16ec603cda784c408110021d1ab550bb1


kubectl create deployment whoami --image=traefik/whoami
kubectl expose deployment whoami --type=NodePort --port=80
kubectl get svc
kubectl get ep
kubectl port-forward whoami-7c88bd4c6f-jppbw 8080:80 &
curl localhost:8080
fg
kubectl get pod -o wide


kubectl create deployment hello --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deploy hello --port=80 --target-port=8080 --type=NodePort
kubectl scale deployment hello --replicas=5