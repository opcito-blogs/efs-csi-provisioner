# efs-csi-provisioner

The [Amazon Elastic File System](https://aws.amazon.com/efs/) Container Storage Interface (CSI) Driver implements the [CSI](https://github.com/container-storage-interface/spec/blob/master/spec.md) specification for container orchestrators to manage the lifecycle of Amazon EFS file systems.

efs-csi-provisioner automation script to easily create EFS and deploy efs csi on EKS cluster.



### Create AWS IAM Policy AmazonEKS_EFS_CSI_Driver_Policy
    aws iam create-policy \
        --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
        --policy-document file://iam-policy-template.json

### Create AWS EFS using terraform script
    cd efs
    bash provision.sh --action create \ 
    --efs-name your-efs --vpc-id vpc-XXXXXXX \
    --region your-region

