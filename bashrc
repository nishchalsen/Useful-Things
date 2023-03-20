alias ssm="aws ssm start-session --target $i"
alias tf="terraform"
alias tg="terragrunt"
alias tgp="tg plan"
alias tfp="tf plan -out=tf.plan"
alias tfa="tf apply tf.plan"
alias rb=". ~/.bashrc"

function awsp() {
	export AWS_PROFILE=$1
}

function ini() {
    local VALUE=$1
    local OPTION=$2

    BASE_COMMAND="aws ec2 describe-instances --filter \"Name=tag:Name,Values=$VALUE\" --output text"
    SHORT_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"
    FULL_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,Placement.AvailabilityZone,InstanceType,Platform,LaunchTime,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"

    if [ "$OPTION" = "-f" ]; then
        eval "$BASE_COMMAND $FULL_FILTER"
    elif [ "$OPTION" = "-c" ]; then
        INSTANCES=$(eval "$BASE_COMMAND $SHORT_FILTER \"Name=instance-state-name,Values=running\"")
        if [ -z "$INSTANCES" ]; then return; fi

        echo "$INSTANCES" | nl -w2
        read -p "Choose server to ssm into: " choosen_num

        instance_id=$(echo "$INSTANCES" |  awk "NR==$choosen_num" | awk '{print $1;}')
        instance_name=$(echo "$INSTANCES" |  awk "NR==$choosen_num" | awk '{print $NF}')
        if [ -z "$instance_id" ]; then return; fi

        echo "Logging you into $instance_id ($instance_name)"
        aws ssm start-session --target $instance_id
    else
        eval "$BASE_COMMAND $SHORT_FILTER"
    fi
}

function inid() {
    local VALUE=$1
    local OPTION=$2

    BASE_COMMAND="aws ec2 describe-instances --instance-id $VALUE"
    SHORT_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"
    FULL_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,Placement.AvailabilityZone,InstanceType,Platform,LaunchTime,VpcId,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"

    if [ "$OPTION" = "-f" ]; then
        eval "$BASE_COMMAND $FULL_FILTER --output text"
    elif [ "$OPTION" = "-c" ]; then

        eval "$BASE_COMMAND $FULL_FILTER --output text"

        choices=("1: SG" "2: EBS" "3: TAGS")
        echo "${choices[@]}"
        read -p "Choose: " choosen_num

        case $choosen_num in
        1)  eval "$BASE_COMMAND --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Groups[*]' --output table";;
        2)  eval "$BASE_COMMAND --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.[VolumeId, Status, AttachTime]' --output table";;
        3)  eval "$BASE_COMMAND  --query 'Reservations[*].Instances[*].Tags' --output table";;
        esac

    else
        eval "$BASE_COMMAND $SHORT_FILTER --output text"
    fi
}

function insg() {
    local VALUE=$1
    local OPTION=$2

    BASE_COMMAND="aws ec2 describe-security-groups --group-ids  $VALUE"
    FILTER="--query 'SecurityGroups[*].[GroupId, Tags[?Key==\`Name\`]| [0].Value, VpcId]'"

    if [ "$OPTION" = "-c" ]; then
        eval "$BASE_COMMAND $FILTER --output text"

        choices=("1: INGRESS" "2: ENGRESS" "3: TAGS")
        echo "${choices[@]}"
        read -p "Choose: " choosen_num

        case $choosen_num in
        1)  eval "$BASE_COMMAND --query 'SecurityGroups[*].IpPermissions[*]' --output table";;
        2)  eval "$BASE_COMMAND --query 'SecurityGroups[*].IpPermissionsEgress[*]' --output table";;
        3)  eval "$BASE_COMMAND  --query 'SecurityGroups[*].Tags' --output table";;
        esac

    else
        eval "$BASE_COMMAND $FILTER --output text"
    fi
}

function inebs() {
    local VALUE=$1
    local OPTION=$2

    BASE_COMMAND="aws ec2 describe-volumes --volume-ids $VALUE"
    SHORT_FILTER="--query 'Volumes[*].[VolumeId,AvailabilityZone,VolumeType,Size,State,SnapshotId,Tags[?Key==\`Name\`]| [0].Value]'"
    FULL_FILTER="--query 'Volumes[*]'"

    if [ "$OPTION" = "-f" ]; then
        eval "$BASE_COMMAND $FULL_FILTER --output table"
    else
        eval "$BASE_COMMAND $SHORT_FILTER --output text"
    fi
}
