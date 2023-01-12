#!/bin/bash
bold="$(tput bold)"
normal="$(tput sgr0)"
green="$(tput setaf 2)"
underline="$(tput smul)"

function deploy_csi {
    echo "Deploying csi helm"
    helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
    helm repo update
    helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --namespace kube-system \
       --set image.repository=602401143452.dkr.ecr.$REGION.amazonaws.com/eks/aws-efs-csi-driver \
       --set controller.serviceAccount.create=false \
       --set controller.serviceAccount.name=efs-csi-controller-sa

}

function create_role {
    echo "Creating IAM ROLE if Not Exist"
    aws iam create-policy \
      --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
      --policy-document file://iam/iam-policy-template.json
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    echo "Creating EKS service account if not exist"
    eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region $REGION


}


function _create_efs {
    _parse_args "$@"
    cd ./efs
    echo "" > ./vars.tfvars
    echo "efs_name = \"$EFS_NAME\"" >> ./vars.tfvars
    echo "vpc_id = \"$VPC_ID\"" >> ./vars.tfvars
    echo "region = \"$REGION\"" >> ./vars.tfvars
    if [[ -z $PERFORMANCE_MODE ]]; then
        echo "performance_mode = \"generalPurpose\"" >> ./vars.tfvars
    else
        echo "performance_mode = \"$PERFORMANCE_MODE\"" >> ./vars.tfvars
    fi
    if [[ -z $THROUGHPUT_MODE ]]; then
        echo "throughput_mode = \"bursting\"" >> ./vars.tfvars
    else
        echo "throughput_mode = \"$THROUGHPUT_MODE\"" >> ./vars.tfvars
    fi
    echo "throughput = \"$THROUGHPUT\"" >> ./vars.tfvars

    if [[ -z $EFS_NAME ]] && [[ -z $VPC_ID ]] && [[ -z $REGION ]] && [[ -z $THROUGHPUT ]]
    then
        echo "Provide valid values"
        _usage
    else
        terraform init
        terraform apply --var-file="vars.tfvars" --auto-approve
        echo "${bold}+++++++++Use below information to deploy helm chart+++++++++${normal}"
        FS_IP=$(terraform output mount_target_ips)
        FS_ID=$(terraform output filesystem-id)
        echo "${bold}1) File System ID ====> ${green}${underline}$FS_ID${normal}"
        echo "${bold}2) File System IP ====> ${green}${underline}$FS_IP${normal}"
        echo "${bold}3) Region         ====> ${green}${underline}$REGION${normal}"
    fi
}

function _delete_efs {
    _parse_args "$@"
    cd ./efs
    echo "" > ./vars.tfvars
    echo "efs_name = \"$EFS_NAME\"" >> ./vars.tfvars
    echo "vpc_id = \"$VPC_ID\"" >> ./vars.tfvars
    echo "region = \"$REGION\"" >> ./vars.tfvars
    if [[ -z $PERFORMANCE_MODE ]]; then
        echo "performance_mode = \"generalPurpose\"" >> ./vars.tfvars
    else
        echo "performance_mode = \"$PERFORMANCE_MODE\"" >> ./vars.tfvars
    fi
    if [[ -z $THROUGHPUT_MODE ]]; then
        echo "throughput_mode = \"bursting\"" >> ./vars.tfvars
    else
        echo "throughput_mode = \"$THROUGHPUT_MODE\"" >> ./vars.tfvars
    fi
    echo "throughput = \"$THROUGHPUT\"" >> ./vars.tfvars

    if [[ -z $EFS_NAME ]] && [[ -z $VPC_ID ]] && [[ -z $REGION ]] && [[ -z $THROUGHPUT ]]
    then
        echo "Provide valid values"
        _usage
    else
            terraform init
            terraform destroy --var-file="vars.tfvars" --auto-approve
    fi
}

function main {
    _parse_args "$@"

    if [[ ! -z $ACTION ]]
    then
        if [[ $ACTION == "create_efs" ]]; then
            _create_efs "$@"
        elif [[ $ACTION == "delete_efs" ]]; then
            _delete_efs "$@"
        elif [[ $ACTION == "create_role" ]]; then
            create_role
        elif [[ $ACTION == "deploy_csi" ]]; then
            echo "running deploy_csi"
            deploy_csi
        else
            echo "provide valid action"
            _usage
        fi
    else
        echo "Provide valid action"
        _usage
    fi

}
function _usage {

    printf "Script will be used to provision efs. \nIt will use aws secret key and secret access key stored in machine.\n
    usage:
        ./deploy.sh --action <create_role> --region <region> --cluster-name <cluster-name>
        ./deploy.sh --action <create_efs|delete_efs> --efs-name <name> --vpc-id <vpc-xxxxx> --region <region> --throughput <in mbps, Only of --throughput is provisioned>
        ./deploy.sh --action <deploy_csi> --region <region> --cluster-name <cluster-name>
"
}

_parse_args() {
    if [ $# != 0 ]; then
        while true ; do
        echo "OP: $1 $2"
        case "$1" in
            --help)
                _usage
                exit 0
            ;;
            --action)
                ACTION=$2
                shift 2
            ;;
            --vpc-id)
                VPC_ID=$2
                shift 2
            ;;
            --region)
                REGION=$2
                shift 2
            ;;
            --performance-mode)
                PERFORMANCE_MODE=$2
                shift 2
            ;;
            --throughput-mode)
                THROUGHPUT_MODE=$2
                shift 2
            ;;
            --throughput)
                THROUGHPUT=$2
                shift 2
            ;;
            --efs-name)
                EFS_NAME=$2
                shift 2
            ;;
            --cluster-name)
                CLUSTER_NAME=$2
                shift 2
            ;;
            *)
                echo "unrecognized or invalid option" "$1"
                break
            ;;
        esac
        done
    fi
}

main "$@"

