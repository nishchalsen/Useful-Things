alias ssm="aws ssm start-session --target $i"

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
        INSTANCES=$(eval "$BASE_COMMAND $SHORT_FILTER")
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

function insid() {
	local VALUE=$1
    local OPTION=$2

    BASE_COMMAND="aws ec2 describe-instances --instance-id $VALUE"
    SHORT_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"
    FULL_FILTER="--query 'Reservations[*].Instances[*].[InstanceId,Placement.AvailabilityZone,InstanceType,Platform,LaunchTime,VpcId,PrivateIpAddress,PublicIpAddress,State.Name,Tags[?Key==\`Name\`]| [0].Value]'"

    if [ "$OPTION" = "-f" ]; then
        eval "$BASE_COMMAND $FULL_FILTER --output text"
    elif [ "$OPTION" = "-c" ]; then

        eval "$BASE_COMMAND $FULL_FILTER --output text"

        options=("1) SG" "2) EBS" "3) TAGS")
        printf '%s\n' "${options[@]}"
        read -p "Choose: " choosen_num

        case $choosen_num in
        1) echo "SG:"; eval "$BASE_COMMAND --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Groups[*]' --output table";;
        2) echo "EBS:";  eval "$BASE_COMMAND --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.[VolumeId, Status, AttachTime]' --output table";;
        3) echo "Tags:";  eval "$BASE_COMMAND  --query 'Reservations[*].Instances[*].Tags' --output table";;
        esac

    else
        eval "$BASE_COMMAND $SHORT_FILTER --output text"
    fi
}
