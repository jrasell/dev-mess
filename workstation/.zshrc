# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="eastwood"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Ensure Go binaries are included in the path.
export GOPATH=$HOME/.go
export GOBIN=$HOME/.go/bin/
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

# Load our custom functions.
fpath=( ~/.zshfn "${fpath[@]}" )
autoload -Uz $fpath[1]/*(.:t)

alias gpo='git push origin "$(git symbolic-ref --short HEAD)"'
alias gpfo='git push -f origin "$(git symbolic-ref --short HEAD)"'
