# bootstrap_mac

## Setup bootstrap-mac

``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh install
```

## Reset bootstrap-mac
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh reset
```

## Beta Testing

Install
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/beta/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh install
```

Reset
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/beta/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh reset
```