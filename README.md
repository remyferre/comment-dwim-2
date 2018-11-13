# Comment-dwim-2

`comment-dwim-2` is a replacement for the Emacs' built-in command `comment-dwim`, which includes more features, and allows you to:

* comment/uncomment the current line (or region, if active)
* insert/kill end-of-line comments
* reindent end-of-line comments

`comment-dwim-2` picks one behavior depending on the context but **can also be repeated several times to switch between the different possible behaviors**.

# Demo

`comment-dwim-2` used 3 times in a row:

![general behavior of comment-dwim-2](http://remyferre.github.io/images/cd2-general.gif)

# How to use

You need to add your own key binding first, for instance:

    (global-set-key (kbd "M-;") 'comment-dwim-2)

# Installation

This package can be installed from [MELPA](http://melpa.org/#/).

# Detailed use cases

## Commenting/uncommenting the region

![commenting/uncommenting the region with comment-dwim-2](http://remyferre.github.io/images/cd2-region.gif)

## Commenting current line

![commenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-comment.gif)

## Uncommenting current line

![uncommenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-uncomment.gif)

## Insert comment (repeat the command)

![inserting comment with comment-dwim-2](http://remyferre.github.io/images/cd2-insert-comment.gif)

## Kill comment (repeat the command)

![killing comment with comment-dwim-2](http://remyferre.github.io/images/cd2-kill-comment.gif)

## Reindent comment (call the command with a prefix argument)

![reindenting comment with comment-dwim-2](http://remyferre.github.io/images/cd2-reindent-comment.gif)

# Customization

When commenting a region, `comment-dwim-2` will by default comment the entirety of the lines that the region spans (i.e. a line will be fully commented even if it is partly selected):
In Lisp modes, however, `comment-dwim-2` will strictly comment the region as commenting whole lines could easily lead to unbalanced parentheses.

If you always want to fully comment lines (Lisp modes included), add this to your configuration file:

	(setq cd2/region-command 'cd2/comment-or-uncomment-lines)

If you only want to comment the selected region (like `comment-dwim` does), add this:

	(setq cd2/region-command 'cd2/comment-or-uncomment-region)
