#!/bin/zsh

########################################################################
#  Collect System Facts
########################################################################

ROOT_DIR=$(pwd)

# Is Homebrew installed correctly?
if [[ $(uname -m) == 'arm64' ]]; then
  MAC_ARCHITECTURE="Apple"
  HOMEBREW_PATH="/opt/homebrew"
else
  MAC_ARCHITECTURE="Intel"
  HOMEBREW_PATH="/usr/local"
fi
HOMEBREW_INSTALLED=$(test -f $HOMEBREW_PATH/bin/brew;echo $?)
export PATH="$HOMEBREW_PATH/bin:$HOME/.poetry/bin:$PATH"

# Is Python3 Installed with
PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3;echo $?)

# Is Poetry Installed
POETRY_INSTALLED=$(test -f $HOME/.poetry/bin/poetry;echo $?)

# Is 1Password Installed
OP_INSTALLED=$(test -d /Applications/1Password.app;echo $?)

# Is 1Password CLI Installed
OP_CLI_INSTALLED=$(test -f /usr/local/bin/op;echo $?)

# Is bootstrap_mac repo synced on mac?
BOOTSTRAP_MAC_PATH="$HOME/.pj/bootstrap-mac/"
BOOTSTRAP_MAC_REPO=$(test -d $HOME/.pj/bootstrap-mac/.git/;echo $?)

# Is the OneDrive IT Setup Folder being synced?
IT_SETUP_FOLDER="$HOME/Library/CloudStorage/OneDrive-SharedLibraries-PurpleJay/Purple Jay - Documents/IT Setup"
IT_SETUP_FOLDER_CHECK=$(test -d "$IT_SETUP_FOLDER";echo $?)

# Personal OneDrive Folder
PERSONAL_FOLDER="$HOME/Library/CloudStorage/OneDrive-PurpleJay"

########################################################################
#  Define Functions
########################################################################

function install-homebrew {
  if [[ $HOMEBREW_INSTALLED == 1 ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    HOMEBREW_INSTALLED=$(test -f $HOMEBREW_PATH/bin/brew;echo $?)
  fi
  if [[ $HOMEBREW_INSTALLED != 0 ]]; then
    echo "function: install-homebrew"
    echo "Homebrew did not install successfully, try again."
    exit 1
  fi
}

function install-python {
  if [[ $HOMEBREW_INSTALLED == 0 && $PYTHON_INSTALLED == 1 ]]; then
    brew install python3
    python3 -m pip install pip --upgrade
    PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3;echo $?)
  fi
  if [[ $PYTHON_INSTALLED != 0 ]]; then
    echo "function: install-python"
    echo "Python 3 did not install successfully, try again."
    exit 1
  fi
}

function install-poetry {
  if [[ $HOMEBREW_INSTALLED == 0  && $PYTHON_INSTALLED == 0 && $POETRY_INSTALLED == 1 ]]; then
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
    POETRY_INSTALLED=$(test -f $HOME/.poetry/bin/poetry;echo $?)
  fi
  if [[ $POETRY_INSTALLED != 0 ]]; then
    echo "function: install-poetry"
    echo "Poetry did not install successfully, try again."
    exit 1
  fi
}

function install-op {
  if [[ $HOMEBREW_INSTALLED == 0  && $OP_INSTALLED == 1 ]]; then
    brew install --cask 1password
    OP_INSTALLED=$(test -d /Applications/1Password.app;echo $?)
  fi
  if [[ $OP_INSTALLED != 0 ]]; then
    echo "function: install-op"
    echo "1Password did not install successfully, try again."
    exit 1
  fi
}

function install-op-cli {
  if [[ $HOMEBREW_INSTALLED == 0 && $OP_CLI_INSTALLED == 1 ]]; then
    brew install --cask 1password-cli
    brew install jq
    OP_CLI_INSTALLED=$(test -f /usr/local/bin/op;echo $?)
  fi
  if [[ $OP_CLI_INSTALLED != 0 ]]; then
    echo "function: install-op-cli"
    echo "1Password CLI did not install successfully, try again."
    exit 1
  fi
}

function clone-bootstrap-mac {
    if [[ $HOMEBREW_INSTALLED == 1 ]]; then
      echo "function: clone-bootstrap-mac"
      echo "Homebrew is not installed"
      exit 1
    fi

    if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
      mkdir -p "$HOME"/.pj
      git clone https://github.com/purplejay-io/bootstrap-mac.git $BOOTSTRAP_MAC_PATH
      BOOTSTRAP_MAC_REPO=$(test -d $HOME/.pj/bootstrap-mac/.git/;echo $?)
    else
      cd $BOOTSTRAP_MAC_PATH || exit
      git reset --hard HEAD
      git fetch
      # Pull latest bootstrap-mac version
      if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
        git pull
      fi
      # Escape the script if git pull didn't get the latest
      if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
        echo "function: clone-bootstrap-mac"
        echo "An error occurred with pulling the version of bootstrap_man. Try again. "
        exit 1
      fi
    fi
    if [[ $OP_CLI_INSTALLED != 0 ]]; then
      echo "function: install-op-cli"
      echo "1Password CLI did not install successfully, try again."
      exit 1
    fi
}

function install-o365-apps {
  if [[ ! -f $HOMEBREW_PATH/bin/wget ]];then
    brew install wget
  fi

  cd /tmp
  if [[ ! -d "/Applications/Company Portal.app" ]];then
    wget https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Company%20Portal/installCompanyPortal.sh
    chmod +x installCompanyPortal.sh
    sudo ./installCompanyPortal.sh &
    # sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Company%20Portal/installCompanyPortal.sh)"
  fi
  if [[ ! -d "/Applications/Company Portal.app" ]];then
    echo "function: install-o365-apps"
    echo "Company Portal did not install, try again."
    exit 1
  fi
  if [[ ! -d "/Applications/Microsoft Teams.app" ]];then
    wget https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Misc/Rosetta2/installRosetta2.sh
    chmod +x installRosetta2.sh
    sudo ./installRosetta2.sh &
    #sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Misc/Rosetta2/installRosetta2.sh)"
    wget https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Teams/installTeams.sh
    chmod +x installTeams.sh
    sudo /bin/bash -c "./installTeams.sh"
    #sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Teams/installTeams.sh)"
  fi
  if [[ ! -d "/Applications/Microsoft Teams.app" ]];then
    echo "function: install-o365-apps"
    echo "Teams did not install, try again."
    exit 1
  fi
  if [[ ! -d "/Applications/Microsoft Edge.app" ]];then
    wget https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Edge/installEdge.sh
    chmod +x installEdge.sh
    sudo ./installEdge.sh &
    # sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Edge/installEdge.sh)"
  fi
  if [[ ! -d "/Applications/Microsoft Edge.app" ]];then
    echo "function: install-o365-apps"
    echo "Edge did not install, try again."
    exit 1
  fi
}
function install-apps {
  install-homebrew
  install-python
  install-poetry
  install-o365-apps
  install-op
  install-op-cli
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
    echo "The ephemeral password did not get created successfully in keychain, try again"
    exit 1
  fi
  ANSIBLE_KEYCHAIN_PASS=0
}

function reset-dock {
  defaults write com.apple.dock persistent-apps -array
  killall Dock
}

function reset-become-password {
  rm -f $BOOTSTRAP_MAC_PATH/vars/pass.yml
}

function check-ansible-readiness {
  if [[ $HOMEBREW_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "Homebrew must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $PYTHON_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "Python 3 must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $POETRY_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "Poetry must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $OP_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "1password must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $OP_CLI_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "1password CLI must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "bootstrap-mac repo must be cloned locally before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $IT_SETUP_FOLDER_CHECK == 1 ]]; then
    echo "function: check-ansible-readiness"
    echo "IT Setup OneDrive folder must be synced before you can run bootstrap-mac"
    exit 1
  fi

  # Remove old bootstrap_mac folder if found
  if [[ -d $HOME/.pj/bootstrap_mac/ ]]; then
    rm -Rf $HOME/.pj/bootstrap_mac/
  fi

  # Create empty secrets and user vars files if not found
  cd $BOOTSTRAP_MAC_PATH
  if [[ ! -f vars/secrets.yml ]]; then
    echo "---" > vars/secrets.yml
  fi
  if [[ ! -f vars/user.yml ]]; then
    echo "---" > vars/user.yml
  fi

  # Check Poetry
  poetry install
  if [[ ! -f .venv/bin/python ]]; then
    echo "function: check-ansible-readiness"
    echo "Poetry Virtual Enviornment was not setup correctly, try again."
    exit 1
  fi

  cp $IT_SETUP_FOLDER/pj-mac-1.0.0.tar.gz collections/
  poetry run ansible-galaxy collection install -r galaxy.yml --force

  if [[ ! -f $HOME/.ansible/collections/ansible_collections/pj/mac/MANIFEST.json ]]; then
    echo "function: check-ansible-readiness"
    echo "Ansible Collection was not installed correctly, try again."
    exit 1
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
  clone-bootstrap-mac
  check-ansible-readiness
  # Note: Should not get to this point if there was a failure, but adding just in case
  if [[ $ANSIBLE_READINESS == 1 ]]; then
    exit 1
  fi

  # 3. Change Directory
  cd $BOOTSTRAP_MAC_PATH

  # 4. If pass.yml does not exist, then ask user for it
  if [[ ! -f vars/pass.yml ]]; then
    echo -n Local Password:
    read -s password
    echo "---" > vars/pass.yml
    echo "ansible_become_password: $password" >> vars/pass.yml

    echo `security find-generic-password -a pj-bootstrap-ansible -w` | poetry run ansible-vault encrypt vars/pass.yml
  fi

  # 5. Check to make sure become password is encrypted
  if [[ $(poetry run ansible-vault view vars/pass.yml) == "" ]]; then
    echo "function: check-become-password"
    echo "Ansible-Vault wasn't able to encrypt your become password, try again."
    exit 1
  fi
  BECOME_PASSWORD_CHECK=0
}

function reset-bootstrap-mac {
  echo "About to remove bootstrap-mac, are you sure you want to continue?"
  # https://unix.stackexchange.com/questions/293940/how-can-i-make-press-any-key-to-continue
  read -r -s -k '?Press any key to continue.'
  sudo echo "You now have SUDO in this session"

  # Uninstall Python
  brew uninstall python3

  # Uninstall all Homebrew Casks
  for f in `brew list`; do
    brew uninstall --ignore-dependencies --force $f
  done

  # Uninstall 1password
  # brew uninstall 1password
  # brew uninstall 1password-cli
  rm -Rf $HOME/.config/op/

  # Remove Homebrew
  echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  sudo rm -Rf "$HOMEBREW_PATH"

  # Remove Poetry
  rm -Rf $HOME/.poetry

  # Remove .zprofile
  rm -f $HOME/.zprofile

  # Remove ansible directory
  rm -Rf $HOME/.ansible

  # Remove ephemeral password for ansible-vault
  security delete-generic-password -a pj-bootstrap-ansible

  # Remove bootstrap-mac
  rm -Rf $HOME/.pj/bootstrap-mac/

  # Reset OneDrive
  /Applications/OneDrive.app/Contents/Resources/ResetOneDriveApp.command

  # Uninstall O365 Apps
  sudo rm -Rf /Applications/Microsoft\ Teams.app/
  sudo rm -Rf /Applications/Microsoft\ Edge.app/
  sudo rm -Rf /Applications/Company\ Portal.app/

  exit 1
}

function display-help {
  echo "Usage: ./run.sh [Option]

  Options:
  [blank]     Install Apps and Goes through bootstrap-mac setup
  install     Only Install Apps
  noupdate    Runs bootstrap-mac minus homebrew playbooks
  password    Resets become password
  op          Runs op-cli secrets push/pull
  reset       Uninstall Apps and remove bootstrap-mac
  "
  exit 1
}

function op-login {
  eval "$(op signin --account purplejayllc)"
  check_op=$(op account get)
  if [[ $check_op == "" ]];then
    echo "function: op-login"
    echo "You did not login into 1password, make sure you have enabled Biometric Unlock."
    exit 1
  fi
  rm vars/secrets.yml
}

function op-create {
  if [[ -f "op_create.sh" ]];then
    ./op_create.sh > /dev/null
  fi
}

function check-dir {
  if [[ $ROOT_DIR != "$HOME/.pj/bootstrap-mac/" ]]; then
    echo "function: check-dir"
    echo "You must run bootstrap-mac from ~/.pj/bootstrap-mac. Try again"
    exit 1
  fi
}

function sync-user-yml {
  if [[ -f $PERSONAL_FOLDER/user.yml ]]; then
    cp $PERSONAL_FOLDER/user.yml $BOOTSTRAP_MAC_PATH/vars/
  fi
}


########################################################################
#  Run Playbook
########################################################################

if [[ $# -gt 1 ]]; then
  display-help
fi

if [[ $1 == "" ]]; then
  install-apps
  reset-dock
  check-become-password
  poetry run ansible-playbook local.yml
  exit 1
fi

if [[ $1 == "install" ]]; then
  install-apps
  exit 1
fi

if [[ $1 == "update" ]]; then
  check-become-password
  brew update
  brew upgrade
  poetry self update
  sync-user-yml
  poetry run ansible-playbook local.yml
  exit 1
fi

if [[ $1 == "noupdate" ]]; then
  check-become-password
  sync-user-yml
  poetry run ansible-playbook local.yml --skip-tags update
  exit 1
fi

if [[ $1 == "password" ]]; then
  reset-become-password
  check-become-password
  poetry run ansible-playbook local.yml --skip-tags update
  exit 1
fi

if [[ $1 == "op" ]]; then
  check-dir
  check-become-password
  op-login
  poetry run ansible-playbook local.yml --skip-tags update
  op-create
  exit 1
fi

if [[ $1 == "reset" ]]; then
  reset-bootstrap-mac
  exit 1
fi

display-help
