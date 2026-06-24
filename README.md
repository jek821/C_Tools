# C Tools

Reimplementations of standard Unix CLI tools written in C from scratch.

## Why

Most real-world projects are large enough that you spend most of your time thinking about architecture, abstractions, and coordination — not the code itself at a functional level. These small, self-contained programs flip that: each one is a focused exercise where the interesting work is in getting the low-level details right.

The secondary goal is building fluency with the Unix programming interface — syscalls, file descriptors, error handling, process semantics — as groundwork toward eventually contributing to the Linux kernel.

## Platform

These tools use POSIX syscalls (`open`, `read`, `write`, `close`) and will work on any Unix or Unix-like system: **Linux, macOS, and BSDs**. They will not work on Windows without a compatibility layer like WSL.

## Principles

Each tool is written with the following in mind:

- **Use the Unix API directly.** No wrappers around `open`, `read`, `write`, `close` — the point is to work at the interface, not above it.
- **Handle errors correctly.** Every syscall return value is checked. Partial writes are retried. Resources are cleaned up on failure paths.
- **Keep it simple and self-contained.** No unnecessary dependencies or abstractions beyond what the problem requires.

## Naming conventions

Every tool follows the same layout so the build and tooling work without per-tool special-casing:

- **Directory:** `jek_<tool>` — *with* an underscore (e.g. `jek_cat`, `jek_wc`, `jek_ls`).
- **Source, header, and binary:** `jek<tool>` — *no* underscore (e.g. `jekcat.c`, `jekwc.h`, the `jekls` binary).

So a tool named `foo` lives in `jek_foo/` and contains:

| File | Purpose |
|------|---------|
| `jekfoo.c` | Source |
| `jekfoo.h` | Header with prototypes (and any shared types) |
| `Makefile` | Builds `jekfoo`, with `install` / `uninstall` / `clean` / `test` targets |
| `test.sh` | Test suite, runnable via `make test` |

The compiled binary is `jek_foo/jekfoo` (no extension). The root `.gitignore` relies on this convention — it ignores `jek_*/jek*` while keeping `*.c` / `*.h` / `*.sh`, so build artifacts are never committed and **no `.gitignore` edits are needed when you add a new tool.**

## Tools

| Tool | Description |
|------|-------------|
| [`jek_cat`](#jek_cat) | Reads a file and writes its contents to stdout, handling partial writes and read errors |
| [`jek_wc`](#jek_wc) | Counts bytes, lines, and/or words in a file, selected by flags |
| [`jek_ls`](#jek_ls) | Lists the contents of the current directory, with modification times and color for subdirectories |

---

### jek_cat

A reimplementation of [`cat(1)`](https://man7.org/linux/man-pages/man1/cat.1.html).

**Usage**

```sh
jekcat <file>
```

**Syscalls used**

| Syscall | Man page |
|---------|----------|
| `open` | [open(2)](https://man7.org/linux/man-pages/man2/open.2.html) |
| `read` | [read(2)](https://man7.org/linux/man-pages/man2/read.2.html) |
| `write` | [write(2)](https://man7.org/linux/man-pages/man2/write.2.html) |
| `close` | [close(2)](https://man7.org/linux/man-pages/man2/close.2.html) |

---

### jek_wc

A reimplementation of [`wc(1)`](https://man7.org/linux/man-pages/man1/wc.1.html). Flags control which counts are shown; any combination is valid.

**Usage**

```sh
jekwc [-b] [-l] [-w] <file>
```

| Flag | Effect |
|------|--------|
| `-b` | Print byte count |
| `-l` | Print line count |
| `-w` | Print word count |

**Syscalls used**

| Syscall | Man page |
|---------|----------|
| `open` | [open(2)](https://man7.org/linux/man-pages/man2/open.2.html) |
| `read` | [read(2)](https://man7.org/linux/man-pages/man2/read.2.html) |
| `close` | [close(2)](https://man7.org/linux/man-pages/man2/close.2.html) |

---

### jek_ls

A reimplementation of [`ls(1)`](https://man7.org/linux/man-pages/man1/ls.1.html). Lists entries in the current directory, printing each entry's name and last modification time. Directory entries are highlighted in blue.

**Usage**

```sh
jekls
```

**APIs used**

| Function | Man page |
|----------|----------|
| `opendir` | [opendir(3)](https://man7.org/linux/man-pages/man3/opendir.3.html) |
| `readdir` | [readdir(3)](https://man7.org/linux/man-pages/man3/readdir.3.html) |
| `stat` | [stat(2)](https://man7.org/linux/man-pages/man2/stat.2.html) |

---

## Build system

The repo uses a two-level Makefile structure:

- **Root `Makefile`** — orchestrates all tools from one place. Run from the repo root.
- **Per-tool `Makefile`** — builds and installs that tool in isolation. Run from inside a tool's directory.

Both support the same targets (`all`, `install`, `uninstall`, `clean`, `test`). The root one just delegates each target down to every tool's Makefile using `make -C <dir>`.

### Install everything at once

```sh
make install
```

This builds and installs all tools to `~/.local/bin/`.

### Work on a single tool

```sh
cd jek_cat
make install
```

Useful when you only want to build or reinstall one tool without touching the others.

### All make targets

| Command | Effect |
|---------|--------|
| `make` | Compile all tools (no install) |
| `make install` | Compile and install all tools to `~/.local/bin` |
| `make uninstall` | Remove all tools from `~/.local/bin` |
| `make clean` | Remove compiled binaries from all project folders |
| `make test` | Build and run each tool's test suite (tools without tests are skipped) |

The per-tool Makefiles support the same commands from inside the tool's directory.

### Compiling directly (strict checks)

The Makefiles compile every tool with a strict warning set so mistakes are caught at compile time rather than at runtime. To compile a tool by hand with the same checks:

```sh
gcc -std=c11 -D_POSIX_C_SOURCE=200809L \
    -Wall -Wextra -Wpedantic -Wshadow \
    -Wstrict-prototypes -Wmissing-prototypes -Wconversion -Werror \
    -o jekwc jekwc.c
```

- `-std=c11 -Wpedantic` — strict ISO C11, no silent compiler extensions.
- `-D_POSIX_C_SOURCE=200809L` — **required.** Strict ISO mode hides the POSIX API (`open`, `read`, `getopt`, …); this macro exposes it. Without it the build fails with "implicit declaration of `getopt`".
- `-Wall -Wextra -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wconversion` — the warning set.
- `-Werror` — every warning is a build failure.

**If your shell says "command not found"** after installing, `~/.local/bin` is not in your `PATH`. Add this line to your `~/.bashrc` (or `~/.zshrc` if you use zsh):

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell with `source ~/.bashrc`.

## Status

This is an ongoing project. More tools will be added over time.
