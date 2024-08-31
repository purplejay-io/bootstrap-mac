HOMEBREW_PATH="$(brew --prefix)"

{{ lookup("template", "templates/yk_functions.zprofile") }}
{{ lookup("template", "templates/python.zprofile") }}
{{ lookup("template", "templates/git.zprofile") }}
{{ lookup("template", "templates/parallels.zprofile") }}
