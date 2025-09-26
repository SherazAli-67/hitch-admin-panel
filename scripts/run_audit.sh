#!/bin/bash

# Data Audit Script Runner for Hitch Tracker
# This script helps you analyze location data coverage in your Firebase database

echo "🚀 Hitch Tracker - Data Audit Tool"
echo "=================================="
echo ""
echo "This tool will help you understand why your location search results"
echo "don't match your total user count of 3000+."
echo ""
echo "What it does:"
echo "• Analyzes location data coverage across all users"
echo "• Identifies users missing searchable location arrays"
echo "• Shows country distribution from search data"
echo "• Provides migration recommendations"
echo ""

# Check if Dart is available
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart SDK not found. Please install Flutter/Dart first."
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory."
    exit 1
fi

echo "📋 Getting Flutter dependencies..."
flutter pub get

echo ""
echo "🔍 Starting location data audit..."
echo "Note: This may take a few minutes with 3000+ users..."
echo ""

# Run the audit script
dart run scripts/data_audit.dart

echo ""
echo "✅ Audit complete!"
echo ""
echo "Next steps:"
echo "1. Review the audit report above"
echo "2. If you chose to migrate data, test your location searches"
echo "3. The improved search count calculation should now be more accurate"
