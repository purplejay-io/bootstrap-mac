function gitd {
  cd "$HOME/git/" || echo "No git directory"
}

function gitsub {
  if [[ -f ".gitmodules" ]]; then
    git submodule sync --recursive
    git submodule update --init --recursive --remote
  fi
}