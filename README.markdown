# RRMMailLink


## Description

RRMMailLink is a simple plugin for OS X's Mail.app. If a valid URL exists on the pasteboard when Mail's "Edit -> Add Link..." sheet is displayed that URL's string value will automatically be copied into the sheet's text field. Why Mail.app doesn't do this by default seems odd.

Compatible with OS X 10.8+.

## Reasons for Existence

Aside from fixing one of my pet peeves with Mail.app, RRMMailLink provides a very straightforward example of how to create a Mail plugin bundle. Also, instead of attempting to directly link against one of Apple's private frameworks, RRMMailLink provides a simple implementation of Mike Ash's [Direct Override example](https://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html).

## Installation

    1. Download the source
    2. Build the Xcode project
    3. Quit Mail.app
    4. Copy RRMMailLink.mailbundle to ~/Library/Mail/Bundles
    5. Launch Mail.app

*NOTE: Bundles aren't loaded by Mail.app unless the following defaults are set via Terminal:*

* defaults write com.apple.mail EnableBundles -bool true
* defaults write com.apple.mail BundleCompatibilityVersion 4 
	* (or "Version 3"" for OS X 10.6)

## License

The source code is distributed under the nonviral [MIT License](http://opensource.org/licenses/mit-license.php). It's the simplest, most permissive license available.

## Version History

* **v1.0:** Jan 3, 2014

    * Moved to github

