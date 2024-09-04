#!/bin/bash
set -e

# Set up ssh known hosts and agent
ssh-keyscan -t rsa github.com >> /etc/ssh/ssh_known_hosts
eval `ssh-agent -s`
ssh-add - <<< "$SSH_PRIVATE_KEY"

# split single parameter of this script into multiple params for the command
eval "set -- $1"
git-filter-repo "$@"

# workaround! tag-callback doesn't appear to be dropping commits as intended.
if [ -n "$TAG_FILTER" ]; then
    git tag --list \
        | grep -v -E "$TAG_FILTER" \
        | sed -E 's#^#delete refs/tags/#g' \
        | git update-ref --no-deref --stdin

# push the target branch and all tags
git push "git@github.com:$TARGET_ORG/$TARGET_REPO.git" HEAD:"$TARGET_BRANCH"
git push --tags "git@github.com:$TARGET_ORG/$TARGET_REPO.git"
