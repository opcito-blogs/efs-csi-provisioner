# efs-csi-provisioner

The [Amazon Elastic File System](https://aws.amazon.com/efs/) Container Storage Interface (CSI) Driver implements the [CSI](https://github.com/container-storage-interface/spec/blob/master/spec.md) specification for container orchestrators to manage the lifecycle of Amazon EFS file systems.

efs-csi-provisioner automation script to easily create EFS and deploy efs csi on EKS cluster.



### Create AWS IAM Policy AmazonEKS_EFS_CSI_Driver_Policy
        ./deploy.sh --action <create_role> --region <region> --cluster-name <cluster-name>

### Create AWS EFS using terraform script
        ./deploy.sh --action <create_efs|delete_efs> --efs-name <name> --vpc-id <vpc-xxxxx> --region <region> --throughput <in mbps, Only of --throughput is provisioned>

### Deploy EFS CSI Driver
        ./deploy.sh --action <deploy_csi> --region <region> --cluster-name <cluster-name>

