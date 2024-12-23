# Purple Jay Bootstrap Mac README

1. Install [Homebrew](https://brew.sh/)
2. `brew install python@3.12 uv yq`

3. Run the following
    ``` bash
    /bin/zsh -c "sudo echo 'sudo'" && rm -fr /tmp/bootstrap-mac && git clone -b main https://github.com/purplejay-io/bootstrap-mac /tmp/bootstrap-mac && caffeinate -d /tmp/bootstrap-mac/run.sh install
    ```
