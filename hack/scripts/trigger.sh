#!/bin/bash

# Copyright AppsCode Inc. and Contributors
#
# Licensed under the AppsCode Free Trial License 1.0.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://github.com/appscode/licenses/raw/1.0.0/AppsCode-Free-Trial-1.0.0.md
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

PR_BRANCH=master
COMMIT_MSG="Update charts"

skip_trigger() {
    while IFS=$': \r\t' read -r -u9 marker v; do
        if [ "$marker" = "/skip-trigger" ]; then
            return 0
        fi
    done 9< <(git show -s --format=%b)
    return 1
}

skip_trigger && {
    echo "Skipped recursive trigger."
    exit 0
}

repo_uptodate() {
    # gomodfiles=(go.mod go.sum vendor/modules.txt)
    gomodfiles=(go.sum vendor/modules.txt)
    # https://remarkablemark.org/blog/2017/10/12/check-git-dirty/
    changed=($(git status --porcelain | awk '{print $2}'))
    changed+=("${gomodfiles[@]}")
    # https://stackoverflow.com/a/28161520
    diff=($(echo ${changed[@]} ${gomodfiles[@]} | tr ' ' '\n' | sort | uniq -u))
    return ${#diff[@]}
}

echo "automatically apply post commit stuff"

# run command to update repo
touch auto-$(date +%s)
ls -l

if repo_uptodate ; then
    echo "Repository is up-to-date."
    exit 0
fi

git add --all
git commit -a -s -m "$COMMIT_MSG" -m "/skip-trigger"
git push -u origin $PR_BRANCH -f

