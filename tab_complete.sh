_colorls_options='-1 -a -A -d -f -l -r -t -h
--all --almost-all --dirs --files --long --report --sort-dirs --group-directories-first
--sort-files --git-status --tree --help --sd --sf --gs'
complete -W "${_colorls_options}" 'colorls'
