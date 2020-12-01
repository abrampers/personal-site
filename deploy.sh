#!/bin/sh

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo -t anubis

cd public

git add .

# Commit changes.
msg="rebuilding site HUGO:$(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

git push origin master
