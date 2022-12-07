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
