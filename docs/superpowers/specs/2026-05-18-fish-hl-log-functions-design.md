# Fish Functions Wrapping `hl` for DevOps Log Viewing

## Goal

Provide ergonomic fish-shell functions that pipe `kubectl logs`, `stern`, and
file/stdin sources through [`hl`](https://github.com/pamburus/hl) with sensible
DevOps defaults. Functions live in the dotfiles repo and are symlinked into
`~/.config/fish/`.

## Non-Goals

- No log shipping, no persistence, no dashboards.
- No replacement for `k9s`, `kdash`, `kubie`.
- No new theme management — use `hl` defaults.
- No multi-cluster context juggling — relies on current `kubectl` context.

## Dependencies (assumed installed)

| Tool | Source | Required by |
|------|--------|-------------|
| `hl` | Homebrew (already in `flake.nix`) | all |
| `kubectl` | Homebrew (already in `flake.nix`) | `klog*` |
| `fzf` | Homebrew (already in `flake.nix`) | `klogp` |
| `stern` | User installs manually | `slog` |
| `fish` ≥ 3.6 | Homebrew | all |

If a dependency is missing, the function prints a one-line error pointing at
the formula and exits non-zero. No fallback.

## Files Added

```
configs/fish/functions/klog.fish
configs/fish/functions/klogp.fish
configs/fish/functions/klogl.fish
configs/fish/functions/slog.fish
configs/fish/functions/logv.fish
configs/fish/completions/klog.fish
configs/fish/completions/slog.fish
configs/fish/fish_plugins
```

`fish_plugins` is referenced by `README.md` step 3 but does not currently
exist; the spec creates it so the documented `fisher update` flow works. Seed
with the plugins already documented in the README.

## Files Modified

- `README.md` — add symlink instructions for `configs/fish/functions/` and
  `configs/fish/completions/` into `~/.config/fish/`.

## Function Contracts

All functions accept a `--` separator. Everything after `--` is forwarded
verbatim to `hl` (e.g. `-l error`, `-f msg,level`, `--theme tokyonight`).

### `klog`

```
klog POD [-n NS] [-f] [-c CON] [-s SINCE] [-p] [-- HL_ARGS...]
```

- `kubectl logs $pod` piped to `hl`.
- `-f` → follow (no pager, no `--since` default).
- Otherwise `--since=10m` default unless `-s` given.
- `-p` → `--previous`.
- Non-follow → `hl -P` (pager via `less`).

### `klogp`

```
klogp [-n NS] [-f] [-- HL_ARGS...]
```

- `kubectl get pods [-n NS] -o name | fzf` to choose pod.
- Delegates to `klog`.
- Empty selection → exit 130, no error message.

### `klogl`

```
klogl SELECTOR [-n NS] [-f] [-s SINCE] [-- HL_ARGS...]
```

- `kubectl logs -l SELECTOR --all-containers --max-log-requests=20 ... | hl`.
- Same `--since`/`-f`/pager rules as `klog`.

### `slog`

```
slog PATTERN [-n NS] [--tail N] [-- HL_ARGS...]
```

- `stern PATTERN [-n NS] --tail=$N --output=json | hl`.
- `--tail` default = 50.
- Always follows (stern's normal mode); no `-f` flag.
- Uses `--output=json` so `hl` sees structured records.

### `logv`

```
logv [FILE...] [-- HL_ARGS...]
```

- No args → `hl` on stdin (pipe target).
- With files → `hl FILE...` (delegates file IO to `hl`).
- Adds `-P` only when stdout is a TTY and no `-f` in `HL_ARGS`.

## Completions

### `klog.fish` completion

- Arg 1 (pod): `kubectl get pods -o name [-n NS] | sed 's|pod/||'`.
- `-n` value: `kubectl get ns -o name | sed 's|namespace/||'`.
- `-c` value: containers of the pod resolved from prior tokens.
- `-s` value: static list `30s 1m 5m 10m 30m 1h 6h 24h`.

### `slog.fish` completion

- `-n` value: namespaces (same as above).
- `--tail` value: static `10 50 100 500 1000`.

## Error Handling

- Each function starts with a `for tool in hl kubectl ...; command -q $tool; or
  return` style guard, with a single `echo` to stderr naming the missing tool.
- All functions return `$kubectl_status` or `$stern_status` on upstream
  failure (no swallowing).

## README Update

Add a new step under "Fish Shell Setup", after the current `config.fish`
symlink:

```bash
ln -sf "$PWD/configs/fish/functions"   ~/.config/fish/functions
ln -sf "$PWD/configs/fish/completions" ~/.config/fish/completions
```

Add a short subsection "Log Viewing" listing the five functions with one-line
descriptions.

## Testing Strategy

Fish functions are hard to unit-test in CI without a live cluster. Strategy:

1. **Static checks** — `fish -n FILE` syntax-check each function and
   completion file (runs locally, no cluster needed).
2. **Smoke tests** — manual checklist in the spec / PR description:
   - `logv` from piped JSON file → colored output.
   - `klog` against a known pod in `kube-system` → colored output, pager on
     exit.
   - `klog -f` → live tail, Ctrl-C clean.
   - `klogp` → fzf opens, selection runs `klog`.
   - `slog kube-` against `kube-system` → multi-pod stream.
   - Completion: type `klog <TAB>` → pod list appears.
3. **Missing-tool path** — temporarily rename `stern` binary, run `slog`,
   confirm one-line error and non-zero exit.

No automated test harness added.

## Open Questions

None. Defaults frozen by user choice: Option B + fzf picker + stern + default
`hl` theme. Stern installed manually by user.
