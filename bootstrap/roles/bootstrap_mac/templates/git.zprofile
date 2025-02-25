export GIT_HOME="$HOME/git"

export CDPATH="$GIT_HOME"

function gitd {
  cd "$GIT_HOME" || echo "No git directory"
}

function gitsub {
  if [[ -f ".gitmodules" ]]; then
    git submodule sync --recursive
    git submodule update --init --recursive --remote
  fi
}