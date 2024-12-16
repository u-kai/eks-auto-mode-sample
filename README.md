# EKS Auto Mode Sample

This sample demonstrates how to create an EKS cluster using the EKS Auto Mode feature.

## Note

An EKS cluster can incur significant costs, even when idle. To minimize expenses, it is strongly recommended to destroy the cluster promptly when it is no longer needed. You can use the `Execute Terraform` workflow to destroy the EKS cluster. For more information, see the [Destroy](#Destroy) section.

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- Fork or clone this repository

## Setup

1. Set the following variables in your GitHub Actions variables.

- `AWS_ACCOUNT_ID`: Your AWS Account ID
- `AWS_ROLE_ARN` : The ARN of the role that will be assumed by the GitHub Actions and used to create the EKS cluster, Network resources, and other resources.
- `TF_STATE_BUCKET`: The name of the S3 bucket to store the Terraform state file.

2. Run the `Execute Terraform` workflow manually with following the parameters to create the EKS cluster.
   - branch: main
   - command: apply -auto-approve
     - If you want to preview the change before applying, you can use the `plan` command.

Execute step 2 and wait for about 10 minutes for the EKS cluster to be created.

## Deploy sample pod identity apps

1. Run the `Build and Deploy Apps` workflow manually with following the parameters to deploy sample pod identity apps.

This workflow will create the following resources:

- ECR repository and push the sample application container image to this repository.
- EKS Pod Identity association resources
- IAM role for the pod identity
- IAM role policy for the pod identity

## Use the EKS cluster

1. Edit the `~/.aws/config` file to configure the AWS CLI Profile for the EKS cluster Administrator role. Add the following configuration to the `~/.aws/config` file:

   ```bash
   [profile eks-sample-cluster-admin]
   region = ap-northeast-1
   role_arn = arn:aws:iam::${YOUR_AWS_ACCOUNT_ID}:role/eks-sample-cluster-admin
   # source_profile is the profile that you use to assume the role
   source_profile = default
   ```

2. Run the following command to update the kubeconfig file:

   ```bash
    aws eks --region ap-northeast-1 update-kubeconfig --name eks-auto-mode-sample
   ```

3. Add the --profile setting to the `~/.kube/config` for AWS CLI commands

   ```bash
   ...
   ...
   users:
   - name: arn:aws:eks:ap-northeast-1:YOUR_AWS_ACCOUNT_ID:cluster/eks-auto-mode-sample
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          args:
          - --region
          - ap-northeast-1
          - eks
          - get-token
          - --cluster-name
          - eks-auto-mode-sample
          - --output
          - json
          # add the --profile setting
          - --profile
          - eks-sample-cluster-admin
          command: aws
   ```

4. Verify the connection to the EKS cluster by running the following command:

   ```bash
   kubectl get nodepools
   ```

- If you want try to deploy sample application, you can run below command.

  ```bash
  kubectl apply -f manifests
  ```

  - Note: Before apply above command, you have to edit the `manifests/pod-identity-sample.yml` file to use the correct ECR repository URI.

## Destroy

- Run `Execute Terraform` workflow manually with the following parameters for to destroy the EKS cluster.
  - branch: main
  - command: destroy -auto-approve
