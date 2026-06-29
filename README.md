# killport

Free up a port by killing whatever is listening on it. One command, no `lsof | grep | awk | kill` dance.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

```console
$ killport 3000
port 3000: killed node (pid 48213)
```

## Why

You know the one: _"Error: listen EADDRINUSE: address already in use :::3000"_. `killport 3000` and you're back to work.

## Install

### Homebrew

```sh
brew install shint-mcguff/tap/killport
```

### From source

```sh
git clone https://github.com/shint-mcguff/killport
cd killport
swift build -c release
cp .build/release/killport /usr/local/bin/
```

## Usage

```sh
killport 3000              # graceful SIGTERM to whatever listens on 3000
killport 3000 8080 5173    # free several ports at once
killport -n 3000           # dry run: show what holds the port, kill nothing
killport -f 3000           # SIGKILL (-9) when a process won't go quietly
killport -q 3000           # quiet: print only errors
```

Both TCP listeners and UDP-bound sockets are matched. TCP is restricted to the
`LISTEN` state, so an outbound connection that merely _uses_ that remote port is
never touched.

### Exit codes

| Code | Meaning |
|------|---------|
| `0`  | At least one process was killed (or shown, in dry-run). |
| `1`  | A kill failed — e.g. the process is owned by another user (`sudo killport …`). |
| `2`  | Nothing was listening on any of the given ports. |

The distinct codes make `killport` safe to script: `killport 3000 || echo "was already free"`.

## License

MIT — see [LICENSE](LICENSE).
