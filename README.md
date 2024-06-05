# dotfiles

## Getting Started

This setup uses [GNU Stow](https://www.gnu.org/software/stow/) so firstly 
we need to install it so we can get all our configs in place.

### OSX

```shell
brew install stow
brew install tmux
brew install fzf
brew install eza
brew install zoxide
brew install neovim
```

### Arch

```shell
sudo pacman -S stow tmux fzf eza zoxide neovim
```

Once you have GNU Stow install you can clone this repo the `$HOME` directory
of your machine.

## Syncing your dotfiles

To sync your dotfiles simply run the following from your `dotfiles` derectory.

```shell
stow .
```

## TODO:

 - Create an Arch setup script to install all the packages needed.
 - Create a OSX setup script to install all the packages needed.
