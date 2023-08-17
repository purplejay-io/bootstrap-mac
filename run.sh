#!/bin/zsh

########################################################################
#  Collect System Facts
########################################################################

script_path=$(readlink -f "${BASH_SOURCE:-$0}")
ROOT_DIR=$(dirname "$script_path")
echo $ROOT_DIR

# Is Homebrew installed correctly?
if [[ $(uname -m) == 'arm64' ]]; then
  MAC_ARCHITECTURE="Apple"
  HOMEBREW_PATH="/opt/homebrew"
else
  MAC_ARCHITECTURE="Intel"
  HOMEBREW_PATH="/usr/local"
fi
HOMEBREW_INSTALLED=$(test -f $HOMEBREW_PATH/bin/brew;echo $?)
export PATH="$HOMEBREW_PATH/bin:$HOME/.local/bin:$PATH"

# Is Python3 Installed with
PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3;echo $?)

# Is Poetry Installed
POETRY_INSTALLED=$(test -f $HOME/.local/bin/poetry;echo $?)

# Is 1Password Installed
# Overriding for now as 1Password no longer a dependency for employees to connect
# OP_INSTALLED=$(test -d /Applications/1Password.app;echo $?)
OP_INSTALLED=0

# Is 1Password CLI Installed
# Overriding for now as 1Password no longer a dependency for employees to connect
# OP_CLI_INSTALLED=$(test -f /usr/local/bin/op;echo $?)
OP_CLI_INSTALLED=0

# Is bootstrap_mac repo synced on mac?
BOOTSTRAP_MAC_PATH="$HOME/.pj/bootstrap-mac/"
BOOTSTRAP_MAC_REPO=$(test -d $HOME/.pj/bootstrap-mac/.git/;echo $?)

# Is the OneDrive IT Setup Folder being synced?
#IT_SETUP_FOLDER="$HOME/Library/CloudStorage/OneDrive-SharedLibraries-PurpleJay/Purple Jay - Documents/IT Setup"
#IT_SETUP_FOLDER_CHECK=$(test -d "$IT_SETUP_FOLDER";echo $?)

# Personal OneDrive Folder
PERSONAL_FOLDER="$HOME/Library/CloudStorage/OneDrive-PurpleJay"

########################################################################
#  Define Functions
########################################################################

function install-homebrew {
  if [[ $HOMEBREW_INSTALLED == 1 ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    HOMEBREW_INSTALLED=$(test -f $HOMEBREW_PATH/bin/brew;echo $?)
    if [[ $(uname -m) == 'arm64' ]]; then
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    else
      sudo chown -R $(whoami) /usr/local/share/zsh /usr/local/share/zsh/site-functions
      chmod u+w /usr/local/share/zsh /usr/local/share/zsh/site-functions
    fi
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
    $HOMEBREW_PATH/bin/python3 -m pip install pip --upgrade
    PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3;echo $?)
  fi
  if [[ $PYTHON_INSTALLED != 0 ]]; then
    echo "function: install-python"
    echo "Python 3 did not install successfully, try again."
    exit 1
  fi
}

function setup-venv {
  sudo ln -s $HOMEBREW_PATH/bin/python3 $HOMEBREW_PATH/bin/python
  python -m venv "$ROOT_DIR/.venv"
  . $ROOT_DIR/.venv/bin/activate
  python -m pip install -r $ROOT_DIR/requirements.txt
}

function install-poetry {
  if [[ $HOMEBREW_INSTALLED == 0  && $PYTHON_INSTALLED == 0 && $POETRY_INSTALLED == 1 ]]; then
    curl -sSL https://install.python-poetry.org | python3 -
    POETRY_INSTALLED=$(test -f $HOME/.local/bin/poetry;echo $?)
  fi
  if [[ $POETRY_INSTALLED != 0 ]]; then
    echo "function: install-poetry"
    echo "Poetry did not install successfully, try again."
    exit 1
  fi
}

function install-op {
#  if [[ $HOMEBREW_INSTALLED == 0  && $OP_INSTALLED == 1 ]]; then
#    brew install --cask 1password
#    OP_INSTALLED=$(test -d /Applications/1Password.app;echo $?)
#  fi
  if [[ $OP_INSTALLED != 0 ]]; then
    echo "function: install-op"
    echo "1Password did not install successfully from Intune, please contact an administrator."
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

function install-bootstrapmac {
    if [[ $HOMEBREW_INSTALLED == 1 ]]; then
      echo "function: install-bootstrapmac"
      echo "Homebrew is not installed"
      exit 1
    fi

    if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
      mkdir -p "$HOME"/.pj
      git clone https://github.com/purplejay-io/bootstrap-mac.git $BOOTSTRAP_MAC_PATH
      BOOTSTRAP_MAC_REPO=$(test -d $HOME/.pj/bootstrap-mac/.git/;echo $?)
#      echo "Bootstrap-mac was not found in ~/.pj/bootstrap-mac/"
#      echo "Please follow the instructions and try again."
#      exit 1
    else
      cd $BOOTSTRAP_MAC_PATH || exit
      git reset --hard HEAD
      git fetch
      # Pull latest bootstrap-mac version
      if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
        git pull
        echo "The bootstrap-mac script has been updated. Re run the script now."
        exit 1
      fi
      # Escape the script if git pull didn't get the latest
      if [[ $(git rev-list HEAD...origin/main --count) != 0 ]]; then
        echo "function: install-bootstrapmac"
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

function install-o365apps {
  if [[ ! -f $HOMEBREW_PATH/bin/wget ]];then
    brew install wget
  fi

  if [[ ! -d "/Applications/Company Portal.app" ]];then
    sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Company%20Portal/installCompanyPortal.sh)"
  fi
  if [[ ! -d "/Applications/Company Portal.app" ]];then
    echo "function: install-o365apps"
    echo "Company Portal did not install, try again."
    exit 1
  fi
  if [[ ! -d "/Applications/Microsoft Teams.app" ]];then
    sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Misc/Rosetta2/installRosetta2.sh)"
    sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Teams/installTeams.sh)"
  fi
  if [[ ! -d "/Applications/Microsoft Teams.app" ]];then
    echo "function: install-o365apps"
    echo "Teams did not install, try again."
    exit 1
  fi
  if [[ ! -d "/Applications/Microsoft Edge.app" ]];then
    sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Edge/installEdge.sh)"
  fi
  if [[ ! -d "/Applications/Microsoft Edge.app" ]];then
    echo "function: install-o365apps"
    echo "Edge did not install, try again."
    exit 1
  fi
}
function install-apps {
  install-homebrew
  install-python
#  install-poetry
#  install-o365apps
#  install-op
#  install-op-cli
}

function check-dir {
  if [[ $ROOT_DIR != "$HOME/.pj/bootstrap-mac" ]]; then
    echo "function: check-dir"
    echo "You must run bootstrap-mac from ~/.pj/bootstrap-mac. Try again. \n"
    exit 1
  fi
}

function check-useryml {
  if [[ -f $PERSONAL_FOLDER/user.yml ]]; then
    echo "user.yml was found in OneDrive, will sync with bootstrap-mac if OneDrive version newer."
    echo "\n"
    rsync -uq $PERSONAL_FOLDER/user.yml $BOOTSTRAP_MAC_PATH/vars/user.yml
  fi
}

function check-corporateyml {
  if [[ -f /tmp/corporate.yml ]]; then
    echo "corporate.yml was found in tmp directory, will sync with bootstrap-mac if version newer."
    echo "\n"
    # rsync -uq /tmp/corporate.yml $BOOTSTRAP_MAC_PATH/vars/corporate.yml
    cp /tmp/corporate.yml $BOOTSTRAP_MAC_PATH/vars/corporate.yml
  fi
}

#function check-keychain-password {
#  ANSIBLE_KEYCHAIN_PASS=1
#  ANSIBLE_KEYCHAIN_PASS_CHECK=$(security find-generic-password -a pj-bootstrap-ansible -w)
#  if [[ $ANSIBLE_KEYCHAIN_PASS_CHECK == "" ]]; then
#    security add-generic-password -a pj-bootstrap-ansible -s ansible -w "$(openssl rand -base64 25)"
#    ANSIBLE_KEYCHAIN_PASS_CHECK=$(security find-generic-password -a pj-bootstrap-ansible -w)
#  fi
#  if [[ $ANSIBLE_KEYCHAIN_PASS_CHECK == "" ]]; then
#    echo "function: check-keychain-password"
#    echo "The ephemeral password did not get created successfully in keychain, try again"
#    exit 1
#  fi
#  ANSIBLE_KEYCHAIN_PASS=0
#}

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
#  if [[ $POETRY_INSTALLED == 1 ]]; then
#    echo "function: check-ansible-readiness"
#    echo "Poetry must be installed before you can run bootstrap-mac"
#    exit 1
#  fi
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
#  if [[ $IT_SETUP_FOLDER_CHECK == 1 ]]; then
#    echo "function: check-ansible-readiness"
#    echo "IT Setup OneDrive folder must be synced before you can run bootstrap-mac"
#    exit 1
#  fi

  # Remove old bootstrap_mac folder if found
  if [[ -d $HOME/.pj/bootstrap_mac/ ]]; then
    rm -Rf $HOME/.pj/bootstrap_mac/
  fi

  # Create empty secrets and user vars files if not found
  cd $BOOTSTRAP_MAC_PATH
#  if [[ ! -f vars/secrets.yml ]]; then
#    echo "---" > vars/secrets.yml
#  fi
  if [[ ! -f vars/user.yml ]]; then
    echo "---" > vars/user.yml
  fi
  if [[ ! -f vars/corporate.yml ]]; then
    echo "---" > vars/corporate.yml
  fi

  # Check Poetry
  poetry install
  if [[ ! -f .venv/bin/python ]]; then
    echo "function: check-ansible-readiness"
    echo "Poetry Virtual Enviornment was not setup correctly, try again."
    exit 1
  fi

#  pull-ansiblecollections
#
#  if [[ ! -f $HOME/.ansible/collections/ansible_collections/pj/mac/MANIFEST.json ]]; then
#    echo "function: check-ansible-readiness"
#    echo "Ansible Collection was not installed correctly, try again."
#    exit 1
#  fi

  # If none of the above failed, we can assume bootstrap_mac can be ran
  ANSIBLE_READINESS=0
}

function check-become-password {
  BECOME_PASSWORD_CHECK=1
  # 1. Check is the ephemeral password in keychain was successfully created.
#  check-keychain-password
#  if [[ $ANSIBLE_KEYCHAIN_PASS == 1 ]]; then
#    exit 1
#  fi

  # 2. Ensure ansible-vault can be ran
  install-bootstrapmac
  check-ansible-readiness
  # Note: Should not get to this point if there was a failure, but adding just in case
  if [[ $ANSIBLE_READINESS == 1 ]]; then
    exit 1
  fi

  # 3. Change Directory
  cd $BOOTSTRAP_MAC_PATH

  # 4. If pass.yml does not exist, then ask user for it
#  if [[ ! -f vars/pass.yml ]]; then
#    echo -n Local Password:
#    read -s password
#    echo "\n"
#    echo "---" > vars/pass.yml
#    echo "ansible_become_password: $password" >> vars/pass.yml
#
#    echo `security find-generic-password -a pj-bootstrap-ansible -w` | poetry run ansible-vault encrypt vars/pass.yml
#  fi
#
#  # 5. Check to make sure become password is encrypted
#  if [[ $(poetry run ansible-vault view vars/pass.yml) == "" ]]; then
#    echo "function: check-become-password"
#    echo "Ansible-Vault wasn't able to encrypt your become password, try again."
#    exit 1
#  fi
  BECOME_PASSWORD_CHECK=0
}

function create-archive {
  CURRENT_DATE=$(date +%m-%d-%Y)
  ARCHIVE_FOLDER="$CURRENT_DATE-Archive"
  mkdir -p $HOME/$ARCHIVE_FOLDER
}

function create-userbackup {
  create-archive
  SN=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}' | sed 's/^[ \t]*//;s/[ \t]*$//')

  echo "Creating user backup... \n"
  tar --exclude='venv' --exclude='*.box' --exclude='__pycache__' --exclude='node_modules' \
  --exclude='[Bb]in' --exclude='[Oo]bj' --exclude='[Dd]ebug' --exclude='[Rr]elease' --exclude='x64'\
  --exclude='.venv' \
  -czf "$HOME/$ARCHIVE_FOLDER/$SN-backup.tar.gz" \
  -C $HOME \
  git/ .pj/bootstrap-mac/vars/user.yml .ssh/ "Library/Containers/com.microsoft.rdc.macos/Data/Library/Application Support/com.microsoft.rdc.macos"
}

function check-poetry {
  POETRY_WORKING=$(poetry --version > /dev/null;echo $?)
  if [[ $POETRY_WORKING != 0 ]]; then
     echo "There is an issue with Poetry, reinstalling...\n"
     curl -sSL https://install.python-poetry.org | python3 - --uninstall
     curl -sSL https://install.python-poetry.org | python3 -
  fi
}

function reset-dock {
  defaults write com.apple.dock persistent-apps -array
  killall Dock
}

function reset-become-password {
  rm -f $BOOTSTRAP_MAC_PATH/vars/pass.yml
}

function reset-onedrive {
  # Reset OneDrive
  /Applications/OneDrive.app/Contents/Resources/ResetOneDriveApp.command

  create-archive
  # Zip Archives
  if [[ -d "$HOME/OneDrive-PurpleJay (Archive)/" ]]; then
    echo "Zipping Personal OneDrive folder ... \n"
    zip -r "$HOME/OneDrive-PurpleJay (Archive).zip" "$HOME/OneDrive-PurpleJay (Archive)/"
    mv "$HOME/OneDrive-PurpleJay (Archive).zip" "$HOME/$ARCHIVE_FOLDER/"
    rm -Rf "$HOME/OneDrive-PurpleJay (Archive)/"
  fi
  if [[ -d "$HOME/OneDrive-SharedLibraries-PurpleJay (Archive)/" ]]; then
    echo "Zipping Shared Libraries OneDrive folder ... \n"
    zip -r "$HOME/OneDrive-SharedLibraries-PurpleJay (Archive).zip" "$HOME/OneDrive-SharedLibraries-PurpleJay (Archive)/"
    mv "$HOME/OneDrive-SharedLibraries-PurpleJay (Archive).zip" "$HOME/$ARCHIVE_FOLDER/"
    rm -Rf "$HOME/OneDrive-SharedLibraries-PurpleJay (Archive)/"
  fi

  # Remove symbolic links
  if [[ -L "$HOME/OneDrive - Purple Jay" ]]; then
    rm -f "$HOME/OneDrive - Purple Jay"
  fi
  if [[ -L "$HOME/Purple Jay" ]]; then
    rm -f "$HOME/Purple Jay"
  fi
}

function reset-nextcloud {
  pkill "Nextcloud"
  brew uninstall nextcloud

  if [[ -d "$HOME/Library/Application Support/Nextcloud/" ]]; then
    rm -Rf "$HOME/Library/Application Support/Nextcloud/"
  fi
  if [[ -d "$HOME/Library/Preferences/Nextcloud" ]]; then
    rm -Rf -d "$HOME/Library/Preferences/Nextcloud"
  fi
  rm -Rf "$HOME/Library/Group Containers/group.com.nextcloud.Talk"
  rm -Rf "$HOME/Library/Caches/com.nextcloud.desktopclient/"
  rm -Rf "$HOME/Library/Caches/Nextcloud/"

  create-archive

  if [[ -d "$HOME/Nextcloud/" ]]; then
    echo "Zipping Nexcloud folder ... \n"
    zip -r "$HOME/$ARCHIVE_FOLDER/nextcloud.zip" "$HOME/Nextcloud/"
    rm -Rf "$HOME/Nextcloud/"
  fi
}

function reset-teams {
  pkill "Microsoft Teams"
  sudo rm -Rf "/Applications/Microsoft Teams.app/"
  rm -Rf "$HOME/Library/Application Support/Microsoft/Teams/"
  rm -f "$HOME/Library/Preferences/com.microsoft.teams.plist"
  rm -Rf "$HOME/Library/Caches/com.microsoft.teams/"
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Teams/installTeams.sh)"
}

function reset-edge {
  pkill "Microsoft Edge"
  sudo rm -Rf "/Applications/Microsoft Edge.app/"
  rm -Rf "$HOME/Library/Application Support/Microsoft/EdgeUpdater/"
  rm -Rf "$HOME/Library/Application Support/Microsoft Edge/"
  rm -f "$HOME/Library/Preferences/com.microsoft.edgemac.plist"
  rm -Rf "$HOME/Library/Caches/Microsoft Edge/"
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Edge/installEdge.sh)"
}

function reset-poetry {
  # OLD_POETRY_INSTALLED=$(test -f $HOME/.poetry/bin/poetry;echo $?)
  # if [[ $OLD_POETRY_INSTALLED == 0 ]]; then
  curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 - --uninstall
  curl -sSL https://install.python-poetry.org | python3 - --uninstall
  rm -Rf $HOME/.pj/bootstrap-mac/.venv
  curl -sSL https://install.python-poetry.org | python3 -
  POETRY_INSTALLED=$(test -f $HOME/.local/bin/poetry;echo $?)
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

function reset-bootstrapmac {
  echo "About to remove bootstrap-mac, are you sure you want to continue?"
  # https://unix.stackexchange.com/questions/293940/how-can-i-make-press-any-key-to-continue
  read -r -s -k '?Press any key to continue.'
  sudo echo "You now have SUDO in this session"

  create-userbackup
  reset-nextcloud

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
  rm -Rf $HOME/.pj/bootstrap_mac/

  # Reset OneDrive
  reset-onedrive

  # Uninstall O365 Apps
  reset-teams
  reset-edge

  exit 1
}

function op-login {
  eval "$(op signin --account purplejayllc)"
  check_op=$(op account get)
  if [[ $check_op == "" ]];then
    echo "function: op-login"
    echo "You did not login into 1password, make sure you have enabled Biometric Unlock. \n"
    exit 1
  fi
  rm vars/secrets.yml
  export PULL_OP_SECRETS=true
}

function op-create {
  if [[ -f "op_create.sh" ]];then
    ./op_create.sh > /dev/null
  fi
  echo "Contact PJ Admin and let them know you have ran 'pj-op' successfully."
  echo "Your Wireguard public key will need to be added until you can connect.\n"
}

function pull-ansiblecollections {
  cd /tmp
  security find-certificate -c "purplejaynet-ca" -p > ca.pem
  openssl x509 -pubkey -noout -in ca.pem > pubkey.pem

  curl -O https://pjansiblecollections.blob.core.windows.net/pj-ansiblecollections/ansiblecollection_keyfile.key.enc
  curl -O https://pjansiblecollections.blob.core.windows.net/pj-ansiblecollections/pj-mac-1.0.0.tar.gz.enc
  curl -O https://pjansiblecollections.blob.core.windows.net/pj-ansiblecollections/pj-ubuntu-1.0.0.tar.gz.enc

  openssl rsautl -inkey pubkey.pem -pubin -in ansiblecollection_keyfile.key.enc -out ansiblecollection_keyfile.key
  openssl enc -in pj-mac-1.0.0.tar.gz.enc -out pj-mac-1.0.0.tar.gz -d -aes256 -k ansiblecollection_keyfile.key
  openssl enc -in pj-ubuntu-1.0.0.tar.gz.enc -out pj-ubuntu-1.0.0.tar.gz -d -aes256 -k ansiblecollection_keyfile.key

  rm ansiblecollection_keyfile.key.enc ansiblecollection_keyfile.key pj-mac-1.0.0.tar.gz.enc pj-ubuntu-1.0.0.tar.gz.enc
  rm ca.pem pubkey.pem

  cd $BOOTSTRAP_MAC_PATH
  poetry run ansible-galaxy collection install -r galaxy.yml --force
}


function display-help {
  echo "Usage: ./run.sh [Option]

  Options:
  install           Install Apps and Clones bootstrap-mac
  update            Runs bootstrap-mac and upgrades poetry
  noupdate          Runs bootstrap-mac minus homebrew playbooks
  password          Resets become password
  op                Runs op-cli secrets push/pull
  reset             Uninstall Apps and remove bootstrap-mac
  reset-edge        Reset Microsoft Edge
  reset-teams       Reset Microsoft Teams
  reset-onedrive    Reset Microsoft OneDrive
  reset-nextcloud   Reset Nextcloud
  create-backup     Backup user git, ssh, and user.yml
  "
  exit 1
}

########################################################################
#  Run Playbook
########################################################################

if [[ $# -gt 1 ]]; then
  display-help
fi

setup-venv

if [[ $1 == "install" ]]; then
  install-apps
  install-bootstrapmac
  cd ~/.pj/bootstrap-mac
  reset-dock

  FILEVAULT_CHECK=$(sudo fdesetup isactive)
  if [[ $FILEVAULT_CHECK != "true" ]]; then
    echo "Opening System Preferences, turn on Filevault before you proceed."
    open "x-apple.systempreferences:com.apple.preference.security?FileVault"
    read -r -s -k '?Press any key to continue.'
    echo "\n"
  fi

  echo "Opening Company Portal, ensure your device is compliant before continuing."
  open "/Applications/Company Portal.app"
  read -r -s -k '?Press any key to continue.'
  echo "\n"
#
#  open "/Applications/OneDrive.app"
#  echo "Opening OneDrive, log into your Office 365 account before continuing."
#  read -r -s -k '?Press any key to continue.'
#  echo "\n"
#
#  DEFAULT_BROWSER=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | sed -n -e '/LSHandlerURLScheme = https;/{x;p;d;}' -e 's/.*=[^"]"\(.*\)";/\1/g' -e x)
#  if [[ $DEFAULT_BROWSER != "com.microsoft.edgemac" ]]; then
#    open /System/Library/PreferencePanes/Appearance.prefPane
#    echo "Opening System Preferences, set the default browser to Microsoft Edge before continuing."
#    echo "Close the System Preferences Pane to ensure the default browser setting was saved."
#    read -r -s -k '?Press any key to continue.'
#    echo "\n"
#  fi
#  sleep 5
#  DEFAULT_BROWSER=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | sed -n -e '/LSHandlerURLScheme = https;/{x;p;d;}' -e 's/.*=[^"]"\(.*\)";/\1/g' -e x)
#  if [[ $DEFAULT_BROWSER != "com.microsoft.edgemac" ]]; then
#    echo "Set the default browser to Microsoft Edge before continuing. Exiting script now... "
#    open /System/Library/PreferencePanes/Appearance.prefPane
#    exit 1
#  fi
#
#  open "https://office.com"
#  echo "Opening Browser: https://office.com"
#  echo "Ensure you are logged into your Purple Jay Office365 Account before continuing."
#  read -r -s -k '?Press any key to continue.'
#  echo "\n"

#  open "https://purplejayio.sharepoint.com/sites/PurpleJay2/Shared%20Documents/Forms/AllItems.aspx"
#  echo "Opening Browser: https://purplejayio.sharepoint.com/sites/PurpleJay2/Shared%20Documents/Forms/AllItems.aspx"
#  echo "Sync Purple Jay Documents before continuing."
#  read -r -s -k '?Press any key to continue.'
#  echo "\n"
#  sleep 5

  check-become-password
  poetry run ansible-playbook local.yml -K

#  open "/Applications/1Password.app"
#  echo "Opening 1Password, enable 'Biometric unlock for 1Password CLI' in Preferences > Developer"
#  read -r -s -k '?Press any key to continue.'
#  echo "\n"
#
#  check-useryml
#  op-login
#  poetry run ansible-playbook local.yml
#  op-create

  exit 1
fi

if [[ $1 == "update" ]]; then
  prune-logs
  brew update
  brew upgrade
  check-poetry
  poetry self update
  check-corporateyml
  # check-useryml
  check-become-password
  ansible-playbook local.yml -K
  exit 1
fi

if [[ $1 == "check" ]]; then
  check-corporateyml
  check-become-password
  ansible-playbook local.yml -K --diff --check -vv
  exit 1
fi

if [[ $1 == "noupdate" ]]; then
  prune-logs
  check-become-password
  check-corporateyml
  # check-useryml
  poetry run ansible-playbook local.yml --skip-tags update -K
  exit 1
fi

#if [[ $1 == "password" ]]; then
#  reset-become-password
#  check-become-password
#  poetry run ansible-playbook local.yml --skip-tags update
#  exit 1
#fi
#
#if [[ $1 == "op" ]]; then
#  check-dir
#  check-become-password
#  op-login
#  poetry run ansible-playbook local.yml --skip-tags update
#  op-create
#  exit 1
#fi

if [[ $1 == "reset" ]]; then
  reset-bootstrapmac
  exit 1
fi

if [[ $1 == "reset-poetry" ]]; then
  reset-poetry
  install-poetry
  poetry install
  exit 1
fi

#if [[ $1 == "reset-edge" ]]; then
#  reset-edge
#  exit 1
#fi

if [[ $1 == "reset-teams" ]]; then
  reset-teams
  exit 1
fi

if [[ $1 == "reset-onedrive" ]]; then
  reset-onedrive
  exit 1
fi

#if [[ $1 == "reset-nextcloud" ]]; then
#  reset-nextcloud
#  exit 1
#fi

if [[ $1 == "create-backup" ]]; then
  create-userbackup
  exit 1
fi

display-help
