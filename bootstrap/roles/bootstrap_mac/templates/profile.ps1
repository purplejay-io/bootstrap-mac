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

function Venv
{
    & "./.venv/bin/activate.ps1"
}

function CreatePipRequirements
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

function SetupVenv
{
    CreatePipRequirements
    if (!([System.IO.Directory]::Exists(".venv")))
    {
        uv venv
    }
    Venv
    InstallRequirements
}

function InstallRequirements
{
    $cwd = $( Get-Location )
    if (![System.IO.File]::Exists("$cwd/requirements.txt") -or !([System.IO.Directory]::Exists("$cwd/.venv")))
    {
        SetupVenv
    }
    else
    {
        Venv
    }

    if ( [System.IO.File]::Exists("$cwd/requirements-dev.txt"))
    {
        uv pip install -r "$cwd/requirements-dev.txt" -p "$cwd/.venv"
    }
    else
    {
        uv pip install -r "$cwd/requirements.txt" -p "$cwd/.venv"
    }

}

#TODO: look to deprecate k8s functions
function CreateK8sDashboardToken
{
    $token = $( ssh pj-n1 -t "microk8s.kubectl create token default --duration 720h" )
    op item edit --vault private "pj k8s cluster dashboard" "password=$token"
    Set-Clipboard -Value "$token"
}

function CreateK8sDevDashboardToken
{
    $token = $( ssh dev-n1 -t "microk8s.kubectl create token default --duration 720h" )
    op item edit --vault private "pj k8s cluster dashboard" "password=$token"
    Set-Clipboard -Value "$token"
}

function K8sDashboardToken
{
    op read "op://private/pj k8s cluster dashboard/password" | Set-Clipboard
}

function K8sDevDashboardToken
{
    op read "op://private/pj k8s cluster dashboard/dev-token" | Set-Clipboard
}
