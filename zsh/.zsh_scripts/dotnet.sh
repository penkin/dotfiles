# .NET SDK setup

# Disable .NET telemetry
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Disable .NET first-run experience
export DOTNET_NOLOGO=1

# Set up dotnet if installed via asdf
if command -v asdf &> /dev/null; then
    DOTNET_ROOT_PATH="$(asdf where dotnet 2>/dev/null)"

    if [ -n "$DOTNET_ROOT_PATH" ]; then
        export DOTNET_ROOT="$DOTNET_ROOT_PATH"
    fi
fi

# Add .NET tools to PATH
export PATH="$PATH:$HOME/.dotnet/tools"
