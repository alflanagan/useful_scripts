#!/usr/bin/env bash

gitconfig() {
  if [[ $# -eq 2 ]]; then
    git config --global --add "$1" "$2"
  else
    echo "gitconfig() requires 2 arguments, got $#!" >&2
    exit 1
  fi
}

if [[ $(hostname) =~ wme.* ]]; then
  gitconfig user.email aflanagan@bhmginc.com
  gitconfig user.name "Adrian (Lloyd) Flanagan"
else
  gitconfig user.email a.lloyd.flanagan@gmail.com
  gitconfig user.name "A. Lloyd Flanagan"
fi

gitconfig credential.helper 'cache --timeout=3600'
gitconfig push.default simple
gitconfig "alias.undo-commit" 'reset --soft @^'
gitconfig core.autocrlf input
