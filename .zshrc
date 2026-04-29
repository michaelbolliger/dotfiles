source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

alias bru="brew update; brew upgrade; brew autoremove; brew cleanup --prune=all"
alias lpreset="find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock"
alias cleardock="defaults write com.apple.dock persistent-apps -array; killall Dock"
alias refresh="topgrade; brew cleanup; lpreset"
alias arestart="sudo fdesetup authrestart -delayminutes -1"
alias pdfex="exiftool -Title="" -Creator="" -Producer="" -Author="""
alias ytmp4="yt-dlp -i -f 'bv[ext=mp4] [vcodec^=avc]+ba[ext=m4a]' -o '%(channel)s - %(title)s [%(id)s.%(ext)s]'"
alias diskspeedtest="time dd if=/dev/zero bs=1024k of=tstfile count=4096; dd if=tstfile bs=1024k of=/dev/null count=4096; rm tstfile"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias fitbackup="gtar -c --exclude-tag-all=.tarignore --exclude='.DS_Store' -vJf /Volumes/storage/Fitting\ In\ Project\ Backup/"$(date '+%y%m%d-%H%M')_fitting_in_avid_project_backup.tar.xz" /Volumes/FIT_Edit1/01\ PROJECT/Avid\ Projekt/FITTING\ IN"
alias backup="rsync -achPiX --stats --cc=xxh64 --delete --delete-excluded --exclude=.DS_Store"
alias backupfast="rsync -auhPiX --stats --delete --delete-excluded --exclude=.DS_Store"
alias backupproject="rsync -auhPiX --stats --delete --delete-excluded --exclude={'.DS_Store','*_Proxy*','*Proxies*','*Previews*','*Auto-Save*','*.xmp','*.mxfindex','*.pek','*.prmi'}"
alias resetuser="echo '== change permissions of user $(id -u) (directory ~) to 700 ==';chmod -R 700 ~ 2>/dev/null;diskutil resetUserPermissions / $(id -u)"
alias cleands="find ~ -name ".DS_Store" -type f -delete 2>/dev/null"

alias ls='ls -G'
alias ll='ls -lhG'
alias la='ls -lAhG'

make_prores() {
    # Check if a filename was provided
    if [ -z "$1" ]; then
        echo "Error: Please provide an input video file."
        echo "Usage: make_prores <filename>"
        return 1
    fi

    local f="$1"

    # 1. Get dimensions using ffprobe
    # This grabs width and height in a 'W H' format
    local dims=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$f")
    local width=$(echo $dims | cut -d'x' -f1)
    local height=$(echo $dims | cut -d'x' -f2)

    # 2. Determine Scale Logic
    # We target 4K (3840) on the longest dimension
    local scale_filter
    if [ "$width" -ge "$height" ]; then
        # Landscape: Width is 3840, Height is calculated to maintain ratio
        scale_filter="scale=3840:-2:flags=lanczos"
        echo "Detected Landscape orientation..."
    else
        # Vertical: Height is 3840, Width is calculated to maintain ratio
        scale_filter="scale=-2:3840:flags=lanczos"
        echo "Detected Vertical orientation..."
    fi

    # 3. Run FFmpeg
    ffmpeg -i "$f" \
        -map_metadata -1 \
        -vf "$scale_filter" \
        -pix_fmt uyvy422 \
        -c:v prores_videotoolbox \
        -profile:v 3 \
        -c:a pcm_s24le \
        -ac 2 \
        -ar 48000 \
        "${f%.*}_4k_prores.mov"

    echo "Done! Output saved as ${f%.*}_4k_prores.mov"
}

export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:$HOME/.local/bin
export PATH=/opt/homebrew/opt/curl/bin:$PATH
export PATH="/opt/homebrew/opt/ffmpeg-full/bin:$PATH"

eval "$(starship init zsh)"

