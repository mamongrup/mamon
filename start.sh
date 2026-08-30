#!/bin/bash
# Mamon server startup script
# Handles nohup TTY crash by using erl directly with -noinput

set -e

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check SECRET_KEY_BASE
if [ -z "$SECRET_KEY_BASE" ]; then
  echo "HATA: SECRET_KEY_BASE tanımlı değil!"
  exit 1
fi

# Check DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "HATA: DATABASE_URL tanımlı değil!"
  exit 1
fi

# Build if build dir doesn't exist
if [ ! -d "build/dev/erlang/mamon/ebin" ]; then
  echo "İlk kez çalışıyor, build ediliyor..."
  gleam build
fi

# Collect all .ebin paths
EBIN_PATH=""
for dir in build/dev/erlang/*/ebin; do
  if [ -n "$EBIN_PATH" ]; then
    EBIN_PATH="$EBIN_PATH:$dir"
  else
    EBIN_PATH="$dir"
  fi
done

echo "Ebin path: $EBIN_PATH"
echo "Starting mamon..."

# Start Erlang VM directly - no TTY needed
# -noinput prevents prim_tty initialization
# -noshell prevents shell prompt
exec erl \
  -pa $EBIN_PATH \
  -noinput \
  -noshell \
  -eval "mamon:main()."
