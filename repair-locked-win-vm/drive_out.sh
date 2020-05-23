#!/bin/bash
# Drive your now unlocked VM out of the garage. 
#
# This script:
#       Detaches the secondary disk volume that was attached by
#	the drive-in script.
#       Attaches it back as the primary disk of the locked out VM
#	Restarts your locked out VM.
#
garage_vm_name="Win2012R2-Garage"
echo -n "Enter failed VM name: "
read failed_vm_name

failed_instance_id=$(aws ec2 describe-instances \
        --filter "Name=tag:Name,Values=[$failed_vm_name]" \
        --query "Reservations[0].Instances[0].InstanceId" --output text)

if [[ "$failed_instance_id" == "None" ]]; then exit; fi

echo "Detaching repaired volume from Garage VM..."
garage_instance_id=$(aws ec2 describe-instances \
    --filter "Name=tag:Name,Values=[$garage_vm_name]" \
    --query "Reservations[0].Instances[0].InstanceId" --output text)
volume_id=$(aws ec2 describe-instances --instance-id $garage_instance_id \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName==`xvdf`].Ebs.VolumeId' \
    --output text)
aws ec2 detach-volume --volume-id $volume_id

while
    state=$(aws ec2 describe-volumes --volume-id $volume_id \
        --query Volumes[0].State --output text)
    [[ "$state" != "available" ]]
do
    echo "Waiting for volume to be available..."
    sleep 3
done

echo "Attaching volume to failed VM..."
aws ec2 attach-volume --instance-id $failed_instance_id \
        --volume-id $volume_id --device /dev/sda1

while
    state=$(aws ec2 describe-volumes --volume-id $volume_id \
        --query Volumes[0].State --output text)
    [[ "$state" != "in-use" ]]
do
    echo "Waiting for volume to be available..."
    sleep 3
done

echo "Restarting the failed VM..."
aws ec2 start-instances --instance-id $failed_instance_id

while
    state=$(aws ec2 describe-instances --instance-id $failed_instance_id \
        --query "Reservations[0].Instances[0].State.Name" --output text)
    [[ "$state" != "running" ]]
do
    echo "Waiting for instance..."
    sleep 3
done

echo "Congratulations! All done."

