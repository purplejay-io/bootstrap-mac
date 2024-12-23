#!/bin/zsh

########################################################################
#  Collect System Facts
########################################################################

# Is bootstrap_mac repo synced on mac?
BOOTSTRAP_MAC_PATH="${2:-$HOME/.pj/bootstrap-mac/}"
printf "Bootstrap Mac Path %s\n" "$BOOTSTRAP_MAC_PATH"

BOOTSTRAP_MAC_REPO=$(test -d "$BOOTSTRAP_MAC_PATH"/.git/;echo $?)

LOCAL_VAULT_PASS_FILE="$HOME/.pj-bootstrap-ansible.txt"

########################################################################
#  Define Functions
########################################################################

function install-bootstrapmac {
    if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
      mkdir -p "$BOOTSTRAP_MAC_PATH"
      git clone https://github.com/purplejay-io/bootstrap-mac.git "$BOOTSTRAP_MAC_PATH"
      BOOTSTRAP_MAC_REPO=$(test -d "$BOOTSTRAP_MAC_PATH"/.git/;echo $?)
    else
      cd "$BOOTSTRAP_MAC_PATH" || exit 1
      if [[ "$BOOTSTRAP_MAC_PATH" == *".pj"* ]]; then
        git reset --hard HEAD
        git fetch
        # Pull latest bootstrap-mac version
        if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
          git pull
          display-msg "The bootstrap-mac script has been updated. Re run the script now."
          exit 1
        fi
        # Escape the script if git pull didn't get the latest
        if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
          echo "function: install-bootstrapmac"
          display-msg "An error occurred with pulling the version of bootstrap_man. Try again. "
          exit 1
        fi
      else
        echo "The variable does not contain .pj -- Not pulling latest from git repo"
      fi
    fi
}

function display-msg {
  msg=$1

  osascript -e "display dialog \"$msg\" with title \"Bootstrap Mac Alert\" buttons {\"OK\"} default button \"OK\""
}

function check-keychain-password {
  ANSIBLE_KEYCHAIN_PASS=1
  ANSIBLE_KEYCHAIN_PASS_CHECK=$(security find-generic-password -a pj-bootstrap-ansible -w)
  if [[ $ANSIBLE_KEYCHAIN_PASS_CHECK == "" ]]; then
    security add-generic-password -a pj-bootstrap-ansible -s ansible -w "$(openssl rand -base64 25)"
    ANSIBLE_KEYCHAIN_PASS_CHECK=$(security find-generic-password -a pj-bootstrap-ansible -w)
  fi
  if [[ $ANSIBLE_KEYCHAIN_PASS_CHECK == "" ]]; then
    echo "function: check-keychain-password"
    display-msg "The ephemeral password did not get created successfully in keychain, try again"
    exit 1
  fi
  ANSIBLE_KEYCHAIN_PASS=0
}

function check-ansible-readiness {
  if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
    echo "function: check-ansible-readiness"
    display-msg "bootstrap-mac repo must be cloned locally before you can run bootstrap-mac"
    exit 1
  fi

  # Create empty secrets and user vars files if not found
  cd "$BOOTSTRAP_MAC_PATH" || (display-msg "failed going to bootstrap mac path"; exit 1)
  if [[ ! -f vars/user.yml ]]; then
    echo "---" > vars/user.yml
  fi

  # If none of the above failed, we can assume bootstrap_mac can be ran
  ANSIBLE_READINESS=0
}

function check-become-password {
  BECOME_PASSWORD_CHECK=1
  # 1. Check is the ephemeral password in keychain was successfully created.
   check-keychain-password
  if [[ $ANSIBLE_KEYCHAIN_PASS == 1 ]]; then
    exit 1
  fi

  # 2. Ensure ansible-vault can be ran
  install-bootstrapmac
  check-ansible-readiness
  # Note: Should not get to this point if there was a failure, but adding just in case
  if [[ $ANSIBLE_READINESS == 1 ]]; then
    exit 1
  fi

  # 3. Change Directory
  cd "$BOOTSTRAP_MAC_PATH" || (display-msg "error going to bootstrap mac path"; exit 1;)

  # 4. Create local ansible vault password file
  if [[ ! -f "$LOCAL_VAULT_PASS_FILE" ]]; then
    echo -n
    echo -n "Create a Vault Password:"
    read -rs vault_password
    printf "\n"
    echo "$vault_password" > "$LOCAL_VAULT_PASS_FILE"
  fi

  # 5. If pass.yml does not exist, then ask user for it
  if [[ ! -f "$BOOTSTRAP_MAC_PATH"/vars/pass.yml ]]; then
    echo -n
    echo -n "Enter Local Mac Password:"
    read -rs password
    printf "\n"
    echo "---" > "$BOOTSTRAP_MAC_PATH"/vars/pass.yml
    echo "ansible_become_password: $password" >> "$BOOTSTRAP_MAC_PATH"/vars/pass.yml
    check-venv

    echo `security find-generic-password -a pj-bootstrap-ansible -w` | uv run ansible-vault encrypt --vault-password-file "$LOCAL_VAULT_PASS_FILE" vars/pass.yml
  fi

  # 6. Check to make sure become password is encrypted
  if [[ $(uv run ansible-vault view vars/pass.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE" ) == "" ]]; then
    echo "function: check-become-password"
    display-msg "Ansible-Vault wasn't able to encrypt your become password, try again."
    exit 1
  fi
  BECOME_PASSWORD_CHECK=0
}

function reset-become-password {
  security delete-generic-password -a pj-bootstrap-ansible
  rm -f "$BOOTSTRAP_MAC_PATH"/vars/pass.yml
  rm -f "$LOCAL_VAULT_PASS_FILE"
}

function prune-logs {
  if [[ -f ansible-logs.txt ]]; then
    sed -i '' '2000,$ d' ansible-logs.txt
  fi
  if [[ -f stderr.txt ]]; then
    sed -i '' '2000,$ d' stderr.txt
  fi
  if [[ -f stdout.txt ]]; then
    sed -i '' '2000,$ d' stdout.txt
  fi
}


function display-help {
  display-msg "Usage: ./run.sh [Option] [Path]

  Options:
  install           Install Apps and Clones bootstrap-mac
  update            Runs bootstrap-mac and upgrades poetry
  noupdate          Runs bootstrap-mac minus homebrew playbooks
  reset-password    Resets become password

  Path:
  <blank>           Will default to ~/.pj/bootstrap-mac
  "
  exit 1
}

########################################################################
#  Run Playbook
########################################################################

if [[ $# -gt 2 ]]; then
  display-help
fi

if [[ $1 == "install" ]]; then
  install-bootstrapmac
  cd "$BOOTSTRAP_MAC_PATH" || (display-msg "error going to bootstrap mac path"; exit 1)
  check-become-password

  FILEVAULT_CHECK=$(uv run ansible-vault view "$BOOTSTRAP_MAC_PATH"/vars/pass.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE" | yq -r '.ansible_become_password' | sudo -S fdesetup isactive)
  if [[ $FILEVAULT_CHECK != "true" ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?FileVault"
    display-msg "Opening System Preferences. Turn on Filevault before pressing OK."
    printf "\n"
  fi

  open "/Applications/Company Portal.app"
  display-msg "Opening Company Portal. Ensure your device is compliant before pressing OK."
  printf "\n"

  uv run ansible-playbook local.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE"

  exit 1
fi

if [[ $1 == "update" ]]; then
  prune-logs
  brew update
  brew upgrade
  check-become-password
  uv run ansible-playbook local.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "check" ]]; then
  check-become-password
  uv run ansible-playbook local.yml --diff --check -vv --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "noupdate" ]]; then
  prune-logs
  check-become-password
  uv run ansible-playbook local.yml --skip-tags update --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "reset-password" ]]; then
  reset-become-password
  check-become-password
  uv run ansible-playbook local.yml --skip-tags update --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

display-help
