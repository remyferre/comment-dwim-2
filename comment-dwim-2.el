;;; comment-dwim-2.el --- An all-in-one comment command to rule them all

;; Copyright (C) 2014  Rémy Ferré

;; Author: Rémy Ferré <remy-ferre@laposte.net>
;; Version: 1.2.1
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
;; This package provides a replacement for `comment-dwim', `comment-dwim-2',
;; which includes more comment commands than its predecessor and allows to
;; comment / uncomment / insert comment / kill comment / indent comment
;; depending on the context. The command can be repeated several times to
;; switch between the different possible behaviors.
;;
;; # Demonstration
;;
;; Go to the github page to see an animated demonstration of the command.
;; https://github.com/remyferre/comment-dwim-2
;;
;; # How to use
;;
;; As the command is unbound, you need to set up you own keybinding first,
;; for instance:
;;
;;   (global-set-key (kbd "M-;") 'comment-dwim-2)
;;
;; # Customization
;;
;; Contrary to `comment-dwim', `comment-dwim-2' will by default kill an
;; inline comment if it encounters one when being repeated. If you prefer
;; the `comment-dwim' behavior (which is to reindent the inline comment),
;; set comment-dwim-2--inline-comment-behavior to 'reindent-comment.
;;
;;   (setq comment-dwim-2--inline-comment-behavior 'reindent-comment)
;;
;; Whatever you choose between killing or reindenting, the other behavior
;; is still made available by calling `comment-dwim-2' with a prefix
;; argument.

;;; Code:

(defvar comment-dwim-2--inline-comment-behavior 'kill-comment
  "Behavior of `comment-dwim-2' when it is being repeated and is
encountering an inline comment. Possible values are:

* 'kill-comment     : Kill the inline comment (default)
* 'reindent-comment : Reindent the inline comment

When a behavior is chosen, the other one is still made available
by calling `comment-dwim-2' with a prefix argument.")

(defvar cd2/inline-comment-behavior--wrong-value
  "Error: `comment-dwim-2--inline-comment-behavior' has an unknown value. Probably a typo."
  "Error message displayed when
`comment-dwim-2--inline-comment-behavior' is set to a wrong value")

(defun cd2/inline-comment-function ()
  "Function called by `comment-dwim-2' when it is being repeated
and is encountering an inline comment. The behavior depends on
the value of `comment-dwim-2--inline-comment-behavior'"
  (case comment-dwim-2--inline-comment-behavior
    ('kill-comment     (cd2/comment-kill))
    ('reindent-comment (comment-indent))
    (t (user-error cd2/inline-comment-behavior--wrong-value))))

(defun cd2/prefix-function ()
  "Function called by `comment-dwim-2' when it is called with a
prefix argument. The behavior is the one not chosen by the user
in `comment-dwim-2--inline-comment-behavior' so it can still be
available."
  (case comment-dwim-2--inline-comment-behavior
    ('kill-comment     (comment-indent))
    ('reindent-comment (cd2/comment-kill))
    (t (user-error cd2/inline-comment-behavior--wrong-value))))

(defun cd2/empty-line-p ()
  "Return true if current line contains only whitespace
characters."
  (string-match "^[[:blank:]]*$"
		(buffer-substring (line-beginning-position)
				  (line-end-position))))

(defun cd2/fully-commented-line-p ()
  "Returns true if current line is commented from its beginning.
Whitespace characters at the beginning of the line are ignored."
  (interactive)
  (and (not (cd2/empty-line-p))
       (comment-only-p (save-excursion
		    (move-beginning-of-line 1)
		    (skip-chars-forward " \t")
		    (point))
		  (line-end-position))))

(defun cd2/within-comment-p (pos)
  "Returns true if content at given position is within a comment."
  (or (eq font-lock-comment-face
	  (get-text-property pos 'face))
      (eq font-lock-comment-delimiter-face
	  (get-text-property pos 'face))))

(defun cd2/line-contains-comment-p ()
  "Returns true if current line contains a comment."
  (let ((eol (line-end-position)))
    (save-excursion
      (move-beginning-of-line 1)
      (while (and (/= (point) eol)
 		  (not (cd2/within-comment-p (point))))
 	(forward-char))
      (cd2/within-comment-p (point)))))

(defun cd2/line-ends-with-multiline-string-p ()
  "Return true if current line ends inside a multiline string such
that adding an end-of-line comment is meaningless."
  (let ((bol  (line-beginning-position))
	(eol  (line-end-position))
	(bol2 (line-beginning-position 2)))
    (and
     ;; End of line have string face..
     (save-excursion
       (font-lock-fontify-region bol eol)
       (or (eq font-lock-string-face (get-text-property eol 'face))
	   (eq font-lock-doc-face    (get-text-property eol 'face))))
     ;; ..and next line contains a string which begins at the same position
     (= (elt (save-excursion (syntax-ppss eol )) 8)
	(elt (save-excursion (syntax-ppss bol2)) 8)))))

(defun cd2/comment-kill ()
  "A clone of `comment-kill' which kills only one comment and
does not re-indent the code."
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

If the region is active, call `comment-or-uncomment-region' to
toggle comments.
Else, the function applies to the current line and calls a
different function at each successive call. The behavior is:
* First  call : Toggle line commenting
* Second call : - Kill inline comment if one is present (1)
                - Insert inline comment otherwise
Given an argument, it reindents the inline comment instead (2).

Please note that the behavior of `comment-dwim-2' when
encountering an inline comment can be customized. Setting
`comment-dwim-2--inline-comment-behavior' to 'reindent-comment
will swap (1) and (2)."
  (interactive "P")
  (if (use-region-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (if arg
	(cd2/prefix-function)
      (if (cd2/fully-commented-line-p)
	  (progn
	    (cd2/uncomment-line)
	    (when (and (eq last-command 'comment-dwim-2)
		       (not (cd2/empty-line-p))
		       (not (cd2/line-ends-with-multiline-string-p))
		       (not (cd2/fully-commented-line-p)))
	      (if (cd2/line-contains-comment-p)
		  (cd2/inline-comment-function)
		(comment-indent)))) ; Insert inline comment
	(if (and (cd2/line-contains-comment-p)
		 (eq last-command 'comment-dwim-2))
	    (cd2/inline-comment-function)
	  (cd2/comment-line))))))

(provide 'comment-dwim-2)
;;; comment-dwim-2.el ends here
