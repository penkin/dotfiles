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
export EDITOR='nvim'

# Aliases
alias ls='eza --icons=auto'
alias lh='eza --icons=auto -lha'
alias la='eza --icons=auto -la'
alias vi="nvim"
alias vim="nvim"
alias c="clear"
alias y="yazi"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Directory for client-specific scripts
SOURCE_DIRS=("$HOME/.zsh_scripts" "$HOME/.zsh_secrets")

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

# Add scritps in the scripts folder to the path.
export PATH="$HOME/scripts:$PATH"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/penkin/sandbox/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/penkin/sandbox/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/penkin/sandbox/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/penkin/sandbox/google-cloud-sdk/completion.zsh.inc'; fi

# Add neovim mason bin to the PATH.
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

# Set up dotnet if installed via asdf
if command -v asdf &> /dev/null; then
    DOTNET_ROOT_PATH="$(asdf where dotnet 2>/dev/null)"

    if [ -n "$DOTNET_ROOT_PATH" ]; then
        export DOTNET_ROOT="$DOTNET_ROOT_PATH"
        export PATH="$PATH:$HOME/.dotnet/tools"
    fi
fi
