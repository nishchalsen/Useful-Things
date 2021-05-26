export VISUAL=vim
export EDITOR="$VISUAL"


alias ssm="aws ssm start-session --target $i"

function insid() {
    aws ec2 describe-instances --filter "Name=tag-value,Values=$1" --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name,Tags[?Key==`Name`]| [0].Value]' --output text
}
