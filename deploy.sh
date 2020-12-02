#!/bin/sh

# If a command fails then the deploy stops		
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo -t anubis

cd public

git add .

# Fill in credentials
git config --local user.name $USER_NAME
git config --local user.email $USER_EMAIL

# Commit changes.
msg="rebuilding site HUGO:$(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

git push origin master
