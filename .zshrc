# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Theme
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# Zinit setup
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Tmuxifier setup
TMUXIFIER_HOME="${HOME}/.tmuxifier"

if [ ! -d "$TMUXIFIER_HOME" ]; then
   mkdir -p "$(dirname $TMUXIFIER_HOME)"
   git clone https://github.com/jimeh/tmuxifier.git "$TMUXIFIER_HOME"
fi

# Add Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode
zinit light Aloxaf/fzf-tab

zinit wait lucid for MichaelAquilina/zsh-autoswitch-virtualenv

# Zsh snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=auto $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons=auto $realpath'

# Exports
export PATH="$HOME/.tmuxifier/bin/:$PATH"
export EDITOR='nvim'

# Aliases
alias ls='eza --icons=auto'
alias lh='eza --icons=auto -lha'
alias la='eza --icons=auto -la'
alias vi="nvim"
alias vim="nvim"
alias c="clear"
alias tx="tmuxifier load-session"
alias y="yazi"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(tmuxifier init -)"

# Directory for client-specific scripts
SOURCE_DIRS=("$HOME/.zsh-scripts" "$HOME/.zsh-secrets")

for DIR in "${SOURCE_DIRS[@]}"; do
  # Check if the directory exists
  if [ -d "$DIR" ]; then
    # Loop through all the shell scripts in the directory
    for FILE in "$DIR"/*.sh; do
      # Check if the script file exists
      if [ -f "$FILE" ]; then
        # Source the script
        source "$FILE"
      fi
    done
  fi
done

# Source OS-specific files
os_name=$(uname | tr '[:upper:]' '[:lower:]')
os_source="$HOME/.zsh-$os_name.sh"

if [ -f "$os_source" ]; then
  source "$os_source"
fi
