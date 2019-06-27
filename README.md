<img src="./screenshot/highlight-matching-tag.gif">

# What is highlight-matching-tag?
HTML template is complicated, sometimes it is very difficult to find matching tag.
This plugin will highlight matching tag instantaneously.

## Installation
Clone or download this repository (path of the folder is the `<path-to-highlight-matching-tag>` used below).

In your `~/.emacs`, add the following two lines:
```Elisp
(add-to-list 'load-path "<path-to-highlight-matching-tag>") ; add highlight-matching-tag to your load-path
(require 'highlight-matching-tag)
(highlight-matching-tag 1)
```

Note, this plugin depend on ```web-mode```, you need make sure install ```web-mode``` first.
