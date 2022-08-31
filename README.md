# bootstrap_mac

## Install O365 Apps

``` bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/intune_o365.sh)"
```

## Install bootstrap-mac

``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh install
```

## Uninstall bootstrap-mac
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh reset
```