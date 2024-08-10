# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

plugins=(
  git
  colorize
  brew
  macos
)

source $ZSH/oh-my-zsh.sh

#bindkey "[D" backward-word
#bindkey "[C" forward-word
#bindkey "^[a" beginning-of-line
#bindkey "^[e" end-of-line

alias bru="brew update; brew upgrade; brew cleanup --prune=all"
alias lpreset="defaults write com.apple.dock ResetLaunchPad -bool true; killall Dock"
alias refresh="topgrade; brew cleanup; lpreset"
alias arestart="sudo fdesetup authrestart -delayminutes -1"
alias pdfex="exiftool -Title="" -Creator="" -Producer="""
alias ytmp4="yt-dlp -i -f 'bv[ext=mp4] [vcodec^=avc]+ba[ext=m4a]' -o '%(channel)s - %(title)s [%(id)s.%(ext)s]'"
alias diskspeedtest="time dd if=/dev/zero bs=1024k of=tstfile count=4096; dd if=tstfile bs=1024k of=/dev/null count=4096; rm tstfile"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias fitbackup="gtar -c --exclude-tag-all=.tarignore --exclude='.DS_Store' -vJf /Volumes/storage/Fitting\ In\ Project\ Backup/"$(date '+%y%m%d-%H%M')_fitting_in_avid_project_backup.tar.xz" /Volumes/FIT_Edit1/01\ PROJECT/Avid\ Projekt/FITTING\ IN"

export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:$HOME/.local/bin
export PATH=/opt/homebrew/opt/curl/bin:$PATH

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/michael/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

eval "$(starship init zsh)"

