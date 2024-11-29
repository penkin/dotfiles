UPDATE_MINUTES=60
WALLPAPER_DIR="/home/jean/Wallpapers/Cyberpunk"
LOCK_WALLPAPER="/tmp/lock.png"

while true; do
  # Select a random wallpaper
  random_wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

  # Convert to png from the extension, and output to our wallpaper dir.
  magick "$random_wallpaper" "$LOCK_WALLPAPER"

  echo "Updated lock wallpaper: $random_wallpaper"

  sleep $((UPDATE_MINUTES * 60))
done
