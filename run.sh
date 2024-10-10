#!/bin/zsh

########################################################################
#  Collect System Facts
########################################################################

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
PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3.12;echo $?)

# Is yq Installed
YQ_INSTALLED=$(test -f $HOMEBREW_PATH/bin/yq;echo $?)

# Is bootstrap_mac repo synced on mac?
BOOTSTRAP_MAC_PATH="${2:-$HOME/.pj/bootstrap-mac/}"
printf "Bootstrap Mac Path %s\n" "$BOOTSTRAP_MAC_PATH"

BOOTSTRAP_MAC_REPO=$(test -d "$BOOTSTRAP_MAC_PATH"/.git/;echo $?)

# Personal OneDrive Folder
PERSONAL_FOLDER="$HOME/Library/CloudStorage/OneDrive-PurpleJay"

LOCAL_VAULT_PASS_FILE="$HOME/.pj-bootstrap-ansible.txt"

########################################################################
#  Define Functions
########################################################################

function install-homebrew {
  if [[ $HOMEBREW_INSTALLED == 1 ]]; then
    # NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    HOMEBREW_INSTALLED=$(test -f $HOMEBREW_PATH/bin/brew;echo $?)
    if [[ $(uname -m) == 'arm64' ]]; then
      # shellcheck disable=SC2016
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    else
      sudo chown -R "$(whoami)" /usr/local/share/zsh /usr/local/share/zsh/site-functions
      chmod u+w /usr/local/share/zsh /usr/local/share/zsh/site-functions
    fi
  fi
  if [[ $HOMEBREW_INSTALLED != 0 ]]; then
    echo "function: install-homebrew"
    display-msg "Homebrew did not install successfully, try again."
    exit 1
  fi
}

function install-python {
  if [[ $HOMEBREW_INSTALLED == 0 && $PYTHON_INSTALLED == 1 ]]; then
    brew install python@3.12 uv
    $HOMEBREW_PATH/bin/python3.12 -m pip install pip --upgrade
    PYTHON_INSTALLED=$(test -f $HOMEBREW_PATH/bin/python3.12;echo $?)
  fi
  if [[ $PYTHON_INSTALLED != 0 ]]; then
    echo "function: install-python"
    display-msg "Python 3.12 did not install successfully, try again."
    exit 1
  fi
}

function install-yq {
  if [[ $HOMEBREW_INSTALLED == 0 && $YQ_INSTALLED == 1 ]]; then
    brew install yq
    YQ_INSTALLED=$(test -f $HOMEBREW_PATH/bin/yq;echo $?)
  fi
  if [[ $YQ_INSTALLED != 0 ]]; then
    echo "function: install-yq"
    display-msg "yq did not install successfully, try again."
    exit 1
  fi
}

function setup-venv {
  cd "$BOOTSTRAP_MAC_PATH" || exit 1
  rm -fr .venv
  uv venv
  . .venv/bin/activate
  check-venv
  uv pip install -r requirements.txt
}

function reset-venv {
  rm -Rf "$BOOTSTRAP_MAC_PATH/.venv"
  setup-venv
}

function activate-venv {
  setup-venv
  . "$BOOTSTRAP_MAC_PATH/.venv/bin/activate"
  check-venv
}

function check-venv {
  if [[ -z "$VIRTUAL_ENV" ]] && [[ "$VIRTUAL_ENV" == "" ]]; then
    display-msg "Something failed in activating the venv, try again."
    exit 1
  fi
}

function install-bootstrapmac {
    if [[ $HOMEBREW_INSTALLED == 1 ]]; then
      echo "function: install-bootstrapmac"
      display-msg "Homebrew is not installed"
      exit 1
    fi

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

function install-apps {
  install-homebrew
  install-python
  install-yq
}

function display-msg {
  msg=$1

  osascript -e "display dialog \"$msg\" with title \"Bootstrap Mac Alert\" buttons {\"OK\"} default button \"OK\""
}

function check-useryml {
  # shellcheck disable=SC2317
  if [[ -f "$PERSONAL_FOLDER/user.yml" ]]; then
    echo "user.yml was found in OneDrive, will sync with bootstrap-mac if OneDrive version newer."
    printf "\n"
    rsync -uq "$PERSONAL_FOLDER"/user.yml "$BOOTSTRAP_MAC_PATH"/vars/user.yml
  fi
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
  if [[ $HOMEBREW_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    display-msg "Homebrew must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $PYTHON_INSTALLED == 1 ]]; then
    echo "function: check-ansible-readiness"
    display-msg "Python 3.12 must be installed before you can run bootstrap-mac"
    exit 1
  fi
  if [[ $BOOTSTRAP_MAC_REPO == 1 ]]; then
    echo "function: check-ansible-readiness"
    display-msg "bootstrap-mac repo must be cloned locally before you can run bootstrap-mac"
    exit 1
  fi

  # Remove old bootstrap_mac folder if found
  if [[ -d $HOME/.pj/bootstrap_mac/ ]]; then
    rm -Rf "$HOME"/.pj/bootstrap_mac/
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

    echo `security find-generic-password -a pj-bootstrap-ansible -w` | ansible-vault encrypt --vault-password-file "$LOCAL_VAULT_PASS_FILE" vars/pass.yml
  fi

  # 6. Check to make sure become password is encrypted
  if [[ $(ansible-vault view vars/pass.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE" ) == "" ]]; then
    echo "function: check-become-password"
    display-msg "Ansible-Vault wasn't able to encrypt your become password, try again."
    exit 1
  fi
  BECOME_PASSWORD_CHECK=0
}

function create-archive {
  CURRENT_DATE=$(date +%m-%d-%Y)
  ARCHIVE_FOLDER="$CURRENT_DATE-Archive"
  mkdir -p "$HOME/$ARCHIVE_FOLDER"
}

function create-userbackup {
  create-archive
  SN=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}' | sed 's/^[ \t]*//;s/[ \t]*$//')

  echo "Creating user backup... \n"
  tar --exclude='venv' --exclude='*.box' --exclude='__pycache__' --exclude='node_modules' \
  --exclude='[Bb]in' --exclude='[Oo]bj' --exclude='[Dd]ebug' --exclude='[Rr]elease' --exclude='x64'\
  --exclude='.venv' \
  -czf "$HOME/$ARCHIVE_FOLDER/$SN-backup.tar.gz" \
  -C "$HOME" \
  git/ "$BOOTSTRAP_MAC_PATH"/vars/user.yml .ssh/ "Library/Containers/com.microsoft.rdc.macos/Data/Library/Application Support/com.microsoft.rdc.macos"
}

function reset-dock {
  defaults write com.apple.dock persistent-apps -array
  killall Dock
}

function reset-become-password {
  security delete-generic-password -a pj-bootstrap-ansible
  rm -f "$BOOTSTRAP_MAC_PATH"/vars/pass.yml
  rm -f "$LOCAL_VAULT_PASS_FILE"
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


function display-help {
  display-msg "Usage: ./run.sh [Option] [Path]

  Options:
  install           Install Apps and Clones bootstrap-mac
  update            Runs bootstrap-mac and upgrades poetry
  noupdate          Runs bootstrap-mac minus homebrew playbooks
  reset-password    Resets become password
  reset             Uninstall Apps and remove bootstrap-mac
  reset-venv        Reset Python Virtual Environment
  reset-edge        Reset Microsoft Edge
  reset-teams       Reset Microsoft Teams
  reset-onedrive    Reset Microsoft OneDrive
  reset-nextcloud   Reset Nextcloud
  create-backup     Backup user git, ssh, and user.yml

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
  install-apps
  install-bootstrapmac
  cd "$BOOTSTRAP_MAC_PATH" || (display-msg "error going to bootstrap mac path"; exit 1)
  reset-dock

  setup-venv
  check-become-password

  FILEVAULT_CHECK=$(ansible-vault view "$BOOTSTRAP_MAC_PATH"/vars/pass.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE" | yq -r '.ansible_become_password' | sudo -S fdesetup isactive)
  if [[ $FILEVAULT_CHECK != "true" ]]; then
    echo "Opening System Preferences, turn on Filevault before you proceed."
    open "x-apple.systempreferences:com.apple.preference.security?FileVault"
    read -r -s -k '?Press any key to continue.'
    printf "\n"
  fi

  echo "Opening Company Portal, ensure your device is compliant before continuing."
  open "/Applications/Company Portal.app"
  read -r -s -k '?Press any key to continue.'
  printf "\n"

  ansible-playbook local.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE"

  exit 1
fi

if [[ $1 == "update" ]]; then
  prune-logs
  brew update
  brew upgrade
  activate-venv
  check-become-password
  ansible-playbook local.yml --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "check" ]]; then
  activate-venv
  check-become-password
  ansible-playbook local.yml --diff --check -vv --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "noupdate" ]]; then
  prune-logs
  activate-venv
  check-become-password
  ansible-playbook local.yml --skip-tags update --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "reset-password" ]]; then
  activate-venv
  reset-become-password
  check-become-password
  ansible-playbook local.yml --skip-tags update --vault-password-file "$LOCAL_VAULT_PASS_FILE"
  exit 1
fi

if [[ $1 == "reset" ]]; then
  reset-bootstrapmac
  exit 1
fi

if [[ $1 == "reset-venv" ]]; then
  reset-venv
  exit 1
fi

if [[ $1 == "reset-teams" ]]; then
  reset-teams
  exit 1
fi

if [[ $1 == "reset-onedrive" ]]; then
  reset-onedrive
  exit 1
fi

if [[ $1 == "create-backup" ]]; then
  create-userbackup
  exit 1
fi

display-help
