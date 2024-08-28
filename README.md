# Purple Jay Bootstrap Mac README

``` bash
/bin/zsh -c "sudo echo 'sudo'" && rm -fr /tmp/bootstrap-mac && git clone -b main https://github.com/purplejay-io/bootstrap-mac /tmp/bootstrap-mac && caffeinate -d /tmp/bootstrap-mac/run.sh install
```

#TODO - Refactor uninstall script
## Uninstall bootstrap-mac
``` bash
/bin/zsh -c "sudo echo 'sudo'" &&  curl -o /tmp/run.sh https://raw.githubusercontent.com/purplejay-io/bootstrap-mac/main/run.sh && chmod +x /tmp/run.sh && caffeinate -d /tmp/run.sh reset
```
