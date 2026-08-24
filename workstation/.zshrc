# Ensure Go binaries are included in the path.
export GOPATH=$HOME/.go
export GOBIN=$HOME/.go/bin/
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

# Load our custom functions.
fpath=( ~/.zshfn "${fpath[@]}" )
autoload -Uz $fpath[1]/*(.:t)

alias gpo='git push origin "$(git symbolic-ref --short HEAD)"'
alias gpfo='git push -f origin "$(git symbolic-ref --short HEAD)"'

# Load direnv if installed, for per-project environment variables.
eval "$(direnv hook zsh)"

# Add our bat alias to replace cat.
alias cat='bat --paging=never'

# Initialize Starship
eval "$(starship init zsh)"

# Initialize Mise
eval "$(/Users/jrasell/.local/bin/mise activate zsh)"
