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

;;; Code:

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
    (if (comment-only-p (save-excursion
			  (move-beginning-of-line 1)
			  (skip-chars-forward " \t")
			  (point))
			(line-end-position))
	(progn
	  (uncomment-region (line-beginning-position) (line-end-position))
	  (when (and (eq last-command 'comment-dwim-2)
		     (not (cd2/line-ends-with-multiline-string-p)))
	    (comment-dwim nil))) ; Add comment at end of line
      (if (and (cd2/line-contains-comment-p)
	       (eq last-command 'comment-dwim-2))
	  (comment-kill nil)
	(comment-region (line-beginning-position) (line-end-position))))))

(provide 'comment-dwim-2)
;;; comment-dwim-2.el ends here
