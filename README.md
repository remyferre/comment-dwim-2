# Comment-dwim-2

`comment-dwim-2` is a replacement for the Emacs built-in command `comment-dwim` which includes more comment features, including:

* commenting/uncommenting the current line (or region, if active)
* inserting an end-of-line comment
* killing the end-of-line comment

As its name suggests, `comment-dwim-2` picks up one behavior depending on the context but contrary to `comment-dwim` **can also be repeated several times to switch between the different behaviors**.

# Demo

`comment-dwim-2` repeated 3 times:

![general behavior of comment-dwim-2](http://remyferre.github.io/images/cd2-general.gif)

# How to use

`comment-dwim-2` is not bound to any key, so you need to set up you own keybinding first. For instance:

    (global-set-key (kbd "M-;") 'comment-dwim-2)

# Detailed use cases

## Commenting/uncommenting the region

![commenting/uncommenting the region with comment-dwim-2](http://remyferre.github.io/images/cd2-region.gif)

## Commenting current line

![commenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-comment.gif)

## Uncommenting current line

![uncommenting current line with comment-dwim-2](http://remyferre.github.io/images/cd2-uncomment.gif)

## Insert comment

![inserting comment with comment-dwim-2](http://remyferre.github.io/images/cd2-insert-comment.gif)

## Kill comment

![killing comment with comment-dwim-2](http://remyferre.github.io/images/cd2-kill-comment.gif)
