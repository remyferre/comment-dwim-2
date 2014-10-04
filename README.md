# Comment-dwim-2

`comment-dwim-2` is a replacement for the Emacs built-in command `comment-dwim` which includes more comment features, including:

* commenting/uncommenting the current line (or region, if active)
* inserting an inline comment
* killing the inline comment
* reindenting the inline comment

As its name suggests, `comment-dwim-2` picks up one behavior depending on the context but contrary to `comment-dwim` **can also be repeated several times to switch between the different behaviors**.

# Demo

`comment-dwim-2` repeated 3 times:

![general behavior of comment-dwim-2](http://remyferre.github.io/images/cd2-general.gif)

# How to use

`comment-dwim-2` is not bound to any key, so you need to set up you own keybinding first. For instance:

    (global-set-key (kbd "M-;") 'comment-dwim-2)

# Installation

This package can be installed from [MELPA](http://melpa.milkbox.net/#/).

# Detailed use cases

## Commenting/uncommenting the region

![commenting/uncommenting the region with comment-dwim-2](http://remyferre.github.io/images/cd2-region.gif)

## Commenting current line

![commenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-comment.gif)

## Uncommenting current line

![uncommenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-uncomment.gif)

## Insert comment (repeated twice)

![inserting comment with comment-dwim-2](http://remyferre.github.io/images/cd2-insert-comment.gif)

## Kill comment (repeated twice)

![killing comment with comment-dwim-2](http://remyferre.github.io/images/cd2-kill-comment.gif)

## Reindent comment (called with a prefix argument)

![reindenting comment with comment-dwim-2](http://remyferre.github.io/images/cd2-reindent-comment.gif)

# Customization

An alternative behavior closer to what `comment-dwim` does is available. To use it, add this to your init file:

	(setq comment-dwim-2--inline-comment-behavior 'reindent-comment)

It basically swaps the killing and reindenting behavior, which means that repeating `comment-dwim-2` will by default reindent the comment instead of killing it, and that calling `comment-dwim-2` with a prefix argument will kill the comment instead of reindenting it.
