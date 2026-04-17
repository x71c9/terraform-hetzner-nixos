#!/bin/sh

# Release script for terraform-hetzner-nixos module
# Usage: ./release.sh [patch|minor|major]

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 [patch|minor|major]"
    exit 1
fi

VERSION_TYPE=$1

if [ "$VERSION_TYPE" != "patch" ] && [ "$VERSION_TYPE" != "minor" ] && [ "$VERSION_TYPE" != "major" ]; then
    echo "Error: Version type must be one of: patch, minor, major"
    exit 1
fi

# Get current version from README.md (first occurrence in source line)
CURRENT_VERSION=$(grep -o 'source = "git::.*?ref=v[0-9]\+\.[0-9]\+\.[0-9]\+"' README.md | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not find current version in README.md"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Parse version numbers
MAJOR=$(echo "$CURRENT_VERSION" | sed 's/v\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1/')
MINOR=$(echo "$CURRENT_VERSION" | sed 's/v\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\2/')
PATCH=$(echo "$CURRENT_VERSION" | sed 's/v\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\3/')

# Calculate new version
case $VERSION_TYPE in
    "patch")
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION="v${MAJOR}.${MINOR}.${NEW_PATCH}"
        COMMIT_TYPE="fix"
        ;;
    "minor")
        NEW_MINOR=$((MINOR + 1))
        NEW_VERSION="v${MAJOR}.${NEW_MINOR}.0"
        COMMIT_TYPE="feat"
        ;;
    "major")
        NEW_MAJOR=$((MAJOR + 1))
        NEW_VERSION="v${NEW_MAJOR}.0.0"
        COMMIT_TYPE="feat"
        ;;
esac

echo "New version: $NEW_VERSION"

# Update README.md - replace version only in the first (Usage section) occurrence
# This uses sed to replace only the first match, leaving vX.Y.Z placeholders in examples
sed -i "0,/${CURRENT_VERSION}/s|${CURRENT_VERSION}|${NEW_VERSION}|" README.md

echo "Updated version references in README.md"

# Commit with conventional commits syntax
if [ "$VERSION_TYPE" = "major" ]; then
    git add README.md
    git commit -m "${COMMIT_TYPE}!: release ${NEW_VERSION}

BREAKING CHANGE: major version release"
else
    git add README.md
    git commit -m "${COMMIT_TYPE}: release ${NEW_VERSION}"
fi

echo "Created commit for ${NEW_VERSION}"

# Run merge to master script
echo "Running merge-to-master.sh..."
"$SCRIPT_DIR/merge-to-master.sh"

# Create and push tag
echo "Creating and pushing tag ${NEW_VERSION}..."
git tag "$NEW_VERSION"
git push origin "$NEW_VERSION"

echo "Release ${NEW_VERSION} completed successfully"