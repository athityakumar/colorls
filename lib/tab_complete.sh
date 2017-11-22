
if [ -z "${ZSH_VERSION+x}" ]; then
    function _colorls_complete() {
        COMPREPLY=( $( colorls --'*'-completion-bash="$2" ) )
    }
    complete -o default -F _colorls_complete colorls
else
    fpath=("${0:A:h:h}/zsh" $fpath)
fi
