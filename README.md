# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for flexible, modular configuration management across multiple machines.

## Quick Start

### Automated Setup

The easiest way to get started is using the provided setup scripts:

**Arch Linux:**
```bash
cd ~/dotfiles
./install-arch.sh
```

**macOS:**
```bash
cd ~/dotfiles
./install-macos.sh
```

These scripts will:
- Install necessary packages
- Prompt for optional package groups
- Automatically stow the selected configurations

### Manual Setup

If you prefer manual control or selective installation:

1. Install GNU Stow:
   ```bash
   # Arch Linux
   sudo pacman -S stow
   
   # macOS
   brew install stow
   ```

2. Clone this repository to your home directory:
   ```bash
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

3. Stow the packages you want:
   ```bash
   stow zsh git nvim zellij
   ```

## Package Structure

Dotfiles are organized into modular packages that can be installed independently:

### Core Packages

- **zsh** - Shell configuration with Zinit, Powerlevel10k, and OS-specific settings
- **git** - Git configuration
- **nvim** - Neovim editor configuration
- **zellij** - Terminal multiplexer configuration

### Development Tools

- **ideavim** - IntelliJ IDEA Vim emulation configuration
- **lazygit** - Git TUI configuration
- **yazi** - File manager configuration
- **btop** - System monitor configuration

### Linux Desktop (Wayland/Hyprland)

- **hyprland** - Hyprland window manager with hypridle and hyprlock
- **wayland-tools** - Waybar, Wofi, SwayNC, Rofi, Wpaperd configurations
- **gtk** - GTK3, Qt5/Qt6, themes, and appearance settings

### macOS Applications

- **macos-tools** - Zed editor and Ghostty terminal configurations

### Creative Tools

- **godot** - Godot engine editor settings
- **zathura** - PDF viewer configuration

## Usage Examples

### Minimal Server Setup
Install just the essentials for a remote server:
```bash
stow zsh git nvim zellij
```

### Full Linux Desktop
Complete Arch Linux desktop environment:
```bash
stow zsh git nvim zellij hyprland wayland-tools gtk lazygit yazi btop
```

### macOS Development Machine
macOS with development tools:
```bash
stow zsh git nvim zellij macos-tools lazygit yazi btop ideavim
```

### Selective Installation
Install only what you need:
```bash
# Just shell config
stow zsh

# Add editor
stow nvim

# Add terminal tools
stow zellij lazygit yazi
```

## Managing Configurations

### Adding a New Configuration
To add a new configuration:
```bash
stow <package-name>
```

### Removing a Configuration
To remove a stowed configuration:
```bash
stow -D <package-name>
```

### Restowing (Update)
After making changes, restow to update symlinks:
```bash
stow -R <package-name>
```

### Restow Everything
To restow all packages at once:
```bash
stow -R */
```

## Package Dependencies

### Arch Linux

**Core:**
```bash
sudo pacman -S git zsh stow fzf eza zoxide neovim zellij
```

**Development:**
```bash
sudo pacman -S lazygit yazi btop
```

**Hyprland Desktop:**
```bash
sudo pacman -S hyprland hypridle hyprlock waybar wofi swaync rofi wpaperd gtk3 qt5ct qt6ct nwg-look
```

### macOS

**Core:**
```bash
brew install git zsh stow fzf eza zoxide neovim zellij
```

**Development:**
```bash
brew install lazygit yazi btop
```

**GUI Applications:**
```bash
brew install --cask zed ghostty
```

## Post-Installation

After installing the zsh package:

1. Restart your terminal or source the config:
   ```bash
   source ~/.zshrc
   ```

2. On first launch, Powerlevel10k will prompt you to configure it:
   ```bash
   p10k configure
   ```

3. Zinit will automatically install plugins on first launch

## Customization

### OS-Specific Settings

The zsh package includes OS-specific configuration files:
- `.zsh-darwin.sh` - macOS-specific settings (Homebrew, ASDF)
- `.zsh-linux.sh` - Linux-specific settings (Paru, ASDF)

These are automatically sourced based on your OS.

### Personal Scripts

Place personal scripts and secrets in:
- `~/.zsh_scripts/` - General scripts
- `~/.zsh_secrets/` - Secrets (should be gitignored)

All `.sh` files in these directories will be automatically sourced.

## Troubleshooting

### Stow Conflicts
If stow reports conflicts with existing files:
```bash
# Backup existing configs
mv ~/.zshrc ~/.zshrc.backup

# Then stow
stow zsh
```

### Permission Issues
Ensure stow is run from the dotfiles directory:
```bash
cd ~/dotfiles
stow <package>
```

### Missing Symlinks
If symlinks aren't created, verify you're in the correct directory and the package exists:
```bash
cd ~/dotfiles
ls -la  # Verify packages exist
stow -v <package>  # Verbose output for debugging
```

## License

Personal dotfiles - feel free to use as reference or inspiration.
