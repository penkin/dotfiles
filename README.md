# dotfiles

## Getting Started

This setup uses [GNU Stow](https://www.gnu.org/software/stow/) so firstly 
we need to install it so we can get all our configs in place.

### OSX

```shell
brew install stow
```

### Arch

```shell
sudo pacman -S stow
```

Once you have GNU Stow install you can clone this repo to your machine.

## Syncing your dotfiles

Go into your the directory where you have cloned this repo and set the
environment variable for `stow` to know where your dotfiles are.

```shell
export DOT=$Home/...
```

Then you can run the script to setup all the symlinks.

```shell
chmod +x stowsync.sh
./stowsync.sh
```

## TODO:

 - Create an Arch setup script to install all the packages needed.
 - Create a OSX setup script to install all the packages needed.
