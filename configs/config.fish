set -gx SHELL /opt/homebrew/bin/fish

##-------- Nix / nix-darwin PATH
# nix-darwin installs darwin-rebuild under /run/current-system/sw/bin.
# Nix daemon profile lives under /nix/var/nix/profiles/default/bin.
for p in /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
    test -d $p; and fish_add_path -gp $p
end

##--------- Greeting
if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
    fastfetch
end

##-------- Setup brew
starship init fish | source

set -Ux EDITOR nvim

##-------- Mise (replaces nvm, pyenv, etc)
if type -q mise
    mise activate fish | source
end

##-------- Completion wrappers
complete -c kubecolor  -w kubectl
complete -c terragrunt -w terraform

##-------- Kubernetes abbreviations
abbr -ag k     kubecolor
abbr -ag kgp   'kubecolor get pods'
abbr -ag kgn   'kubecolor get nodes'
abbr -ag kgs   'kubecolor get service'
abbr -ag kgpv  'kubecolor get pv'
abbr -ag kgpvc 'kubecolor get pvc'
abbr -ag kd    'kubecolor describe'
abbr -ag kns   'kubie ns'
abbr -ag kcx   'kubie ctx'

##-------- Aliases (need pipes — not abbr-able)
alias pod-check "kubecolor get pods -A -o wide | grep -v Running | grep -v Comp"
alias pod-count "kubecolor get pods -A | wc -l"

##-------- Tool replacements
if type -q bat
  abbr --add -g cat 'bat'
end

if type -q trash
  abbr --add -g rm 'trash'
end

if type -q nvim
  abbr --add -g vi 'nvim'
end

##-------- AI: Serena-wrapped gemini
function gemini-serena
    set -l project_root (git rev-parse --show-toplevel 2>/dev/null; or pwd)
    echo "🪝 Serena ON | $project_root"
    USE_SERENA=true SERENA_ROOT=$project_root gemini $argv
end

##-------- fzf → $EDITOR picker (Ctrl+E)
function fzf_edit --description "Pick file with fzf, open in \$EDITOR"
    set -l finder
    if type -q fd
        set finder fd --type f --hidden --exclude .git
    else
        set finder find . -type f -not -path '*/.git/*'
    end
    set -l file ($finder | fzf --height 60% --reverse \
        --preview 'bat --style=numbers --color=always {} 2>/dev/null; or cat {}')
    if test -n "$file"
        $EDITOR $file
    end
    commandline -f repaint
end

bind \ce fzf_edit

##-------- Option+Left/Right → word jump (zellij passes Alt+Arrow through)
bind \e\[1\;3D backward-word
bind \e\[1\;3C forward-word
bind \eb backward-word
bind \ef forward-word

##-------- Color scheme (requires h-matsuo/fish-color-scheme-switcher)
scheme set catppuccin
