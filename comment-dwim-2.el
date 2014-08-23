;;; comment-dwim-2.el --- A comment command to rule them all

;; Copyright (C) 2014  Rémy Ferré

;; Author: Rémy Ferré <remy-ferre@laposte.net>
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
;; This package add a replacement for `comment-dwim', `comment-dwim-2',
;; which allow to comment/uncomment/insert comment/kill comment depending
;; on the context and by using successive calls.

;;; How to use:
;;
;; The simplest way is to enable `comment-dwim-2-mode' which bind
;; `comment-dwim-2' to M-;
;;
;;   (comment-dwim-2)
;;
;; If you do not want this keybinding, do not use the mode and bind the
;; command manually instead:
;;
;;   (global-set-key (kbd YOUR_KEY) 'comment-dwim-2)

;;; Code:

(defgroup comment-dwim-2 ()
  "Customization group for comment-dwim-2 minor mode."
  :group 'convenience)

(defvar comment-dwim-2-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-;") 'comment-dwim-2))
  "Keymap of comment-dwim-2 minor mode.")

(defcustom comment-dwim-2-on-hook ()
  "Hook run after `comment-dwim-2-mode' is enabled."
  :type 'hook
  :group 'comment-dwim-2)

(defcustom comment-dwim-2-off-hook ()
  "Hook run after `comment-dwim-2-mode' is disabled."
  :type 'hook
  :group 'comment-dwim-2)

(define-minor-mode comment-dwim-2-mode
  "Toggle comment-dwim-2 minor mode.

This mode add a replacement for the built-in command
`comment-dwim' named `comment-dwim-2'. Contrary to its
predecessor, `comment-dwim-2' include more comment commands and
allow to comment / uncomment / insert comment / kill comment
depending on the context. The command can be repeated several
times to switch between the different possible behaviors.

With a prefix argument ARG, enable comment-dwim-2 mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil."
  :global t
  :keymap comment-dwim-2-map
  (if comment-dwim-2-mode
      (run-hooks 'comment-dwim-2-on-hook)
    (run-hooks 'comment-dwim-2-off-hook)))


(defun cd2/empty-line-p ()
  "Return true if current line contains only whitespace characters."
  (string-match "^[[:blank:]]*$"
		(buffer-substring (line-beginning-position)
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
that adding an end of line comment is meaningless."
  (and
   ;; End of line have string face..
   (progn
     (font-lock-fontify-region (line-beginning-position) (line-end-position))
     (or (eq font-lock-string-face
	     (get-text-property (line-end-position) 'face))
	 (eq font-lock-doc-face
	     (get-text-property (line-end-position) 'face))))
   ;; ..and next line contains a string which begins at the same position
   (eq (elt (save-excursion (syntax-ppss
			     ;; Move one character forward if point is on quote
			     ;; (needed by `syntax-ppss')
			     (if (or (elt (syntax-ppss (point)) 3)
			     	     (eq (point) (point-max)))
			     	 (point)
			       (1+ (point))))) 8)
       (elt (save-excursion (syntax-ppss (line-beginning-position 2))) 8))))

(defun cd2/comment-line ()
  "Comment current line."
  ;; `comment-region' does not support empty lines, so we use
  ;; `comment-dwim' in such cases to comment the line
  (if (cd2/empty-line-p)
      (comment-dwim nil)
    (comment-region (line-beginning-position) (line-end-position))))

(defun comment-dwim-2 ()
  "Call a comment command according to the context.
If the region is active, call `comment-or-uncomment-region' to
toggle comments.
Else, the function applies to the current line and calls a
different function at each successive call. If the line is not
commented, the behavior is:
comment line -> add end-of-line comment -> restore initial state.
If the line is already commented, uncomment it first."
  (interactive)
  (if mark-active
      (comment-or-uncomment-region (region-beginning) (region-end))
    (if (and (not (cd2/empty-line-p))
	     (comment-only-p (save-excursion
			       (move-beginning-of-line 1)
			       (skip-chars-forward " \t")
			       (point))
			     (line-end-position)))
	(progn
	  (uncomment-region (line-beginning-position) (line-end-position))
	  (when (and (eq last-command 'comment-dwim-2)
		     (not (cd2/empty-line-p))
		     (not (cd2/line-ends-with-multiline-string-p)))
	    (comment-dwim nil))) ; Add comment at end of line
      (if (and (cd2/line-contains-comment-p)
	       (eq last-command 'comment-dwim-2))
	  (comment-kill nil)
	(cd2/comment-line)))))

(provide 'comment-dwim-2)
;;; comment-dwim-2.el ends here
