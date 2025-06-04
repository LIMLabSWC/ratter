#!/bin/bash

set -e

read -p "SVN Username: " SVN_USER
read -s -p "SVN Password: " SVN_PASS
echo ""

REPO_URL="http://172.24.155.220/svn/akramilab/ratter"
LOG_FILE="sparse_init.log"

echo ""
echo "=========================================" | tee -a "$LOG_FILE"
echo "🔧  Initializing sparse SVN checkout"      | tee -a "$LOG_FILE"
echo "📂  Target directory: $(pwd)"             | tee -a "$LOG_FILE"
echo "📡  Repository URL: $REPO_URL"            | tee -a "$LOG_FILE"
echo "📄  Log file: $LOG_FILE"                 | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Detect if this folder is already a working copy
if svn info > /dev/null 2>&1; then
  echo "⚠️  This directory is already an SVN working copy." | tee -a "$LOG_FILE"
  echo "❌ Aborting to avoid interfering with existing data." | tee -a "$LOG_FILE"
  exit 1
fi

# Sparse checkout of root
echo "➡️  Checking out repository root (empty)..." | tee -a "$LOG_FILE"
svn checkout --username "$SVN_USER" --password "$SVN_PASS" --non-interactive --depth=empty "$REPO_URL" . | tee -a "$LOG_FILE"

# Fetch top-level .mat file
echo "✅ Fetching: PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat" | tee -a "$LOG_FILE"
svn update --username "$SVN_USER" --password "$SVN_PASS" --non-interactive PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat | tee -a "$LOG_FILE"

# Prepare SoloData structure
echo "" | tee -a "$LOG_FILE"
echo "📁 Preparing SoloData structure..." | tee -a "$LOG_FILE"
svn update --username "$SVN_USER" --password "$SVN_PASS" --non-interactive --set-depth=empty SoloData | tee -a "$LOG_FILE"
svn update --username "$SVN_USER" --password "$SVN_PASS" --non-interactive --set-depth=empty SoloData/Data | tee -a "$LOG_FILE"
svn update --username "$SVN_USER" --password "$SVN_PASS" --non-interactive --set-depth=empty SoloData/Settings | tee -a "$LOG_FILE"

# Add training_videos folder
echo "" | tee -a "$LOG_FILE"
echo "📁 Adding training_videos folder..." | tee -a "$LOG_FILE"
svn update --username "$SVN_USER" --password "$SVN_PASS" --non-interactive --set-depth=empty training_videos | tee -a "$LOG_FILE"

# Done
echo "" | tee -a "$LOG_FILE"
echo "✅ DONE: Sparse checkout initialized." | tee -a "$LOG_FILE"
echo "📌 You can now selectively fetch folders like:" | tee -a "$LOG_FILE"
echo "   svn update --set-depth=infinity SoloData/Data/arpit" | tee -a "$LOG_FILE"
echo "   svn update --set-depth=infinity training_videos/rig1" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
