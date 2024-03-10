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

alias bru="brew update; brew upgrade; brew cleanup"
alias lpreset="defaults write com.apple.dock ResetLaunchPad -bool true; killall Dock"
alias refresh="topgrade; brew cleanup; lpreset"
alias arestart="sudo fdesetup authrestart -delayminutes -1"
alias pdfex="exiftool -Title="" -Creator="" -Producer="""
alias ytmp4="yt-dlp -i -f 270+140"
alias diskspeedtest="time dd if=/dev/zero bs=1024k of=tstfile count=4096; dd if=tstfile bs=1024k of=/dev/null count=4096; rm tstfile"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:$HOME/.local/bin
export PATH=/opt/homebrew/opt/curl/bin:$PATH

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/michael/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

