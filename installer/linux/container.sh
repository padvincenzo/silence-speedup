#!/usr/bin/env bash
# Runs inside the image built from installer/linux/Dockerfile.
#
# The source arrives read-only at /src and is copied into /work, a volume of
# its own: building in the Windows checkout would rewrite .dart_tool with Linux
# paths and break the Windows build sharing it. /out is where results land.
#
#   build   analyse, test, build the release bundle, pack it into /out
#   smoke   start the built bundle on a virtual display and photograph it
#   e2e     process a sample video through the GUI and measure the result
#   run    start the built bundle on the display in $DISPLAY (WSLg)
#   shell   a shell in /work
set -euo pipefail

bundle=/work/build/linux/x64/release/bundle
binary="$bundle/silence_speedup"

version() {
  sed -n 's/^version: *\([0-9.]*\).*/\1/p' /work/pubspec.yaml
}

# The ephemeral folders are left out for the same reason as .dart_tool: a
# Windows pub get fills them with links to Windows paths, and CMake here
# would follow them nowhere. Flutter regenerates them on the Linux side.
# An excluded path is also one rsync will not delete, so a stale copy is
# removed by hand first.
sync_source() {
  rm -rf /work/linux/flutter/ephemeral
  rsync -a --delete \
    --exclude .git/ --exclude build/ --exclude dist/ --exclude .dart_tool/ \
    --exclude .flutter-plugins-dependencies --exclude flutter/ephemeral/ \
    /src/ /work/
}

build() {
  sync_source
  cd /work
  flutter pub get
  flutter analyze
  flutter test
  flutter build linux --release

  local name="silence-speedup-$(version)-linux-x64"
  rm -rf "/tmp/$name"
  cp -a "$bundle" "/tmp/$name"
  tar -czf "/out/$name.tar.gz" -C /tmp "$name"
  echo "Packed /out/$name.tar.gz"
}

require_bundle() {
  if [[ ! -x "$binary" ]]; then
    echo "No bundle yet: run the build first." >&2
    exit 1
  fi
}

# Starts the app on a virtual display, waits for its window, photographs it,
# then launches a second copy and checks that it leaves without a window of
# its own — the one-copy rule, which on Linux rests on the session bus.
smoke() {
  require_bundle
  local shots=/out/screenshots
  mkdir -p "$shots"
  export DISPLAY=:99
  Xvfb :99 -screen 0 1600x1000x24 >/dev/null 2>&1 &
  sleep 1

  dbus-run-session -- bash -s "$binary" "$shots" <<'SESSION'
set -euo pipefail
binary=$1
shots=$2

"$binary" >/tmp/app.log 2>&1 &
app=$!

window=""
for _ in $(seq 1 60); do
  window=$(xdotool search --name '^Silence SpeedUp$' 2>/dev/null | head -n 1 || true)
  [[ -n "$window" ]] && break
  sleep 0.5
done
if [[ -z "$window" ]]; then
  echo "FAIL: no window appeared" >&2
  cat /tmp/app.log >&2
  exit 1
fi
sleep 3
import -window root "$shots/queue.png"
echo "Window $window is up; screenshot in $shots/queue.png"

timeout 20 "$binary" >/tmp/second.log 2>&1 && second=$? || second=$?
count=$(xdotool search --name '^Silence SpeedUp$' 2>/dev/null | wc -l)
if [[ $second -ne 0 || $count -ne 1 ]]; then
  echo "FAIL: second copy exited $second with $count window(s)" >&2
  cat /tmp/second.log >&2
  exit 1
fi
echo "Second copy left at once and the first window is still the only one"

kill "$app"
wait "$app" 2>/dev/null || true
echo "--- app log"
cat /tmp/app.log
if grep -q 'ffmpeg_kit: dlopen' /tmp/app.log; then
  echo "FAIL: the plugin could not load the bundled FFmpeg" >&2
  exit 1
fi
SESSION
}

# Processes a real video through the GUI, the way a person would: Ctrl+O, the
# file dialog, the Start button. The sample alternates two seconds of tone
# with three of silence, so a working run has to come out clearly shorter;
# what the run produced is measured rather than looked at.
e2e() {
  require_bundle
  local shots=/out/screenshots
  mkdir -p "$shots"
  export DISPLAY=:99
  Xvfb :99 -screen 0 1600x1000x24 >/dev/null 2>&1 &
  sleep 1

  # A home of its own, so the run starts from default preferences. The
  # desktop name is what makes the portal pick its GTK backend for dialogs.
  export HOME=$(mktemp -d)
  export XDG_CURRENT_DESKTOP=GNOME
  local samples=/tmp/e2e
  rm -rf "$samples" && mkdir -p "$samples"
  ffmpeg -loglevel error \
    -f lavfi -i testsrc=size=640x360:rate=25:duration=30 \
    -f lavfi -i "aevalsrc='if(lt(mod(t,5),2),0.5*sin(2*PI*440*t),0)':s=44100:d=30" \
    -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "$samples/talk.mp4"

  dbus-run-session -- bash -s "$binary" "$shots" "$samples" <<'SESSION'
set -euo pipefail
binary=$1
shots=$2
samples=$3

shot() { import -window root "$shots/$1.png"; }
fail() { echo "FAIL: $*" >&2; shot failure; cat /tmp/app.log >&2; exit 1; }

"$binary" >/tmp/app.log 2>&1 &

window=""
for _ in $(seq 1 60); do
  window=$(xdotool search --name '^Silence SpeedUp$' 2>/dev/null | head -n 1 || true)
  [[ -n "$window" ]] && break
  sleep 0.5
done
[[ -n "$window" ]] || fail "no window appeared"
sleep 3

xdotool windowfocus --sync "$window"
xdotool key ctrl+o
# Found by the title the app gives it, which is the portal's window.
dialog=""
for _ in $(seq 1 30); do
  dialog=$(xdotool search --name '^Select one or more videos$' 2>/dev/null | tail -n 1 || true)
  [[ -n "$dialog" ]] && break
  sleep 0.5
done
[[ -n "$dialog" ]] || fail "Ctrl+O opened no file dialog"
sleep 1
shot e2e-1-dialog
xdotool windowfocus --sync "$dialog"
xdotool key ctrl+l
xdotool type --delay 20 "$samples/talk.mp4"
# The first Return can go to the location entry's completion rather than to
# the Open button, so it is pressed until the dialog has gone.
for _ in 1 2 3; do
  xdotool key Return
  sleep 2
  xdotool search --name '^Select one or more videos$' >/dev/null 2>&1 || break
done
xdotool search --name '^Select one or more videos$' >/dev/null 2>&1 \
  && fail "the file dialog would not accept the path"
sleep 3
shot e2e-2-queued

# The Start button floats at the bottom right of the window.
eval "$(xdotool getwindowgeometry --shell "$window")"
xdotool mousemove --window "$window" $((WIDTH - 68)) $((HEIGHT - 89)) click 1

output=""
for i in $(seq 1 240); do
  output=$(find "$samples" -type f ! -name talk.mp4 | head -n 1)
  [[ $i -eq 6 ]] && shot e2e-3-running
  if [[ -n "$output" ]]; then
    size=$(stat -c %s "$output")
    sleep 2
    [[ "$size" -gt 0 && "$size" -eq "$(stat -c %s "$output")" ]] && break
  fi
  sleep 0.5
done
[[ -n "$output" ]] || fail "no output file after two minutes"
sleep 2
shot e2e-4-done

duration() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"
}
before=$(duration "$samples/talk.mp4")
after=$(duration "$output")
echo "Input $before s, output $after s: $(basename "$output")"
awk -v a="$after" -v b="$before" 'BEGIN { exit !(a > 0 && a < b * 0.75) }' \
  || fail "the output is not clearly shorter than the input"
ffprobe -v error -show_entries stream=codec_type,codec_name -of csv=p=0 "$output"
echo "End-to-end run through the GUI succeeded"
SESSION
}

run() {
  require_bundle
  dbus-run-session -- "$binary"
}

case "${1:-build}" in
  build) build ;;
  smoke) smoke ;;
  e2e) e2e ;;
  run) run ;;
  shell) cd /work && exec bash ;;
  *) echo "Unknown command: $1" >&2; exit 2 ;;
esac
