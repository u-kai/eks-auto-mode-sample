#!/bin/zsh

kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.2.0" | kubectl apply -f -
kubectl apply -f manifests/vpc-lattice.yml
# login to ECR
aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
# Run helm with either install or upgrade
helm install gateway-api-controller \
    oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart \
    --version=v1.1.0 \
    --set=serviceAccount.create=false \
    --namespace aws-application-networking-system \
    --set=log.level=info # use "debug" for debug level logs

kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/gatewayclass.yaml
