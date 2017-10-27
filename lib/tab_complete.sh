function _colorls_complete() {
    COMPREPLY=( $( colorls --'*'-completion-bash="$2" ) )
}
complete -o default -F _colorls_complete colorls
