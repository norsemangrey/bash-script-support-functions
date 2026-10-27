A collection of helper scripts and functions to use in other bash scripts.

## Platform and environment detection

[platform.sh](./platform.sh) provides shared Linux deployment detection for the
Linux setup and dotfiles repositories. Source it from Bash after loading any
configuration overrides:

```bash
source "${scriptDirectory}/utils/platform.sh"
printf 'Platform: %s; environment: %s\n' "${platform}" "${environment}"
```

Use `utils/bash/platform.sh` instead when consuming it from the dotfiles repo.
The helper sets:

- `platform`: `wsl`, `hyperv`, `proxmox` (QEMU vendor), or `physical`.
- `environment`: `desktop` when the default systemd target is `graphical.target`
  and a desktop session or display manager is installed; otherwise `headless`.

Nonempty values other than `auto` are preserved as configuration overrides.
Sourcing is silent and does not parse the caller's arguments. The helper also
exposes `detectPlatform` and `detectEnvironment` for explicit detection.
It is for deployment scripts, not shell startup or agent initialization.

Run it directly with `bash platform.sh` or view help with
`bash platform.sh --help`. Run the regression tests with:

```bash
bash tests/platform-test.sh
```

## Updating consumers

Make shared utility changes in this repository, then test, commit, and push them
before updating consumers. In the setup repository, run
`git submodule update --init --remote -- utils`; in the dotfiles repository, run
`git submodule update --init --remote -- utils/bash`.
Commit each consumer's updated submodule pointer along with any dependent changes.
Normal deployments should use `git submodule update --init --recursive` to check
out the revisions pinned by the consuming repository.
