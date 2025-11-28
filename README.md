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
- **yabai** - Tiling window manager for macOS
- **skhd** - Hotkey daemon for macOS
- **sketchybar** - Custom status bar for macOS

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

### macOS with Window Manager
macOS with tiling window manager and custom bar:
```bash
stow zsh git nvim zellij macos-tools yabai skhd sketchybar lazygit yazi btop
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

**Window Manager Tools:**
```bash
brew tap koekeishiya/formulae
brew tap FelixKratz/formulae
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
brew install FelixKratz/formulae/sketchybar
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

### macOS Window Manager Setup (yabai)

If you installed yabai, additional configuration is required for full functionality:

#### 1. Disable System Integrity Protection (SIP)

Yabai's scripting addition requires partially disabling SIP:

1. Reboot into Recovery Mode:
   - **Intel Mac:** Restart and hold `Cmd + R` during boot
   - **Apple Silicon:** Shut down, then press and hold the power button until "Loading startup options" appears, then select Options

2. Open Terminal from the Utilities menu

3. Run the following command:
   ```bash
   csrutil enable --without fs --without debug --without nvram
   ```

4. Reboot normally

5. Verify SIP status:
   ```bash
   csrutil status
   ```
   You should see: `System Integrity Protection status: unknown (Custom Configuration)`

#### 2. Load Scripting Addition

After disabling SIP and rebooting:

```bash
sudo yabai --load-sa
```

You'll need to run this command each time yabai is updated.

#### 3. Grant Accessibility Permissions

1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Add and enable:
   - `yabai`
   - `skhd`
   - Your terminal application (Terminal.app, Ghostty, etc.)

#### 4. Start Services

```bash
# Start yabai
yabai --start-service

# Start skhd
skhd --start-service

# Start sketchybar
brew services start sketchybar
```

#### 5. Verify Installation

```bash
# Check yabai is running
yabai -m query --windows

# Check skhd is running
skhd --check

# Check sketchybar is running
brew services list | grep sketchybar
```

#### Updating yabai

When updating yabai via Homebrew, you must reload the scripting addition:

```bash
brew upgrade yabai
sudo yabai --load-sa
yabai --restart-service
```

#### Troubleshooting

- **yabai not tiling windows:** Ensure SIP is partially disabled and scripting addition is loaded
- **skhd hotkeys not working:** Check Accessibility permissions
- **sketchybar not appearing:** Restart the service with `brew services restart sketchybar`

For more details, see the [official yabai wiki](https://github.com/koekeishiya/yabai/wiki).

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
