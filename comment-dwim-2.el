;;; comment-dwim-2.el --- An all-in-one comment command to rule them all

;; Copyright (C) 2014  Rémy Ferré

;; Author: Rémy Ferré <remy-ferre@laposte.net>
;; Version: 1.0.0
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
;; This package provides a replacement for `comment-dwim', `comment-dwim-2',
;; which include more comment commands than its predecessor and allow to
;; comment / uncomment / insert comment / kill comment depending on the
;; context. The command can be repeated several times to switch between the
;; different possible behaviors.
;;
;; As the command is unbound, you need to set up you own keybinding first, for
;; instance:
;;
;;   (global-set-key (kbd "M-;") 'comment-dwim-2)

;;; Code:

(defun cd2/empty-line-p ()
  "Return true if current line contains only whitespace
characters."
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

(defun cd2/beginning-of-end-of-line-comment ()
  "Return beginning position of current line end-of-line comment,
or nil if there is none."
  (save-excursion
    (move-end-of-line 1)
    (forward-char -1)
    (if (not (cd2/within-comment-p (point)))
	nil
      (while (and (not (= (line-beginning-position) (point)))
		  (cd2/within-comment-p (point)))
	(forward-char -1))
      (forward-char 1)
      (while (eq font-lock-comment-delimiter-face
		 (get-text-property (point) 'face))
	(forward-char 1))
      (point))))

(defun cd2/comment-line ()
  "Comment current line."
  ;; `comment-region' does not support empty lines, so we use
  ;; `comment-dwim' in such cases to comment the line
  (if (cd2/empty-line-p)
      (comment-dwim nil)
    (comment-region (line-beginning-position) (line-end-position))))

;;;###autoload
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
	    (let ((boc (cd2/beginning-of-end-of-line-comment)))
	      (if boc (goto-char boc)
		(comment-dwim nil))))) ; Add comment at end of line
      (if (and (cd2/line-contains-comment-p)
	       (eq last-command 'comment-dwim-2))
	  (comment-kill nil)
	(cd2/comment-line)))))

(provide 'comment-dwim-2)
;;; comment-dwim-2.el ends here
