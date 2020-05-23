#!/bin/bash
#
# Drive your locked VM into the garage for repairs.  The Garage VM
# is an EC2 instance that is identical to your locked-out VM. Make
# sure you install the Windows Assessment and Deployment Kit on the 
# Garage VM
#
# This script:
# 	Stops the locked out VM
#	Detaches the primary disk volume
#	Attaches it as a secondary disk of the Garage VM
#
# You then connect to the Garage VM and run the disable-firewalls.bat
# script.

# This should be a VM identical to the one you are locked out off.
garage_vm_name="Win2012R2-Garage"

echo -n "Enter failed VM name: "
read failed_vm_name

failed_instance_id=$(aws ec2 describe-instances \
        --filter "Name=tag:Name,Values=[$failed_vm_name]" \
        --query "Reservations[0].Instances[0].InstanceId" --output text)

echo "Stopping failed instance..."
aws ec2 stop-instances --instance-ids $failed_instance_id

while
    state=$(aws ec2 describe-instances --instance-id $failed_instance_id \
        --query "Reservations[0].Instances[0].State.Name" --output text)
    [[ "$state" != "stopped" ]]
do
    echo "Waiting for instance to stop..."
    sleep 3
done

echo "Detaching volume from $failed_vm_name..."
volume_id=$(aws ec2 describe-instances --instance-id $failed_instance_id \
    --query "Reservations[*].Instances[*].BlockDeviceMappings[0].Ebs.VolumeId" --output text)
aws ec2 detach-volume --volume-id $volume_id

while
    state=$(aws ec2 describe-volumes --volume-id $volume_id \
        --query Volumes[0].State --output text)
    [[ "$state" != "available" ]]
do
    echo "Waiting for volume to be available..."
    sleep 3
done

echo "Attaching volume to Garage VM..."
garage_instance_id=$(aws ec2 describe-instances \
    --filter "Name=tag:Name,Values=[$garage_vm_name]" \
    --query "Reservations[0].Instances[0].InstanceId" --output text)
aws ec2 attach-volume --instance-id $garage_instance_id --volume-id $volume_id --device xvdf

while
    state=$(aws ec2 describe-volumes --volume-id $volume_id \
        --query Volumes[0].State --output text)
    [[ "$state" != "in-use" ]]
do
    echo "Waiting for volume to be attached..."
    sleep 3
done

echo "Done.  Please connect to the Garage VM for next steps."
