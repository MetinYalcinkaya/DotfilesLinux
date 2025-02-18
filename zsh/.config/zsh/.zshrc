# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

###########
# History #
###########

HIST_STAMPS="yyyy/mm/dd"
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
export HISTSIZE=10000
export SAVEHIST=10000
export SHELL_SESSIONS_DISABLE=1

###############
# Environment #
###############
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"
export HYPRSHOT_DIR=~/Pictures/
export TERM=ghostty
export CLICOLOR=1

# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# Bat colorscheme
# export BAT_THEME="Catppuccin-Mocha"

############
# Ruby Env #
############
# if [ -d "/opt/homebrew/opt/ruby/bin/" ]; then
#   export PATH=/opt/homebrew/opt/ruby/bin:$PATH
#   export PATH='gem environment gemdir'/bin:$PATH
# fi

###########
# Keymaps #
###########
# vi mode
bindkey -v
# tmux sessionizer keybind (ctrl+f)
bindkey -s ^f "tmux-sessionizer\n"
# Use fd instead of fzf
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

############
# Sourcing #
############
typeset -a sources
sources+="$ZDOTDIR/aliases/aliases" # Aliases
sources+="$ZDOTDIR/scripts/uvsh"
# Plugins
sources+="$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" # Syntax highlighting
sources+="$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" # Autosuggestions
# Prompt
sources+="$ZDOTDIR/themes/powerlevel10k/powerlevel10k.zsh-theme"

for file in $sources[@]; do
  if [[ -a "$file" ]]; then
    source "$file"
  fi
done

#######
# FZF #
#######
source <(fzf --zsh)
# For ** functionality
# E.g.: cd ** {tab}, nvim ** {tab}
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}
autoload -Uz compinit && compinit

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
# export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

export PATH=$PATH:/home/metin/.spicetify

# bun completions
[ -s "/home/metin/.bun/_bun" ] && source "/home/metin/.bun/_bun"

# Created by `pipx` on 2024-12-13 07:43:17
export PATH="$PATH:/home/metin/.local/bin"

eval "$(uv generate-shell-completion zsh)"
