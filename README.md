# tmxgen

A collection of tools for generating TMX files from various sources.

Currently supported:

- [Apple glossaries](https://developer.apple.com/downloads/?name=glossaries)
- Android SDK strings
- [CLDR](http://cldr.unicode.org/index): Unicode Common Locale Data Repository

# Usage

Run `make SRC_LANG=xx TRG_LANG=yy` from the root of the repository to generate
all TMXs for the specified languages.

# Requirements

These external software packages must be installed and available on the PATH:

- [xmlstarlet](http://xmlstar.sourceforge.net/)
- xsltproc (part of [libxslt](http://xmlsoft.org/libxslt/))
- rainbow (part of [Okapi](http://okapiframework.org/))

The above are all available in [MacPorts](https://www.macports.org/).

See also [special instructions for Apple glossaries](vendor/apple/README.md).

# License

MIT
