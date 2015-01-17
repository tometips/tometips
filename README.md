ToME Tips
=========

Auto-generated web-based spoilers for [ToME](http://te4.org/).

Development instructions:

1. Make sure that you have the prerequisites installed:
 * Lua - Currently, Lua 5.1.x is required.
 * [make](https://www.gnu.org/software/make/)
 * The Git command-line client
 * [ImageMagick](http://www.imagemagick.org/)
 * [Handlebars](https://www.npmjs.org/package/handlebars), installed globally via [Node.js](http://nodejs.org/)'s `npm`.
 * The current build system uses symlinks and so requires Cygwin or a Unix-like operating system.
2. Run `make`.  This will automatically clone the [ToME repository](http://git.net-core.org/tome/t-engine4) and generate spoilers from the most recent ToME release.
3. Check the Makefile for switching between release and development versions of ToME, pretty-printing JSON spoiler information for debugging, and more.

