#!/bin/bash

#PROFILE="032443079205_SSO-Consumer-admin"
export AWS_PROFILE="default"


# Verificar si se proporcionan argumentos
uso() {
    echo "Use: "
    echo "	$(basename $0) scale in|out"
    echo "	$(basename $0) installVM on|off"
    echo "	$(basename $0) status"
    echo "	$(basename $0) resources"
    echo "	$(basename $0) sso"
    echo "	$(basename $0) jmp"
    echo "	$(basename $0) vpc"
    echo "	$(basename $0) policies"
    echo "	$(basename $0) policy <policyname>"
    echo "	$(basename $0) users"
    echo "	$(basename $0) user <username>" 
    echo "	$(basename $0) subnets"
}

if [ $# -eq 0 ]; then
	uso
	exit 1
fi

ORDER=$(echo $1 |  tr [:upper:] [:lower:])

case $ORDER in
	"roles") 
		aws iam list-roles | jq '.Roles[] | .RoleName + " -->  " + .Arn, .AssumeRolePolicyDocument'
		exit 0
		;;
	"policies") 
		aws iam list-policies | jq '.Policies[] | .PolicyName + " -->  " + .Arn'
		exit 0
		;;
	"policy") 
		FILTER='.Policies[] | select(.PolicyName == "'$2'") | .Arn + " " + .DefaultVersionId'
		aws iam list-policies | jq -r "$FILTER" | while read ARN VERSION
		do
		  aws iam get-policy-version --policy-arn $ARN --version-id $VERSION
		done
		exit 0
		;;
	"users") 
		aws iam list-users | jq '.Users[] | .UserName + "(" + .UserId + ") Arn: " + .Arn'
		exit 0
		;;
	"user") 
		aws iam get-user --user-name $2 | jq '.User | .UserName + " (" + .UserId + ")"'
                aws iam list-user-policies --user-name $2
                aws iam list-attached-user-policies --user-name $2 | jq '.AttachedPolicies[] | "    Policy name: " +  .PolicyName + "(" + .PolicyArn + ")" + .DefaultVersionId'

		aws iam list-groups-for-user --user-name $2 | jq -r '.Groups[] | .GroupName + " " + .GroupId + " " + .Arn' | while read NAME ID ARN
		do
		    echo "    Grupo: $NAME ($ID) $ARN"
		    # aws iam list-group-policies --group-name $NAME
		    aws iam list-attached-group-policies --group-name $NAME | jq '.AttachedPolicies[] | .PolicyName + " (" + .PolicyArn + ")"'
		done
		exit 0
		;;
	"vpc")
		aws ec2 describe-vpcs --region eu-north-1  | jq '.Vpcs[] | "Name: " + (.Tags[] | select(.Key == "Name") | .Value) + "; ID: " + .VpcId + "; CIDR: " + .CidrBlock'
		exit 0
		;;
	"subn")
		aws ec2 describe-subnets | jq '.Subnets[] | "Name: " + (.Tags[] | select(.Key == "Name") | .Value) +  "; ID: " + .SubnetId + "; CIDR: " + .CidrBlock + "; VPC-Subnet: <" + .VpcId + "><" + .SubnetId +">"'
		exit 0
		;;
	"status")
		aws ec2 describe-instances --region=eu-north-1 --profile $AWS_PROFILE | jq '.Reservations[].Instances[] | .InstanceId + " --> " + .PrivateIpAddress + ", " +  .State.Name + " (" + .InstanceType + ")"'
		exit 0
		;;
	"resources")
		kubectl get nodes | awk '{ print $1} ' | while read node
		do
			echo "--- $node ---"
			kubectl describe node $node | egrep "Pressure|cpu|memory|ephemeral"
		done
		exit 0
		;;
	"scale")
		PARAM=$(echo $2 |  tr [:upper:] [:lower:])
		case $PARAM in
			"in")
				#eksctl scale  nodegroup --cluster=EO-cCM --name CCD --nodes=0 --region=eu-north-1 --profile $AWS_PROFILE
				eksctl scale  nodegroup --cluster=EO-cCM --name CCD2 --nodes=0 --region=eu-north-1 --profile $AWS_PROFILE
				sleep 30
				#eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD --profile $AWS_PROFILE
				eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD2 --profile $AWS_PROFILE
				exit 0
				;;
			"out")
				#eksctl scale  nodegroup --cluster=EO-cCM --name CCD --nodes=0 --region=eu-north-1 --profile $AWS_PROFILE
				eksctl scale  nodegroup --cluster=EO-cCM --name CCD2 --nodes=6 --region=eu-north-1 --profile $AWS_PROFILE
				sleep 30
				#eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD --profile $AWS_PROFILE
				eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD2 --profile $AWS_PROFILE
				exit 0
				;;
			*)
				uso
				exit 1
				;;
		esac
		;;
	"sso")
		aws configure sso
		exit 0
		;;
	"installvm")
		PARAM=$(echo $2 |  tr [:upper:] [:lower:])
		case $PARAM in
			"start"|"on")
				aws ec2 start-instances --instance-ids i-0f1eaea2773c5a58c --profile $AWS_PROFILE  --region=eu-north-1 
				exit 0
				;;
			"stop"|"off")
				aws ec2 stop-instances --instance-ids i-0f1eaea2773c5a58c --profile $AWS_PROFILE  --region=eu-north-1 
				exit 0
				;;
			*) 
				echo "Opción no válida"
				uso
				exit 1
				;;
		esac
		;;
	"jmp" )
		./AWS-JMP.sh
		exit 0
		;;
	*)
		echo "<$ORDER> option invalid"
		uso
		exit 1
		;;
esac


