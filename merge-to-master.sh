#!/bin/sh

# Script to auto-commit changes, merge develop to master, and return to develop
set -e

echo "Switching to develop branch..."
git checkout develop

echo "Auto-committing changes..."
git-auto-commit

echo "Pushing develop branch..."
git-push-all

echo "Switching to master branch..."
git checkout master

echo "Merging develop into master..."
git merge -

echo "Pushing master branch..."
git-push-all

echo "Switching back to develop branch..."
git checkout develop

echo "Done. Develop has been merged to master and pushed."