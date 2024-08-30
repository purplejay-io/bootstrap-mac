function yk-ssh-key {
  ssh-keygen -D /usr/local/lib/libykcs11.dylib
}

function yk-ssh-agent {
  ssh-add -D
  ssh-add -s /usr/local/lib/libykcs11.dylib
}
