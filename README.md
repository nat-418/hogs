# Hogs 🐖🐖🐖
![Semantic Versioning 2.0.0]
![Conventional Commits 1.0.0]

Ever wonder which processes are hogging your ports? `hogs` will tell you.
`hogs` is a wrapper for `ss`, the standard Linux socket statistics tool.
`hogs` provides a simpler command-line interface and more easily digestible
output about what is happening on your system.

## Usage

```bash
$ hogs --tcp --ipv4
Address  Port  Process    PID    
0.0.0.0  8080  miniserve  1251227
```

### Options

| Option flag         | Description                                       |
| ------------------- | ------------------------------------------------- |
| `-all`              | Show all results, see [Permissions](#permissions) |
| `-ipv4`             | Show IPv4 addresses                               |
| `-ipv6`             | Show IPv6 addresses                               |
| `-tcp`              | Show TCP network                                  |
| `-udp`              | Show UDP network                                  |
| `-ip value`         | Lookup a given IP address                         |
| `-port value`       | Lookup a given port number                        |
| `-version`          | Print version number                              |

### Permissions

 Usually, an empty process name or PID means that the user does not have
 sufficient permissions to access that information. The most common cause
 of this is when a process is spawned by root or init. By default, `hogs`
 does not show results with an empty process name or PID.

## Installation

`hogs` is written in Tcl and uses the standard libarary `tcllib`;
the `ss` utility is also required. Simply copy the `hogs.tcl` script
somewhere on your `$PATH` and mark it executable. There is also a
Nix package available in my [Grimoire] repository.

### Dependencies

- Tcl version 8.6 or greater (`tclsh`, `tcllib`)
- `ss` (from `iproute2` version 6.5.0 or greater)


## Miscellaneous

Hogs is open-source software distributed under the 0BSD license.
To report bugs or view source code, see https://www.github.com/nat-418/hogs.


[Grimoire]: https://github.com/nat-418/grimoire
[Conventional Commits 1.0.0]: https://flat.badgen.net/badge/Conventional%20Commits/1.0.0/
[Semantic Versioning 2.0.0]:  https://flat.badgen.net/badge/Semantic%20Versioning/2.0.0/
