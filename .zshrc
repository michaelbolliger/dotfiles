source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

#bindkey "[D" backward-word
#bindkey "[C" forward-word
#bindkey "^[a" beginning-of-line
#bindkey "^[e" end-of-line

alias bru="brew update; brew upgrade; brew autoremove; brew cleanup --prune=all"
#alias lpreset="defaults write com.apple.dock ResetLaunchPad -bool true; killall Dock"
alias lpreset="find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock"
alias cleardock="defaults write com.apple.dock persistent-apps -array; killall Dock"
alias refresh="topgrade; brew cleanup; lpreset"
alias arestart="sudo fdesetup authrestart -delayminutes -1"
alias pdfex="exiftool -Title="" -Creator="" -Producer="" -Author="""
alias ytmp4="yt-dlp -i -f 'bv[ext=mp4] [vcodec^=avc]+ba[ext=m4a]' -o '%(channel)s - %(title)s [%(id)s.%(ext)s]'"
alias diskspeedtest="time dd if=/dev/zero bs=1024k of=tstfile count=4096; dd if=tstfile bs=1024k of=/dev/null count=4096; rm tstfile"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias fitbackup="gtar -c --exclude-tag-all=.tarignore --exclude='.DS_Store' -vJf /Volumes/storage/Fitting\ In\ Project\ Backup/"$(date '+%y%m%d-%H%M')_fitting_in_avid_project_backup.tar.xz" /Volumes/FIT_Edit1/01\ PROJECT/Avid\ Projekt/FITTING\ IN"
alias backup="rsync -achP --cc=xxh64 --delete --delete-excluded --exclude=.DS_Store"
alias backupfast="rsync -auhP --delete --delete-excluded --exclude=.DS_Store"
alias backupproject="rsync -auhP --delete --delete-excluded --exclude={'.DS_Store','*_Proxy*','*Proxies*','*Previews*','*Auto-Save*','*.xmp','*.mxfindex','*.pek','*.prmi'}"
alias resetuser="chmod -R 700 ~ 2>/dev/null;diskutil resetUserPermissions / $(id -u)"

# List directory contents
alias ls='ls --color'
alias ll='ls -lh --color'
alias la='ls -lAh --color'

export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:$HOME/.local/bin
export PATH=/opt/homebrew/opt/curl/bin:$PATH

eval "$(starship init zsh)"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/michael/.lmstudio/bin"

# Added by Antigravity
export PATH="/Users/michael/.antigravity/antigravity/bin:$PATH"
