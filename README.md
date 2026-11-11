# `yarn install --frozen-lockfile` on a clean clone of React Native rewrites tracked files

Made from React Native's reproducer template. The defect is in the `react/react-native` repository's own install, so `ReproducerApp` is the template's, unchanged, and `reproduce.sh` runs the steps on a fresh clone:

```sh
./reproduce.sh [<react-native branch or tag, main by default>]
```

It needs git, Node and yarn 1. It clones `react/react-native` into `react-native-<ref>`, runs `yarn install --frozen-lockfile --non-interactive` at its root and prints `git status --short` before and after.

It exits 1 while the install leaves `packages/react-native/package.json` or `yarn.lock` modified, 0 once the install leaves the tree as committed or refuses to write `yarn.lock`, and 2 when a step fails another way.
