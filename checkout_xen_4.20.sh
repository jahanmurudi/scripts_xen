#!/bin/bash

# Set custom repository URL and branch name
REPO_URL="https://github.com/jahanmurudi/xen.git"
BRANCH="xen-4.20-stable-h3sk-kf"
COMMIT="7ccb488f8752a69f41f820a44ce618e3d3b8fb4f"

# Clone the Xen repository with full history to access specific commit
echo "Cloning Xen repository from custom fork..."
git clone --branch $BRANCH $REPO_URL $BRANCH

# Navigate into the cloned repository
cd $BRANCH || { echo "Failed to enter directory"; exit 1; }

# Checkout the specific commit
echo "Checking out specific commit: $COMMIT"
git checkout $COMMIT || { echo "Failed to checkout commit"; exit 1; }

# Confirm checked-out commit
echo "Checked out commit:"
git log -1 --oneline

