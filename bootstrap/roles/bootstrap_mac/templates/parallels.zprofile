function power-save {
    shutdown-vms
    sudo shutdown -s now
}

alias typora="open -a typora"

function reboot-vms {
vm_list=$(prlctl list -o name --no-header)
while IFS= read -r vm_name
do
  echo "VM Name: $vm_name"
  prlctl restart "$vm_name"
done <<(echo "$vm_list")
}
function shutdown-vms {
    vm_list=$(prlctl list -o name --no-header)
    while IFS= read -r vm_name
    do
      echo "VM Name: $vm_name"
      prlctl stop "$vm_name"
    done <<(echo "$vm_list")
}
function start-vms {
    vm_list=$(prlctl list -a -o name --no-header)
    while IFS= read -r vm_name
    do
      echo "VM Name: $vm_name"
      prlctl start "$vm_name"
    done <<(echo "$vm_list")
}
