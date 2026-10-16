export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="$HOME/.local/share/android/java-21"
for android_tool_dir in "$JAVA_HOME/bin" "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/emulator"; do
  case ":$PATH:" in
    *":$android_tool_dir:"*) ;;
    *) PATH="$android_tool_dir:$PATH" ;;
  esac
done
export PATH
unset android_tool_dir
