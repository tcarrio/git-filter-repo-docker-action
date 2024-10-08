#!/bin/bash
set -e

# Set up ssh known hosts and agent
ssh-keyscan -t rsa github.com >> /etc/ssh/ssh_known_hosts
eval `ssh-agent -s`
ssh-add - <<< "$SSH_PRIVATE_KEY"

# workaround! tag-callback doesn't appear to be dropping commits as intended.
if [ -n "$TAG_FILTER" ]; then
    git tag --list \
        | grep -v -E "$TAG_FILTER" \
        | sed -E 's#^#delete refs/tags/#g' \
        | git update-ref --no-deref --stdin
fi

# split single parameter of this script into multiple params for the command
eval "set -- $1"
git-filter-repo "$@"

# triage data
echo "git tags found:"
git tag --list

# push to the target branch
if [ -n "$TARGET_BRANCH" ]; then
    git push "git@github.com:$TARGET_ORG/$TARGET_REPO.git" HEAD:"$TARGET_BRANCH"
else
    # push all tags
    git remote add origin "git@github.com:$TARGET_ORG/$TARGET_REPO.git"
    git fetch --all
    git push origin --tags 
fi

