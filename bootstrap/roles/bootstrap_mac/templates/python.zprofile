function venv {
  if [[ -d ".venv" ]]; then
     rm -Rf .venv
  fi
  uv venv
  pip-install
  v
}

function pip-install {
  if [[ -f "requirements-dev.txt" ]]; then
    uv pip install -r "requirements-dev.txt" -p ".venv"
  elif [[ -f "requirements.txt" ]]; then
    uv pip install -r "requirements.txt" -p ".venv"
  else
    pipc
  fi
}

function pipc {
  if [[ -f "pyproject.toml" ]]; then
    uv pip compile --no-emit-index-url --strip-extras --output-file=requirements.txt pyproject.toml
    uv pip compile --no-emit-index-url --extra=test --output-file=requirements-test.txt pyproject.toml
    uv pip compile --no-emit-index-url --extra=test --extra=dev --output-file=requirements-dev.txt pyproject.toml

    pip-install
  elif [[ -f "requirements.in" ]]; then
    uv pip compile --no-emit-index-url --output-file=requirements.txt requirements.in

    pip-install
  else
    echo "No requirements.in or pyproject.toml file found"
  fi
}

function v {
  if [[ -d ".venv" ]]; then
    . .venv/bin/activate
  fi
}
