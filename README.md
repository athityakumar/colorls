# Color LS

[![forthebadge](http://forthebadge.com/images/badges/made-with-ruby.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

[![Gem Version](https://badge.fury.io/rb/colorls.svg)](https://badge.fury.io/rb/colorls)
[![CI](https://github.com/athityakumar/colorls/actions/workflows/ruby.yml/badge.svg)](https://github.com/athityakumar/colorls/actions/workflows/ruby.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=shields)](http://makeapullrequest.com)

A Ruby script that colorizes the `ls` output with color and icons. Here are the screenshots of working example on an iTerm2 terminal (Mac OS), `oh-my-zsh` with `powerlevel9k` theme and `powerline nerd-font + awesome-config` font with the `Solarized Dark` color theme.

 ![image](https://user-images.githubusercontent.com/17109060/32149040-04f3125c-bd25-11e7-8003-66fd29bc18d4.png)

*If you're interested in knowing the powerlevel9k configuration to get this prompt, have a look at [this gist](https://gist.github.com/athityakumar/1bd5e9e24cd2a1891565573a893993eb).*

# Table of contents

- [Usage](#usage)
  - [Flags](#flags)
    - `-1`
    - `-a`   (or) `--all`
    - `-A`   (or) `--almost-all`
    - `-d`   (or) `--dirs`
    - `-f`   (or) `--files`
    - `--help`
    - `-l`   (or) `--long`
    - `--report`
    - `--tree` (or) `--tree=[DEPTH]`
    - `--gs` (or) `--git-status`
    - `--sd` (or) `--sort-dirs` or `--group-directories-first`
    - `--sf` (or) `--sort-files`
    - `-t`
  - [Combination of flags](#combination-of-flags)
- [Installation](#installation)
- [Recommended configurations](#recommended-configurations)
- [Custom configurations](#custom-configurations)
- [Updating](#updating)
- [Uninstallation](#uninstallation)
- [Contributing](#contributing)
- [License](#license)

# Usage

[(Back to top)](#table-of-contents)

Man pages have been added. Checkout `man colorls`.

### Flags

- With `-1` : Lists one entry per line

  ![image](https://user-images.githubusercontent.com/17109060/32149062-4f0547ca-bd25-11e7-98b6-587467379704.png)

- With `-a` (or) `--all` : Does not ignore entries starting with '.'

  ![image](https://user-images.githubusercontent.com/17109060/32149045-182eb39e-bd25-11e7-83d4-897cb14bcff3.png)

- With `-A` (or) `--almost-all` : Does not ignore entries starting with '.', except `./` and `../`

  ![image](https://user-images.githubusercontent.com/17109060/32149046-1ef7664e-bd25-11e7-8bd9-bfc3c8b27b74.png)

- With `-d` (or) `--dirs` : Shows only directories

  ![image](https://user-images.githubusercontent.com/17109060/32149066-5f842aa8-bd25-11e7-9bf0-23313b717182.png)

- With `-f` (or) `--files` : Shows only files

  ![image](https://user-images.githubusercontent.com/17109060/32149065-5a27c9d4-bd25-11e7-9a2b-fd731d76a058.png)

- With `--help` : Prints a very helpful help menu

  ![image](https://user-images.githubusercontent.com/17109060/32149096-cf2cf5b0-bd25-11e7-84b6-909d79099c98.png)

- With `-l` (or) `--long` : Shows in long listing format

  ![image](https://user-images.githubusercontent.com/17109060/32149049-2a63ae48-bd25-11e7-943c-5ceed25bd693.png)

- With `--report` : Shows brief report about number of files and folders shown

  ![image](https://user-images.githubusercontent.com/17109060/32149082-96a83fec-bd25-11e7-9081-7f77e4c90e90.png)

- With `--tree` (or) `--tree=[DEPTH]` : Shows tree view of the directory with the specified depth (default 3)

  ![image](https://user-images.githubusercontent.com/17109060/32149051-32e596e4-bd25-11e7-93a9-5e50c8d2bb19.png)

- With `--gs` (or) `--git-status` : Shows git status for each entry

  ![image](https://user-images.githubusercontent.com/17109060/32149075-7a1a1954-bd25-11e7-964e-1adb173aa2b9.png)

- With `--sd` (or) `--sort-dirs` or `--group-directories-first` : Shows directories first, followed by files

  ![image](https://user-images.githubusercontent.com/17109060/32149068-65117fc0-bd25-11e7-8ada-0b055603e3fd.png)

- With `--sf` (or) `--sort-files` : Shows files first, followed by directories

  ![image](https://user-images.githubusercontent.com/17109060/32149071-6b379de4-bd25-11e7-8764-a0c577e526a1.png)

- With `-t` : Sort by modification time, newest first (NEED TO ADD IMAGE)

- With color options : `--light` or `--dark` can be passed as a flag, to choose the appropriate color scheme. By default, the dark color scheme is chosen. In order to tweak any color, read [Custom configurations](#custom-configurations).

### Combination of flags

- Using `--gs` with `-t` :

  ![image](https://user-images.githubusercontent.com/17109060/32149076-8423c864-bd25-11e7-816e-8642643d2c27.png)

- Using `--gs` with `-l` :

  ![image](https://user-images.githubusercontent.com/17109060/32149078-899b0622-bd25-11e7-9810-d398eaa77e32.png)

- Using `--sd` with `-l` and `-A` :

  ![image](https://user-images.githubusercontent.com/17109060/32149084-9eb2a416-bd25-11e7-8fb7-a9d336c6e038.png)

- Using `--non-human-readable` with `-l` :
  - This will print the file sizes in bytes (non-human readable format)

  ![image](https://user-images.githubusercontent.com/19269206/234581461-1e1fdd90-a362-4cea-ab82-5ca360746be8.png)

# Installation

[(Back to top)](#table-of-contents)

1. Install Ruby (preferably, version >= 2.6)
2. [Download](https://www.nerdfonts.com/font-downloads) and install a Nerd Font. Have a look at the [Nerd Font README](https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md) for installation instructions.

    *Note for `iTerm2` users - Please enable the Nerd Font at iTerm2 > Preferences > Profiles > Text > Non-ASCII font > Hack Regular Nerd Font Complete.*

    *Note for `HyperJS` users - Please add `"Hack Nerd Font"` Font as an option to `fontFamily` in your `~/.hyper.js` file.*

3. Install the [colorls](https://rubygems.org/gems/colorls/) ruby gem with `gem install colorls`

    *Note for `rbenv` users - In case of load error when using `lc`, please try the below patch.*

    ```sh
    rbenv rehash
    rehash
    ```

4. Enable tab completion for flags by entering following line to your shell configuration file (`~/.bashrc` or `~/.zshrc`) :
    ```bash
    source $(dirname $(gem which colorls))/tab_complete.sh
    ```

5. Start using `colorls` :tada:

6. Have a look at [Recommended configurations](#recommended-configurations) and [Custom configurations](#custom-configurations).

# Recommended configurations

[(Back to top)](#table-of-contents)

1. To add some short command (say, `lc`) with some flag options (say, `-l`, `-A`, `--sd`) by default, add this to your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.) :
    ```sh
    alias lc='colorls -lA --sd'
    ```

2. For changing the icon(s) to other unicode icons of choice (select icons from [here](https://nerdfonts.com/)), change the YAML files in a text editor of your choice (say, `subl`)

    ```sh
    subl $(dirname $(gem which colorls))/yaml
    ```

# Custom configurations

[(Back to top)](#table-of-contents)

You can overwrite the existing icons and colors mapping by copying the yaml files from `$(dirname $(gem which colorls))/yaml` into `~/.config/colorls`, and changing them.

- To overwrite color mapping :

  Please have a look at the [list of supported color names](https://github.com/sickill/rainbow#color-list). You may also use a color hex code as long as it is quoted within the YAML file and prefaced with a `#` symbol.

  Let's say that you're using the dark color scheme and would like to change the color of untracked file (`??`) in the `--git-status` flag to yellow. Copy the defaut `dark_colors.yaml` and change it.

  Check if the `~/.config/colorls` directory exists. If it doesn't exist, create it using the following command:
 
  ```sh
  mkdir -p ~/.config/colorls
  ```

  And then

  ```sh
  cp $(dirname $(gem which colorls))/yaml/dark_colors.yaml ~/.config/colorls/dark_colors.yaml
  ```

  In the `~/.config/colorls/dark_colors.yaml` file, change the color set for `untracked` from `darkorange` to `yellow`, and save the change.

  ```
  untracked: yellow
  ```

  Or, using hex color codes:

  ```
  untracked: '#FFFF00'
  ```

- To overwrite icon mapping :

  Please have a look at the [list of supported icons](https://nerdfonts.com/). Let's say you want to add an icon for swift files. Copy the default `files.yaml` and change it.

  ```sh
  cp $(dirname $(gem which colorls))/yaml/files.yaml ~/.config/colorls/files.yaml`
  ```

  In the `~/.config/colorls/files.yaml` file, add a new icon / change an existing icon, and save the change.


  ```
  swift: "\uF179"
  ```

- User contributed alias configurations :

  - [@rjhilgefort](https://gist.github.com/rjhilgefort/51ea47dd91bcd90cd6d9b3b199188c16)


# Updating

[(Back to top)](#table-of-contents)

Want to update to the latest version of `colorls`?

```sh
gem update colorls
```

# Uninstallation

[(Back to top)](#table-of-contents)

Want to uninstall and revert back to the old style? No issues (sob). Please feel free to open an issue regarding how we can enhance `colorls`.

```sh
gem uninstall colorls
```

# Contributing

[(Back to top)](#table-of-contents)

Your contributions are always welcome! Please have a look at the [contribution guidelines](CONTRIBUTING.md) first. :tada:

# License

[(Back to top)](#table-of-contents)


The MIT License (MIT) 2017 - [Athitya Kumar](https://github.com/athityakumar/). Please have a look at the [LICENSE.md](LICENSE.md) for more details.
