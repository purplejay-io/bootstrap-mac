Set-Alias -Name python -Value python3
{% if gitlab_api_token != "please_update_user_yml" %}
$env:UV_EXTRA_INDEX_URL = "https://__token__:{{ gitlab_api_token }}@gitlab.purplejay.net/api/v4/groups/205/-/packages/pypi/simple"
{% endif %}
$env:UV_NATIVE_TLS = "true"

function RefreshEnv
{
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | ForEach-Object {
        if ( [System.IO.File]::Exists($_))
        {
            Write-Verbose -Verbose "Running $_"
            . $_
        }
    }
}

function v
{
    & "./.venv/bin/activate.ps1"
}

function pipc
{
    $cwd = $( Get-Location )
    if (![System.IO.File]::Exists("$cwd/requirements.in") -and ![System.IO.File]::Exists("$cwd/pyproject.toml"))
    {
        Write-Output "No requirements.in or pyproject.toml file found"
        return
    }

    if ( [System.IO.File]::Exists("$cwd/pyproject.toml"))
    {
        uv pip compile --no-emit-index-url --strip-extras --output-file=requirements.txt pyproject.toml
        uv pip compile --no-emit-index-url --extra=test --output-file=requirements-test.txt pyproject.toml
        uv pip compile --no-emit-index-url --extra=test --extra=dev --output-file=requirements-dev.txt pyproject.toml
    }
    else
    {
        uv pip compile --no-emit-index-url --output-file=requirements.txt requirements.in
    }
}

function venv
{
    if (!([System.IO.Directory]::Exists(".venv")))
    {
        uv venv
    }
    v
    pip-install
}

function pip-install
{
    $cwd = $( Get-Location )
    if (![System.IO.File]::Exists("$cwd/pyproject.toml") -and ![System.IO.File]::Exists("$cwd/requirements.in"))
    {
        write-output "No requirements found"
    }
    else
    {
        v
    }

    if ( [System.IO.File]::Exists("$cwd/pyproject.toml"))
    {
        uv pip install -r "$cwd/pyproject.toml" -p "$cwd/.venv"
        uv pip install -r "$cwd/pyproject.toml" -p "$cwd/.venv" --extra dev
    }
    else
    {
        uv pip install -r "$cwd/requirements.in" -p "$cwd/.venv"
    }

}
