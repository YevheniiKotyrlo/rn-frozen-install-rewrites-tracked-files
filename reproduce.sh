#!/usr/bin/env bash
# Clones react/react-native at a ref (main by default), runs `yarn install --frozen-lockfile` at its root and lists the
# tracked files the install changed.
# Exit 1 while the install rewrites packages/react-native/package.json or yarn.lock, 0 once it leaves the tree as
# committed or refuses to write the lockfile, 2 when a step fails another way.
set -uo pipefail

ref="${1:-main}"
work="react-native-$ref"

rm -rf "$work"
if ! git clone --quiet --depth 1 --branch "$ref" https://github.com/react/react-native "$work"; then
  echo "SUMMARY: cloning react/react-native at $ref failed"
  exit 2
fi
cd "$work" || exit 2

system="$(uname -sm)" || exit 2
node_version="$(node --version)" || exit 2
yarn_version="$(yarn --version)" || exit 2
commit="$(git rev-parse HEAD)" || exit 2
echo "$system, node $node_version, yarn $yarn_version, react-native $commit"
echo "--- git status --short before the install:"
git status --short

echo "--- yarn install --frozen-lockfile --non-interactive:"
yarn install --frozen-lockfile --non-interactive > ../yarn-install.log 2>&1
install_status=$?
grep -E '^\$ |Hermes compiler|^yarn (workspace|add) v|Saved lockfile|Your lockfile needs to be updated|^error ' ../yarn-install.log
echo "exit $install_status"

if [[ $install_status -ne 0 ]]; then
  if grep -q 'Your lockfile needs to be updated' ../yarn-install.log; then
    echo "SUMMARY: yarn install --frozen-lockfile refuses to write yarn.lock"
    exit 0
  fi
  tail -n 20 ../yarn-install.log
  echo "SUMMARY: yarn install failed before the check, see the lines above"
  exit 2
fi

echo "--- git status --short after the install:"
changed="$(git status --short)"
echo "$changed"

if [[ -z $changed ]]; then
  echo "SUMMARY: yarn install --frozen-lockfile leaves the tree as committed"
  exit 0
fi

if ! grep -qE ' (packages/react-native/package\.json|yarn\.lock)$' <<< "$changed"; then
  echo "SUMMARY: the install changed tracked files other than packages/react-native/package.json and yarn.lock"
  exit 2
fi

echo "--- git diff -- packages/react-native/package.json:"
git diff -- packages/react-native/package.json
echo "--- git diff --stat -- yarn.lock:"
git diff --stat -- yarn.lock
echo "SUMMARY: yarn install --frozen-lockfile exits 0 and leaves packages/react-native/package.json and yarn.lock modified"
exit 1
