## IINA Translation Utility [![Build Status](https://travis-ci.org/iina/iina-translation-utility.svg?branch=master)](https://travis-ci.org/iina/iina-translation-utility)

Update `.strings` files with minimal effort.

This application is expected to be used only for IINA.

## Usage

**Load The Project**

1. Launch the application. <kbd>⌘O</kbd> and open the `iina.xcodeproj` file.
2. Now the project should be loaded. Two popup buttons will show up in the toolbar; the left one indicates the current language, and the right one is the base language to be compared to. Select your language for the left popup button.
3. All strings files should be listed in the sidebar, with an indicator showing how many errors are detected in the file.

**Add Translations**

1. Double click a row to edit the translation.
2. Press <kbd>Enter</kbd> to commit the change and save the file. 
3. Press <kbd>⌘Enter</kbd> to all above and continue to the next key.
4. Click "Next issue" to jump to the next error.
5. Right click on a file and choose "reload all" to reload the file from disk.
6. Right click on a translation to update all keys with the same base translation. This is especially useful for some words like "Save" and "Cancel".

**WARNING**

1. This application is not bug-free.
2. So backup/commit the project before running it. `git checkout -- /path/to/file` could recover a single file.
3. Keys that no longer exist in the base strings/xib file will be skipped during saving. Open an issue in case of a valid key got deleted.
