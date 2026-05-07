# Theme (zsh-syntax-highlighting Catppuccin)
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# Powerlevel10k instant prompt — must stay near the top.
# Initialization that may require console input (passwords, prompts) goes
# above this block; everything else goes below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zinit setup
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode
zinit light Aloxaf/fzf-tab

zinit wait lucid for MichaelAquilina/zsh-autoswitch-virtualenv

# Generic OMZ snippets (distro-specific ones live in OS fragments)
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

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
export EDITOR='nvim'
export GPG_TTY=$(tty)

# Aliases
alias ls='eza --icons=auto'
alias lh='eza --icons=auto -lha'
alias la='eza --icons=auto -la'
alias vi="nvim"
alias vim="nvim"
alias c="clear"
alias y="yazi"

# Source any user scripts and secrets
SOURCE_DIRS=("$HOME/.zsh_scripts" "$HOME/.zsh_secrets")
for DIR in "${SOURCE_DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    for FILE in "$DIR"/*.sh; do
      [ -f "$FILE" ] && source "$FILE"
    done
  fi
done

# OS / distro detection — selects the right shell fragment.
case "$OSTYPE" in
  darwin*)
    DOTFILES_OS="darwin"
    ;;
  linux*)
    DOTFILES_OS="linux"
    if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *arch*)              DOTFILES_OS="linux-arch" ;;
        *debian*|*ubuntu*)   DOTFILES_OS="linux-debian" ;;
      esac
    fi
    ;;
esac

[[ -r "$HOME/.zsh-${DOTFILES_OS}.sh" ]] && source "$HOME/.zsh-${DOTFILES_OS}.sh"

# Machine-local fragment (gitignored, holds gcloud paths, work aliases, etc.)
[[ -r "$HOME/.zsh-local.sh" ]] && source "$HOME/.zsh-local.sh"

# PATH — consolidated. Add scripts in the scripts folder, neovim/Mason bins,
# and ~/.local/bin to PATH.
path=(
  "$HOME/scripts"
  "$HOME/.local/bin"
  $path
  "$HOME/.local/share/nvim/mason/bin"
)
export PATH

# OPENSPEC:START
fpath=("$HOME/.zsh/completions" $fpath)
# OPENSPEC:END

# Load completions (single compinit, after zinit plugins and fpath additions)
autoload -U compinit && compinit
zinit cdreplay -q

# Shell integrations (must be at the end of .zshrc)
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
