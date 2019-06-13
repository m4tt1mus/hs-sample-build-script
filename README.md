# Sample Build Script

This is a sample build script for .NET Core projects using Psake.

## Installation

You'll need PowerShell 5+ installed, or PowerShell Core.  To install the dependencies, use the setup script:

```
setup.cmd
```

Or if you're already in PowerShell:

```
./setup.ps1
```

You'll need to run this once to setup the dependencies for Psake.

## Usage

View documentation on build tasks
```
psake ?
```

To use this in your own projects, just copy these files / folders into the root of your project:

```
psake-build-helpers.ps1
psake.cmd
psakefile.ps1
setup.cmd
setup.ps1
tools/
```

Then you should customize `setup.ps1` to include anything else you need for your build, and customize `psakefile.ps1` to add any other useful tasks you need.


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.


## License
[MIT](https://choosealicense.com/licenses/mit/)