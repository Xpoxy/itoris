# itoris

A text editor utility wrapper. Sets up hooks for `inotify` events then runs your
`$EDITOR` program.

# Dependencies
- `bash`
- `readlink`
- `jq`
- `libinotify-tools`
- `python3` to run python scripts under `./scripts`, optional

# Installation

Clone the repository, then run the install script:
```
$ git clone https://codeberg.org/yarkin/itoris
$ cd itoris

for local installation:
$ ./install

for global installation:
$ sudo ./install
```

Then, run itoris with a project directory:
```
$ itoris ~/my-project
```
