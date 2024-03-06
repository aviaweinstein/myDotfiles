setopt NO_CASE_GLOB
setopt AUTO_CD
# setopt CORRECT
# setopt CORRECT_ALL
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# share history across multiple zsh sessions
setopt SHARE_HISTORY
# append to history
setopt APPEND_HISTORY
# adds commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY
# expire duplicates first
setopt HIST_EXPIRE_DUPS_FIRST 
# do not store duplications
setopt HIST_IGNORE_DUPS
#ignore duplicates when searching
setopt HIST_FIND_NO_DUPS
# removes blank lines from history
setopt HIST_REDUCE_BLANKS
# shows the substituted command in the prompt when using !! for prev command
setopt HIST_VERIFY
# prompt string is first subjected to parameter expansion, command substitution and arithmetic expansion
setopt PROMPT_SUBST

# initializes the zsh completion system http://zsh.sourceforge.net/Doc/Release/Completion-System.html#Completion-System
autoload -Uz compinit && compinit
# case insensitive path-completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
# partial completion suggestions
zstyle ':completion:*' list-suffixeszstyle ':completion:*' expand prefix suffix
# load bashcompinit for some old bash completions
autoload bashcompinit && bashcompinit
[[ -r ~/Projects/autopkg_complete/autopkg ]] && source ~/Projects/autopkg_complete/autopkg

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

p() {
  autoload colors ; colors
  # local cur_cmd="${blue_op}%_${blue_cp}"
  # PROMPT2="${cur_cmd}> "

  local time_op="%F{yellow}"
  local whoami_op="%F{green}"
  local branch_op="%F{#005fff}"
  local dir_op="%F{cyan}"
  local end="%f"

  local time="${time_op}%D{%a %b %f %L:%M %p}${end}"
  local whoami="${whoami_op}%n@%m${end}"
  local dir="${dir_op}%~${end}"
  local parsed_git_branch=$(parse_git_branch)
  local branch
  if test $parsed_git_branch ; then
    branch=" ${branch_op}$(parse_git_branch)${end}"
  else
    unset branch
  fi

  local last_status=$?
  local last_fail
  if test $last_status -ne 0 ; then
    last_fail="=> %F{yellow}Err: $last_status${end}\n"
  else
    unset last_fail
  fi

  echo "$time $whoami$branch $dir
$last_fail${end}\$ "
}

PROMPT='$(p)'
# retain $PROMPT_DIRTRIM directory components when the prompt is too long
PROMPT_DIRTRIM=3

## Set up $dotfiles directory
# returns true if the program is installed
installed() {
  hash "$1" >/dev/null 2>&1
}

# OSX `readlink` doesn't support the `-f` option (-f = follow components to make full path)
# If `greadlink` is installed, use it
# Otherwise, use the dir and basename provided to construct a sufficient stand-in
relative_readlink() {
  local dir="$1" base="$2"
  if installed greadlink ; then
    dirname "$(greadlink -f "$dir/$base")"
  elif pushd "$dir" >/dev/null 2>&1 ; then
    local link="$(readlink "$base")"
    case "$link" in
      /*) dirname "$link" ;;
      *) pushd "$(dirname "$link")" >/dev/null 2>&1 ; pwd -P ; popd >/dev/null ;;
    esac
    popd >/dev/null
  fi
}

if [[ -L "$HOME/.bash_profile" ]] ; then
  dotfiles="$(relative_readlink "$HOME" .bash_profile)"
fi

if [[ -z "$dotfiles" ]] || [[ ! -d "$dotfiles" ]] ; then
  #warn "~/.bash_profile should be a link to .bash_profile in the dotfiles repo"
  dotfiles=$HOME/Code/dotfiles
fi

# Finish if we couldn't find our root directory
if [[ -z "$dotfiles" ]] || [[ ! -d "$dotfiles" ]] ; then
  echo "Couldn't find root of dotfiles directory. Exiting .bash_profile early."
  return
fi

export DOTFILES="$dotfiles"

. $dotfiles/app-navigation.bash

# Load completion files from $dotfiles/completion/{function}.bash
for script in "$dotfiles/completion/"*.bash ; do
  . "$script" > /dev/null 2>&1
done

. $dotfiles/.aliases

# Bindings
bindkey "^R" history-incremental-search-backward
bindkey "\e[A" history-beginning-search-backward
bindkey "\e[B" history-beginning-search-forward
