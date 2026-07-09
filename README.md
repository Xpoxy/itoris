# itoris

An everything-is-a-file text editor utility wrapper. Sets up hooks for `inotify`
events then runs your `$EDITOR` program.

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

**Note:** itoris will launch your text editor and exit when it exits, to make
sure itoris will not exit abruptly, set your `$EDITOR` environment variable:
```sh
# .bashrc.json (or your shell profile)
export EDITOR="zed --foreground"
```
or run itoris with the `$EDITOR` variable set:
```
$ EDITOR="zed --foreground" itoris ~/my-project
```

# Using itoris

After running your project, itoris will automatically launch your text editor
and look for the project itoris config file in project root: `.toris.json`.

## Project Configuration

`.toris.json` can be configured to use itoris bundles for specific target
directories in the project, an example with wildcards:
```json
{
    "profiles": [
        {
            "bundle": "python",
            "targets": [
                "py",
                "py-scripts/*"
            ]
        }
    ]
}
```
This config will look for the `py` directory and the children of `py-scripts`
in project root and assign the `python` bundle to run under those targeted
directories.

## Bundles

Bundles can exist globally in the itoris installation directory:
- `/opt/itoris/bundles` for global installations
- `~/.local/itoris/bundles` for local installations

Or, directly in the project root. Project bundles take priority over global
bundles. The `"bundle"` field in the configuration is treated as a path, so
`.toris/<bundle>` can be used to hide bundles away.

Bundles are expected to have a `calls` subdirectory under them, and under
`calls` inotify event hook directories. Every executable is called i
alphabetical order inside those hook directories. Symlinks are suggested to
call the same script from multiple hooks.

## Hooks

All executables are called with these command line arguments:
- `$1`: The profile target root, this is not the same as project root. This
  is defined in the `"targets"` field under profile configuration.
- `$2`: Changed file/directory path.

Available inotify hooks:
- `add`: Called when a file/directory gets added. (created or moved in)
- `close`: Called when a file gets closed. (Stopped reading/writing)
- `create`: Called when a file/directory gets created.
- `delete`: Called when a file/directory gets deleted.
- `first-save`: Called once when a file gets saved after it's creation.
- `move`: Called when a file/directory gets moved anywhere.
- `move-in`: Called when a file/directory gets moved in the target.
- `move-out`: Called when a file/directory gets moved outside the target.
- `read`: Called when a file gets read.
- `remove`: Called when a file/directory gets removed. (deleted or moved out)
- `save`: Called when a file gets saved.

## Examples

Examples are available under `project-templates` in repo root.

