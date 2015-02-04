# We use a fake terminal type to signal that the terminal emulator is configured with solarized colors. The proper thing to do would be to pass an environment variable directly, but the servers don't accept this
if [[ "$TERM" == *-solarized* ]]
then
	ORIGTERM="$TERM"
	export TERM=`echo $ORIGTERM | sed "s/-solarized.*$//"`
	export SOLARIZED=`echo $ORIGTERM | sed "s/^.*-solarized//"`
	unset ORIGTERM
fi

# Support solarized mintty's
if [[ -f ~/.minttyrc ]]
then
	export SOLARIZED=$(grep -i solarized .minttyrc | cut -d"=" -f2)
fi

# For some reason, some systems forcibly set this to /etc/inputrc
if [ -f "$HOME/.inputrc" ]; then
	export INPUTRC=$HOME/.inputrc
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Cygwin, by default, does not include DOMAINNAME.
command -v domainname > /dev/null 2>&1 && DOMAINNAME=`domainname`

# Work systems only
if [[ "ilndc.com" = "$DOMAINNAME" ]]; then
	export PATH=/usr/local/bin:/bin:/usr/bin:/usr/X11R6/bin
	export PATH=~/bin:$PATH:/usr/ms/bin:~/ms-scripts/:/opt/rational/clearcase/bin
	export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
	export LD_LIBRARY_PATH=$HOME/lib
	[[ "$CPPFLAGS" == *-I$HOME/include* ]] || export CPPFLAGS="$CPPFLAGS -I$HOME/include"
	[[ "$LDFLAGS" == *-L$HOME/lib* ]] || export LDFLAGS="$LDFLAGS -L$HOME/lib"
fi


export HISTSIZE=100000000
shopt -s histappend
shopt -s checkwinsize
export EDITOR=vim

CYAN="\[\033[0;36m\]"
GRAY="\[\033[0;37m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"

#PROMPT_COMMAND='history -a; DIR=`pwd|sed -e "s!$HOME!~!"`; if [ ${#DIR} -gt 48 ]; then CurDir=${DIR:0:30}...${DIR:${#DIR}-15}; else CurDir=$DIR; fi'
#PROMPT_COMMAND='history -a'
#PROMPT_COMMAND='history -a ; hcmnt -lty ~/.bash_history.full' # ; history -a'
PROMPT_COMMAND='history -a'

__local_git_ps1 () 
{ 
	local b="$(git symbolic-ref HEAD 2>/dev/null)";
	if [ -n "$b" ]; then
		printf " (%s)" "${b##refs/heads/}";
	fi
}

export LS_OPTIONS='-F'
if [ "$(uname)" == "Darwin" ]
then
	export LS_OPTIONS="$LS_OPTIONS -G"
else
	export LS_OPTIONS="$LS_OPTIONS --color=auto"
fi

export GREP_OPTIONS='--color=auto'
# Pass colors, don't clear the screen, and don't use LESS if there's less than one screenful
export LESS='-R -X -F'

alias vim='vim -X'
alias ls='ls $LS_OPTIONS'

# Check for dircolors-solarized
if [ "$(uname)" == "Darwin" ]
then
	export CLICOLOR=YES
else
	DIRCOLORSDB=`dirname \`$READLINK ~/.bashrc\``/dircolors-solarized/dircolors.ansi-universal
	if [ -f $DIRCOLORSDB ]
	then
		eval `dircolors $DIRCOLORSDB`
	else
		export LS_COLORS='di=01;33:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
	fi
fi

if $(which brew > /dev/null)
then
	export PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
	if [ -f $(brew --prefix)/etc/bash_completion ]; then
		. $(brew --prefix)/etc/bash_completion
	fi
fi

# When reconnecting a tmux session, the DISPLAY variable will retain it's previous value. This fixes that.
alias fix_display="eval export \`tmux show-environment | grep DISPLAY\`"

_loghistory() {
 
# Detailed history log of shell activities, including time stamps, working directory etc.
#
# Based on 'hcmnt' by Dennis Williamson - 2009-06-05 - updated 2009-06-19
# (http://stackoverflow.com/questions/945288/saving-current-directory-to-bash-history)
#
# Add this function to your '~/.bashrc':
#
# Set the bash variable PROMPT_COMMAND to the name of this function and include
# these options:
#
#     e - add the output of an extra command contained in the histentrycmdextra variable
#     h - add the hostname
#     y - add the terminal device (tty)
#     n - don't add the directory
#     t - add the from and to directories for cd commands
#     l - path to the log file (default = $HOME/.bash_log)
#     ext or a variable
#
# See bottom of this function for examples.
#
 
    # make sure this is not changed elsewhere in '.bashrc';
    # if it is, you have to update the reg-ex's below
    export HISTTIMEFORMAT="[%F %T] ~~~ "
 
    local script=$FUNCNAME
    local histentrycmd=
    local cwd=
    local extra=
    local text=
    local logfile="$HOME/.bash_log"
    local hostname=
    local histentry=
    local histleader=
    local datetimestamp=
    local histlinenum=
    local options=":hyntel:"
    local option=
    OPTIND=1
    local usage="Usage: $script [-h] [-y] [-n|-t] [-e] [text] [-l logfile]"
 
    local ExtraOpt=
    local NoneOpt=
    local ToOpt=
    local tty=
    local ip=
 
    # *** process options to set flags ***
 
    while getopts $options option
    do
        case $option in
            h ) hostname=$HOSTNAME;;
            y ) tty=$(tty);;
            n ) if [[ $ToOpt ]]
                then
                    echo "$script: can't include both -n and -t."
                    echo $usage
                    return 1
                else
                    NoneOpt=1       # don't include path
                fi;;
            t ) if [[ $NoneOpt ]]
                then
                    echo "$script: can't include both -n and -t."
                    echo $usage
                    return 1
                else
                    ToOpt=1         # cd shows "from -> to"
                fi;;
            e ) ExtraOpt=1;;        # include histentrycmdextra
            l ) logfile=$OPTARG;;
            : ) echo "$script: missing filename: -$OPTARG."
                echo $usage
                return 1;;
            * ) echo "$script: invalid option: -$OPTARG."
                echo $usage
                return 1;;
        esac
    done
 
    text=($@)                       # arguments after the options are saved to add to the comment
    text="${text[*]:$OPTIND - 1:${#text[*]}}"
 
    # add the previous command(s) to the history file immediately
    # so that the history file is in sync across multiple shell sessions
    history -a
 
    # grab the most recent command from the command history
    histentry=$(history 1)
 
    # parse it out
    histleader=`expr "$histentry" : ' *\([0-9]*  \[[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\]\)'`
    histlinenum=`expr "$histleader" : ' *\([0-9]*  \)'`
    datetimestamp=`expr "$histleader" : '.*\(\[[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\]\)'`
    histentrycmd=${histentry#*~~~ }
 
    # protect against relogging previous command
    # if all that was actually entered by the user
    # was a (no-op) blank line
    if [[ -z $__PREV_HISTLINE || -z $__PREV_HISTCMD ]]
    then
        # new shell; initialize variables for next command
        export __PREV_HISTLINE=$histlinenum
        export __PREV_HISTCMD=$histentrycmd
        return
    elif [[ $histlinenum == $__PREV_HISTLINE  && $histentrycmd == $__PREV_HISTCMD ]]
    then
        # no new command was actually entered
        return
    else
        # new command entered; store for next comparison
        export __PREV_HISTLINE=$histlinenum
        export __PREV_HISTCMD=$histentrycmd
    fi
 
    if [[ -z $NoneOpt ]]            # are we adding the directory?
    then
        if [[ ${histentrycmd%% *} == "cd" || ${histentrycmd%% *} == "jd" ]]    # if it's a cd command, we want the old directory
        then                             #   so the comment matches other commands "where *were* you when this was done?"
            if [[ -z $OLDPWD ]]
            then
                OLDPWD="$HOME"
            fi
            if [[ $ToOpt ]]
            then
                cwd="$OLDPWD -> $PWD"    # show "from -> to" for cd
            else
                cwd=$OLDPWD              # just show "from"
            fi
        else
            cwd=$PWD                     # it's not a cd, so just show where we are
        fi
    fi
 
    if [[ $ExtraOpt && $histentrycmdextra ]]    # do we want a little something extra?
    then
        extra=$(eval "$histentrycmdextra")
    fi
 
    # strip off the old ### comment if there was one so they don't accumulate
    # then build the string (if text or extra aren't empty, add them with some decoration)
    histentrycmd="${datetimestamp} ${text:+[$text] }${tty:+[$tty] }${ip:+[$ip] }${extra:+[$extra] }~~~ ${hostname:+$hostname:}$cwd ~~~ ${histentrycmd# * ~~~ }"
    # save the entry in a logfile
    echo "$histentrycmd" >> $logfile || echo "$script: file error." ; return 1
 
} # END FUNCTION _loghistory

export PROMPT_COMMAND='_loghistory -hyt'
#export PROMPT_COMMAND='history -a ; history -n'
export PROMPT_COMMAND='history -a'

if [[ -f /mnt/Fusion/mmiller/common/bin/_bashrc ]]; then
	source /mnt/Fusion/mmiller/common/bin/_bashrc
fi

command -v __git_ps1 > /dev/null 2>&1 && GITPS1='$(__git_ps1 " {%s}")' || GITPS1='$(__local_git_ps1 " {%s}")'
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUPSTREAM="verbose"
export PS1="\`_ret=\$?; if [ \$_ret = 0 ]; then echo -en \"${GREEN}\"; else echo -en \"${RED}\"; fi; printf "%3d" \$_ret\` ${CYAN}\u@\h ${RED}\w${CYAN}${GITPS1}\\\$${GRAY} "

if [[ -d /usr/local/tmuxifier ]]; then
       export PATH="/usr/local/tmuxifier/bin:$PATH"
       eval "$(tmuxifier init -)"
fi
if [[ -d $HOME/.tmuxifier ]]; then
       export PATH="$HOME/.tmuxifier/bin:$PATH"
       eval "$(tmuxifier init -)"
fi


