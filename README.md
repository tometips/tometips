ToME Tips
=========

Auto-generated web-based spoilers for [ToME](http://te4.org/).

Development instructions:

1. Make sure that you have the prerequisites installed:
 * LuaJIT - although Lua 5.1.x should also work if you edit the Makefile.
 * Additional Lua libraries - currently, [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)
 * [make](https://www.gnu.org/software/make/)
 * The Git command-line client
 * [ImageMagick](http://www.imagemagick.org/)
 * [Pngcrush](http://pmt.sourceforge.net/pngcrush/)
 * [Handlebars](https://www.npmjs.org/package/handlebars), installed globally via [Node.js](http://nodejs.org/)'s `npm`.
 * The current build system uses symlinks and so requires a Unix-like operating system or Cygwin.
2. Run `make`.  This will automatically clone the [ToME repository](http://git.net-core.org/tome/t-engine4) and generate spoilers from the most recent ToME release.
3. Check the Makefile for  pretty-printing JSON spoiler information for debugging and more.

