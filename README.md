# Purple Jay Bootstrap Mac README

#TODO - Move to dev docs. 
``` bash
/bin/zsh -c "sudo echo 'sudo'" && rm -fr /tmp/bootstrap-mac && git clone -b remove-poetry https://github.com/purplejay-io/bootstrap-mac /tmp/bootstrap-mac && caffeinate -d /tmp/bootstrap-mac/run.sh install
```

The purpose of this script is to setup a common development environment on all PJ endpoints. 
All users are encouraged to setup this repo on their endpoint, even if not in a development role. 

Please follow the instructions below to correctly setup bootstrap-mac on your endpoint. 

1. Confirm you able to access the [bootstrap-mac repo](https://gitlab.purplejay.net/purple-jay/bootstrap-mac/)
2. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
3. Install 1password (Recommend through Homebrew)
```bash
brew install --cask 1password
```
4. Confirm your SSH key is setup with Gitlab. 
* GitLab -> Profile -> Preferences -> SSH Keys
5. Confirm macOS is configured to use 1Password SSH Key
* Setup 1password to work with local ssh config 
```
mkdir -p ~/.ssh/
echo "Host *
  IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"" > ~/.ssh/config
```
* 1Password -> Settings -> Developer -> Use the SSH agent

5. Run the following command in a terminal.
```bash
mkdir -p "$HOME"/.pj
git clone git@gitlab.purplejay.net:purple-jay/bootstrap-mac.git "$HOME"/.pj/bootstrap-mac/
cd "$HOME"/.pj/bootstrap-mac/ ; ./run.sh install
```

#TODO - Refactor uninstall script
## Uninstall bootstrap-mac
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh reset
```
