#!/bin/bash
export DOTNET_ROOT="$HOME/.asdf/installs/dotnet/8.0.405"
export PATH="$HOME/.asdf/installs/dotnet/8.0.405:$PATH"
exec ~/.local/netcoredbg/netcoredbg "$@"
