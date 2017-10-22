_colorls_options='-1 -a -A -d -f -l -r -sd -sf -gs -t -h
--all --almost-all --dirs --files --long --report --sort-dirs --group-directories-first
--sort-files --git-status --tree --help'
complete -W "${_colorls_options}" 'colorls'
