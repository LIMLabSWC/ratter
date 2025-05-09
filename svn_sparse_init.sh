#!/bin/bash

# Stop on errors
set -e

REPO_URL="http://172.24.155.100/svn/akramilab/ratter"

echo ""
echo "========================================="
echo "🔧  Initializing sparse SVN checkout"
echo "📂  Target directory: $(pwd)"
echo "📡  Repository URL:   $REPO_URL"
echo "========================================="
echo ""

# Sparse checkout of root
echo "➡️  Checking out repository root (empty)..."
svn checkout --depth=empty "$REPO_URL" .

# Fetch top-level .mat file
echo "✅ Fetching: PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat"
svn update PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat

# Prepare SoloData structure
echo ""
echo "📁 Preparing SoloData structure..."
svn update --set-depth=empty SoloData
svn update --set-depth=empty SoloData/Data
svn update --set-depth=empty SoloData/Settings

# Add training_videos folder
echo ""
echo "📁 Adding training_videos folder..."
svn update --set-depth=empty training_videos

# Done
echo ""
echo "✅ DONE: Sparse checkout initialized."
echo "📌 You can now selectively fetch folders like:"
echo "   svn update --set-depth=infinity SoloData/Data/arpit"
echo "   svn update --set-depth=infinity SoloData/Settings/arpit"
echo ""
