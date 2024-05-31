#!/usr/bin/env bash

# make sure we have pulled in and updated any submodules
git submodule init
git submodule update

# what directories should be installable by all users including the root user
base=(
)

# folders that should, or only need to be installed for a local user
useronly=(
  .config
  .zsh
  Wallpapers
)

# run the stow command for the passed in directory ($2) in location $1
stowit() {
    dir=$1
    app=$2
    # -v verbose
    # -R recursive
    # -t target

    # Check if the directory exists. If not create it.
    if [ ! -d "$dir" ]; then
      mkdir $dir
    fi

    stow -v -R -t ${dir} ${app}
}

echo ""
echo "Stowing apps for user: ${whoami}"

# install apps available to local users and root
for app in ${base[@]}; do
    stowit "${HOME}" $app 
done

# install only user space folders
if [ "$EUID" -ne 0 ]; then
  for app in ${useronly[@]}; do
    stowit "${HOME}/$app" $app 
  done
fi

echo ""
echo "##### ALL DONE"
