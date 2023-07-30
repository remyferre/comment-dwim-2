;;; comment-dwim-2.el --- An all-in-one comment command to rule them all

;; Copyright (C) 2014-2019  Rémy Ferré

;; Author: Rémy Ferré <dev@remyferre.net>
;; Version: 1.4.3
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/remyferre/comment-dwim-2
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; # Description
;;
;; This package provides a replacement for `comment-dwim' called
;; `comment-dwim-2', which includes more features and allows you to
;; comment / uncomment / insert comment / kill comment and indent
;; comment depending on the context.  The command can be repeated
;; several times to switch between the different possible behaviors.
;;
;; # Demonstration
;;
;; You can find several gifs showing how the command works on Github:
;; https://github.com/remyferre/comment-dwim-2
;;
;; # How to use
;;
;; You need to add your own key binding first, for instance:
;;
;;   (global-set-key (kbd "M-;") 'comment-dwim-2)
;;
;; # Customization
;;
;; ## Commenting region
;;
;; When commenting a region, `comment-dwim-2' will by default comment
;; the entirety of the lines that the region spans (i.e. a line will
;; be fully commented even if it is partly selected).  In Lisp modes,
;; however, `comment-dwim-2' will strictly comment the region as
;; commenting whole lines could easily lead to unbalanced parentheses.
;; You can customize this behavior.
;;
;; If you always want to fully comment lines (Lisp modes included),
;; add this to your configuration file:
;;
;;   (setq cd2/region-command 'cd2/comment-or-uncomment-lines)
;;
;; If you only want to comment the selected region (like
;; `comment-dwim' does), add this:
;;
;;   (setq cd2/region-command 'cd2/comment-or-uncomment-region)
;;
;; # Org-mode
;;
;; For org-mode, consider using `org-comment-dwim-2':
;;
;;   (define-key org-mode-map (kbd "M-;") 'org-comment-dwim-2)
;;
;; ## Behavior when command is repeated
;;
;; `comment-dwim-2' will by default try to kill any end-of-line
;; comments when repeated. If you wish to reindent these comments
;; instead, add this to your configuration file:
;;
;;   (setq comment-dwim-2--inline-comment-behavior 'reindent-comment)
;;
;; If you use this setting, you will still be able to kill comments by
;; calling `comment-dwim-2' with a prefix argument.

;;; Code:

(require 'cl-lib)
(require 'org)
(require 'ob-core)

(defvar comment-dwim-2--inline-comment-behavior 'kill-comment
  "Behavior of `comment-dwim-2' when repeated and at an inline comment.
Possible values are:

* \\='kill-comment     : Kill the inline comment (default)
* \\='reindent-comment : Reindent the inline comment

When a behavior is chosen, the other one is still made available
by calling `comment-dwim-2' with a prefix argument.")

(defvar cd2/inline-comment-behavior--wrong-value
  "Error: `comment-dwim-2--inline-comment-behavior' has an unknown value. Probably a typo."
  "Error message displayed when `comment-dwim-2--inline-comment-behavior' is set to a wrong value.")

(defun cd2/inline-comment-command ()
  "Command called by `comment-dwim-2' when repeated and at an inline comment.
The behavior depends on the value of `comment-dwim-2--inline-comment-behavior'"
  (cl-case comment-dwim-2--inline-comment-behavior
    (kill-comment     (cd2/comment-kill))
    (reindent-comment (comment-indent))
    (t (user-error cd2/inline-comment-behavior--wrong-value))))

(defun cd2/prefix-command ()
  "Command called by `comment-dwim-2' when called with a prefix argument.
The behavior is the one not chosen by the user in
`comment-dwim-2--inline-comment-behavior' so it can still be
available."
  (cl-case comment-dwim-2--inline-comment-behavior
    (kill-comment     (comment-indent))
    (reindent-comment (cd2/comment-kill))
    (t (user-error cd2/inline-comment-behavior--wrong-value))))

(defun cd2/comment-or-uncomment-region ()
  "Call `comment-or-uncomment-region' on current region."
  (comment-or-uncomment-region (region-beginning) (region-end)))

(defun cd2/comment-or-uncomment-lines ()
  "Toggle commenting on all the lines that the region spans."
  (if (eq (line-number-at-pos (point))
		  (line-number-at-pos (mark)))
	  (cd2/comment-or-uncomment-region)
	(comment-or-uncomment-region
	 (save-excursion (goto-char (region-beginning)) (line-beginning-position))
	 (if (= (region-end)
			(save-excursion (goto-char (region-end)) (line-beginning-position)))
		 (- (region-end) 1)
	   (save-excursion (goto-char (region-end)) (line-end-position))))))

(defun cd2/comment-or-uncomment-lines-or-region-dwim ()
  "Toggle commenting on lines or region depending on the mode.

In most modes, the command will toggle commenting on all the lines
that the region spans.
In Lisp-derived modes, however, the command applies strictly to the
region, as commenting whole lines would often results with
unbalanced parentheses."
  (if (derived-mode-p 'lisp-mode 'emacs-lisp-mode 'clojure-mode
					  'racket-mode 'scheme-mode)
	  (cd2/comment-or-uncomment-region)
	(cd2/comment-or-uncomment-lines)))

(defvar cd2/region-command 'cd2/comment-or-uncomment-lines-or-region-dwim
  "Command used for commenting/uncommenting current region.
Possible values are:

* `cd2/comment-or-uncomment-lines-or-region-dwim' (default)
* `cd2/comment-or-uncomment-lines'
* `cd2/comment-or-uncomment-region'")

(defun cd2/empty-line-p ()
  "Return true if current line contains only whitespace characters."
  (string-match "^[[:blank:]]*$"
				(buffer-substring (line-beginning-position)
								  (line-end-position))))

(defun cd2/fully-commented-line-p ()
  "Return true if current line is commented from its beginning.
Whitespace characters at the beginning of the line are ignored."
  (and (not (cd2/empty-line-p))
       (comment-only-p (save-excursion
						 (move-beginning-of-line 1)
						 (skip-chars-forward " \t")
						 (point))
					   (line-end-position))))

(defun cd2/face-is-at-pos-p (pos faces)
  "Return true if one of the given faces is at pos."
  (let* ((face-property (get-text-property pos 'face))
		 (faces-at-point (if (listp face-property) face-property (list face-property))))
	(cl-some (lambda (face) (member face faces-at-point)) faces)))

(defun cd2/within-comment-p (pos)
  "Return true if content at given position (POS) is within a comment."
  (cd2/face-is-at-pos-p pos '(font-lock-comment-face
							  font-lock-comment-delimiter-face)))

(defun cd2/line-contains-comment-p ()
  "Return true if current line contains a comment."
  (save-excursion
	(font-lock-fontify-region (line-beginning-position) (line-end-position)))
  (let ((eol (line-end-position)))
	(save-excursion
	  (move-beginning-of-line 1)
	  (while (and (/= (point) eol)
				  (not (cd2/within-comment-p (point))))
		(forward-char))
	  (cd2/within-comment-p (point)))))

(defun cd2/line-ends-with-multiline-string-p ()
  "Return true if current line ends inside a multiline string such that adding an end-of-line comment is meaningless."
  (let ((bol  (line-beginning-position))
		(eol  (line-end-position))
		(bol2 (line-beginning-position 2)))
    (and
     ;; End of line have string face..
     (save-excursion
       (font-lock-fontify-region bol eol)
	   (cd2/face-is-at-pos-p eol '(font-lock-string-face
								   font-lock-doc-face)))
     ;; ..and next line contains a string which begins at the same position
     (= (elt (save-excursion (syntax-ppss eol )) 8)
		(elt (save-excursion (syntax-ppss bol2)) 8)))))

(defun cd2/comment-kill ()
  "A clone of `comment-kill' which kills only one comment and does not re-indent the code."
  (comment-normalize-vars)
  (save-excursion
    (beginning-of-line)
    (let ((cs (comment-search-forward (line-end-position) t)))
      (when cs
		(goto-char cs)
		(skip-syntax-backward " ")
		(setq cs (point))
		(comment-forward)
		(kill-region cs (if (bolp) (1- (point)) (point)))))))

(defun cd2/uncomment-line ()
  "Uncomment current line."
  (uncomment-region (line-beginning-position) (line-end-position)))

(defun cd2/comment-line ()
  "Comment current line."
  ;; `comment-region' does not support empty lines, so we use
  ;; `comment-dwim' in such cases to comment the line
  (if (cd2/empty-line-p)
      (comment-dwim nil)
    (comment-region (line-beginning-position) (line-end-position))))

;;;###autoload
(defun comment-dwim-2 (&optional arg)
  "Call a comment command according to the context.

If the region is active, toggle commenting according to the value
of `cd2/region-command'.
Else, the function applies to the current line and calls a
different function at each successive call.  The algorithm is:
* First  call : Toggle line commenting
* Second call : - Kill end-of-line comment if present (1)
                - Insert end-of-line comment otherwise
Given an argument ARG, it reindents the inline comment instead (2).

You can also switch behaviors of (1) and (2) by setting
`comment-dwim-2--inline-comment-behavior' to \\='reindent-comment."
  (interactive "*P")
  (if (use-region-p)
	  (funcall cd2/region-command)
	(if arg
		(cd2/prefix-command)
      (if (cd2/fully-commented-line-p)
		  (progn
			(cd2/uncomment-line)
			(when (and (or (eq last-command 'comment-dwim-2)
						   (eq last-command 'org-comment-dwim-2))
					   (not (cd2/empty-line-p))
					   (not (cd2/line-ends-with-multiline-string-p))
					   (not (cd2/fully-commented-line-p)))
			  (if (cd2/line-contains-comment-p)
				  (cd2/inline-comment-command)
				(comment-indent)))) ; Insert inline comment
		(if (and (cd2/line-contains-comment-p)
				 (or (eq last-command 'comment-dwim-2)
					 (eq last-command 'org-comment-dwim-2)))
			(cd2/inline-comment-command)
		  (cd2/comment-line))))))

;;;###autoload
(defun org-comment-dwim-2 (&optional arg)
  "Call `comment-dwim-2' inside source blocks. Else, fallback to `org-toggle-comment'."
  (interactive "*P")
  (if (org-in-src-block-p t)
      (org-babel-do-in-edit-buffer (call-interactively 'comment-dwim-2))
    (call-interactively 'org-toggle-comment)))

(provide 'comment-dwim-2)
;;; comment-dwim-2.el ends here
