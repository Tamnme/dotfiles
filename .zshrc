# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#starship theme
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship.toml

plugins=(aws terraform git kubectl)

source $ZSH/oh-my-zsh.sh

# Alias
alias kgp="kubecolor get pods"
alias kgn="kubecolor get nodes"
alias kgs="kubecolor get service"
alias kgpv="kubecolor get pv"
alias kgpvc="kubecolor get pvc"
alias kd="kubecolor describe"
alias kns="kubie ns"
alias kcx="kubie ctx"
alias pod-check="kgp -A -o wide | grep -v Running | grep -v Comp"
alias pod-count="kgp -A | wc -l"
alias k="kubecolor"

## Atuin
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^r' atuin-search

## Zsh Auto Complete
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey '^I' autosuggest-accept
bindkey '^I' complete-word

# Make completion work with kubecolor
compdef kubecolor=kubectl
compdef terragrunt=terraform
