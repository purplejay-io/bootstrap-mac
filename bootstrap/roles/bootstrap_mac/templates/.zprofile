export PATH="$HOME/.LOCAL/bin:$PATH"
export PATH="$HOME/.jetbrains:$PATH"

HOMEBREW_PATH="$(brew --prefix)"

export PATH="$HOMEBREW_PATH/opt/node@18/bin:$PATH"
alias python="python3"

{% if gitlab_api_token != "please_update_user_yml" %}
export UV_EXTRA_INDEX_URL = "https://__token__:{{ gitlab_api_token }}@gitlab.purplejay.net/api/v4/groups/205/-/packages/pypi/simple"
{% endif %}
export UV_NATIVE_TLS="true"


# Keep handy in case bug comes backup
# https://www.nccs.nasa.gov/nccs-users/instructional/logging-in/connectivity-issues
# alias ssh=/usr/libexec/ssh-apple-pkcs11
# alias scp="scp -S /usr/libexec/ssh-apple-pkcs11"
# alias sftp="sftp -S /usr/libexec/ssh-apple-pkcs11"
# alias rsync="rsync -e /usr/libexec/ssh-apple-pkcs11"

function pivssh-agent {
  ssh-add -D
  ssh-add -s /usr/lib/ssh-keychain.dylib
}

function pivssh-key {
  ssh-add -D
  ssh-add -s /usr/lib/ssh-keychain.dylib
}

function yk-ssh-key {
  ssh-keygen -D /usr/local/lib/libykcs11.dylib
}

function yk-ssh-agent {
  ssh-add -D
  ssh-add -s /usr/local/lib/libykcs11.dylib
}


function pj-update {
  cd ~/.pj/bootstrap-mac
  ./run.sh update
}
function pj-op {
  cd ~/.pj/bootstrap-mac
  ./run.sh op
}
function pj-noupdate {
  cd ~/.pj/bootstrap-mac
  ./run.sh noupdate
}
function pj-pass-reset {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset-password
}
function pj-reset {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset
}
function pj-reset-onedrive {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset-onedrive
}
function pj-reset-edge {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset-edge
}
function pj-reset-teams {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset-teams
}

function pj-reset-nextcloud {
  cd ~/.pj/bootstrap-mac
  ./run.sh reset-nextcloud
}

function pj-create-backup {
  cd ~/.pj/bootstrap-mac
  ./run.sh create-backup
}

function gitd {
  cd "$HOME/git/"
}

function pj-infra-config-update {
  # Store the current working directory
  CWD=$(pwd)

  # Function to execute commands and ensure return to the original directory
  cleanup() {
    deactivate || echo "no virtual environment to deactivate"
    cd "$CWD"
  }

  trap cleanup EXIT
  gitd
  cd infrastructure/pj-stack || exit
  venv
  python -m run -t setup --hosts localhost

}

function create-git-repo {
    # Check for the required parameters
    if [ $# -lt 2 ]; then
        echo "Usage: create-git-repo <gitlabGroup> <repoName>"
        return 1
    fi

    gitlabGroup=$1
    repoName=$2

    # Store the current working directory
    cwd=$(pwd)

    # Check if .gitignore exists
    if [ ! -f "$cwd/.gitignore" ]; then
        echo "Could not find .gitignore file"
        return 1
    fi

    # Check if .git exists
    if [ -d "$cwd/.git" ]; then
        echo "Must remove .git folder first"
        return 1
    fi

    # Try block equivalent in bash
    {
        git init --initial-branch=main
        git remote add origin "git@gitlab.purplejay.net:$gitlabGroup/$repoName.git"
        git add .
        git commit -m "Initial commit"
        git push --set-upstream origin main
    } || {
        echo "An error occurred while pushing to the repository."
    }
}

function pj-user-vars {
  file_path="$HOME/.pj/bootstrap-mac/vars/user.yml"
  code "$file_path"
}

function venv {
  if [[ -d ".venv" ]]; then
     rm -Rf .venv
  fi
  uv venv
  pip-install
  v
}

function pip-install {
  if [[ -f "requirements-dev.txt" ]]; then
    uv pip install -r "requirements-dev.txt" -p ".venv"
  elif [[ -f "requirements.txt" ]]; then
    uv pip install -r "requirements.txt" -p ".venv"
  else
    pipc
  fi
}

function pipc {
  if [[ -f "pyproject.toml" ]]; then
    uv pip compile --no-emit-index-url --strip-extras --output-file=requirements.txt pyproject.toml
    uv pip compile --no-emit-index-url --extra=test --output-file=requirements-test.txt pyproject.toml
    uv pip compile --no-emit-index-url --extra=test --extra=dev --output-file=requirements-dev.txt pyproject.toml

    pip-install
  elif [[ -f "requirements.in" ]]; then
    uv pip compile --no-emit-index-url --output-file=requirements.txt requirements.in

    pip-install
  else
    echo "No requirements.in or pyproject.toml file found"
  fi
}

function gitsub {
  if [[ -f ".gitmodules" ]]; then
    git submodule sync --recursive
    git submodule update --init --recursive --remote
  fi
}

function v {
  if [[ -d ".venv" ]]; then
    . .venv/bin/activate
  fi
}

function ssh-kill {
  ps aux -o pid,comm | grep "ssh -f" | grep -v grep | awk '{print $2}'| xargs kill
}

function ssh-tunnels {
  ~/tunnels.sh
}

function power-save {
  shutdown-vms
  sudo shutdown -s now
}

alias p="prlctl"
alias typora="open -a typora"
alias fde="sudo fdesetup authrestart"
alias dns="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder"

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
