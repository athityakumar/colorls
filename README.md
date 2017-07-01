# Color LS [![Build Status](https://travis-ci.org/athityakumar/colorls.svg?branch=master)](https://travis-ci.org/athityakumar/colorls)
A Ruby script that colorizes the `ls` output with format icons. Here are the screenshots of
working example on an iTerm2 terminal (Mac OS), `oh-my-zsh` with `powerlevel9k` theme and `powerline nerd-font + awesome-config` font.

![Example #1](readme/example1.png)
![Example #2](readme/example2.png)

# Installation steps

1. Install Ruby (prefably, version > 2.1)
2. Install the patched fonts of powerline nerd-font and/or font-awesome.
3. Clone this repository with `git clone https://github.com/athityakumar/colorls.git`
4. Navigate to this cloned directory : `cd colorls`
5. Install bundler and dependencies :
  ```
  gem install bundler
  bundle install
  ``` 
6. For CLI functionality, add a function (say, `lc`) to your shell configuration file (`~/.bashrc` or `~/.zshrc`) : 
  ```sh
  function lc()
  {
    ruby /path/to/colorls/colorls.rb $1;
  }
  ```

  _Note : I have aliased it to `lc`, as it can be seen from the screenshot._

7. Change the `aliases.yaml` and `formats.yaml` files, if required. (Say, add custom icons)
8. Open a new terminal, and start using  `lc` :tada:

# How to use

- `lc` : Prints all directories, files and dotfiles in current directory.
- `lc path` : Prints all directories, files and dotfiles in `path` directory.
- `lc path1 path2` : Prints all directories, files and dotfiles in directories `path1` and `path2`.
- `lc path1 path2 --report` : Prints above details, along with metdata such as number of folders, recognized file formats & unrecognized file formats.

# Tweaking this project

![Pending formats](readme/pending.png)

There are a couple of formats that aren't recognized yet. Custom file formats and icons can be added by changing the files : [formats](formats.yaml) and/or [aliases](aliases.yaml). If it looks good, feel free to send a Pull Request here.

Please feel free to contribute to this project, by 
- opening an issue for reporting any bug / suggesting any enhancement
- cleaning up the `colorls.rb` ruby script with more functionalities.
- adding support for more file [formats](formats.yaml) and/or [aliases](aliases.yaml).

# LICENSE

MIT License 2017 - [Athitya Kumar](https://github.com/athityakumar/).
