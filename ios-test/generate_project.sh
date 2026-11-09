#!/bin/bash
# StillsTest Xcode loyihasini avtomatik yaratish skripti

set -e

echo "🚀 StillsTest loyihasini tayyorlash boshlanmoqda..."

if ! command -v xcodegen &> /dev/null; then
    echo "⚠️ XcodeGen topilmadi. O'rnatilmoqda (Homebrew orqali)..."
    brew install xcodegen
fi

echo "📦 Xcode loyihasi (.xcodeproj) yaratilmoqda..."
xcodegen generate

echo "✅ Loyiha muvaffaqiyatli yaratildi! Xcode ochilmoqda..."
open StillsTest.xcodeproj
