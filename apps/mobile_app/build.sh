#!/bin/bash
set -e

echo "==> Cloning stable Flutter"
if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable _flutter --depth 1
fi

export PATH="$PATH:`pwd`/_flutter/bin"

echo "==> Configuring Flutter Web"
flutter config --enable-web
flutter precache --web

echo "==> Fetching Dependencies"
flutter pub get

echo "==> Building Web Release"
flutter build web --release --no-tree-shake-icons

echo "==> Build Complete"
