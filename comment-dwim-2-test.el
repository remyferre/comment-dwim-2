(add-to-list 'load-path ".")
(require 'comment-dwim-2)

;;;; Helpers

(defmacro cd2/test-setup (buffer-content &rest body)
  `(save-excursion
     (with-temp-buffer
       (switch-to-buffer (current-buffer))
       (c-mode)
       (font-lock-mode)
       (insert ,buffer-content)
       (font-lock-fontify-buffer)
       (setq kill-ring ())
       (setq last-command nil)
       (goto-char (point-min))
       (setq comment-dwim-2--inline-comment-behavior 'kill-comment)
       ,@body)))

(defmacro cd2/test-setup--with-reindent (buffer-content &rest body)
  `(cd2/test-setup ,buffer-content
    (setq comment-dwim-2--inline-comment-behavior 'reindent-comment)
    ,@body))

(defun should-buffer (str)
  (should (string-equal str (buffer-substring (point-min) (point-max)))))

(defadvice comment-dwim-2 (around test-advice activate)
  (font-lock-fontify-buffer)
  ad-do-it
  (setq last-command 'comment-dwim-2))

;;;; Unit tests

;;; Private functions

(ert-deftest cd2/test-line-contains-comment-p ()
  (cd2/test-setup "Foo //"     	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo // Bar" 	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "// Foo"     	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo /**/"      (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo /* Bar */" (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "/* Foo */"     (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo"           (should (not (cd2/line-contains-comment-p)))))


(ert-deftest cd2/test-fully-commented-line-p ()
  (cd2/test-setup "// Foo"         (should (cd2/fully-commented-line-p)))
  (cd2/test-setup "/* Foo */"      (should (cd2/fully-commented-line-p)))
  (cd2/test-setup " 	// Foo"    (should (cd2/fully-commented-line-p)))
  (cd2/test-setup " 	/* Foo */" (should (cd2/fully-commented-line-p)))
  (cd2/test-setup "Bar // Foo"     (should (not (cd2/fully-commented-line-p))))
  (cd2/test-setup "/* Foo */ Bar"  (should (not (cd2/fully-commented-line-p))))
  (cd2/test-setup "Bar"            (should (not (cd2/fully-commented-line-p)))))


(ert-deftest cd2/test-line-ends-with-multiline-comment-p ()
  (cd2/test-setup "\"Foo\""          (should (not (cd2/line-ends-with-multiline-string-p))))
  (cd2/test-setup "\"Foo\"\n\"Bar\"" (should (not (cd2/line-ends-with-multiline-string-p)))
   (forward-line)                    (should (not (cd2/line-ends-with-multiline-string-p))))
  (cd2/test-setup "\"Foo\nBar\""     (should (cd2/line-ends-with-multiline-string-p))
   (forward-line)                    (should (not (cd2/line-ends-with-multiline-string-p))))
  (cd2/test-setup " \"Foo\nBar\""    (should (cd2/line-ends-with-multiline-string-p))))

;;; comment-dwim-2 tests

;; comment-dwim-2--inline-comment-behavior == 'kill-comment

(ert-deftest cd2/test-comment-dwim-2--uncommented-line ()
  (cd2/test-setup "Foo\n"
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest cd2/test-comment-dwim-2--empty-line ()
  (cd2/test-setup ""
   (comment-dwim-2) (should-buffer "/*  */")
   (comment-dwim-2) (should-buffer "")))

(ert-deftest cd2/test-comment-dwim-2--commented-line ()
  (cd2/test-setup "// Foo\n"
   (comment-dwim-2) (should-buffer "Foo\n")
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest cd2/test-comment-dwim-2--commented-line-2 ()
  (cd2/test-setup "Foo // Bar\n"
   (comment-dwim-2) (should-buffer "/* Foo // Bar */\n")
   (comment-dwim-2) (should-buffer "Foo\n")
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest cd2/test-comment-dwim-2--commented-line-3 ()
  (cd2/test-setup "// Foo // Bar\n"
   (comment-dwim-2) (should-buffer "Foo // Bar\n")
   (comment-dwim-2) (should-buffer "Foo\n")
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest cd2/test-comment-dwim-2--multiline-string ()
  (cd2/test-setup "\"Foo\nBar\"\n" (forward-char 3)
   (comment-dwim-2) (should-buffer "/* \"Foo */\nBar\"\n")
   (comment-dwim-2) (should-buffer "\"Foo\nBar\"\n"))
  (cd2/test-setup "\"Foo\nBar\"\n" (forward-line)
   (comment-dwim-2) (should-buffer "\"Foo\n/* Bar\" */\n")
   (comment-dwim-2) (should-buffer "\"Foo\nBar\"				/*  */\n")))

(ert-deftest cd2/test-nested-commented-line ()
  (cd2/test-setup "// // // Foo\n"
   (comment-dwim-2) (should-buffer "// // Foo\n")
   (comment-dwim-2) (should-buffer "// Foo\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

;; comment-dwim-2--inline-comment-behavior == 'reindent-comment

(ert-deftest cd2/test-comment-dwim-2--uncommented-line--with-reindent ()
  (cd2/test-setup--with-reindent "Foo\n"
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest cd2/test-comment-dwim-2--empty-line--with-reindent ()
  (cd2/test-setup--with-reindent ""
   (comment-dwim-2) (should-buffer "/*  */")
   (comment-dwim-2) (should-buffer "")))

(ert-deftest cd2/test-comment-dwim-2--commented-line--with-reindent ()
  (cd2/test-setup--with-reindent "// Foo\n"
   (comment-dwim-2) (should-buffer "Foo\n")
   (comment-dwim-2) (should-buffer "/* Foo */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest cd2/test-comment-dwim-2--commented-line-2--with-reindent ()
  (cd2/test-setup--with-reindent "Foo // Bar\n"
   (comment-dwim-2) (should-buffer "/* Foo // Bar */\n")
   (comment-dwim-2) (should-buffer "Foo				// Bar\n")
   (comment-dwim-2) (should-buffer "Foo				// Bar\n")))

(ert-deftest cd2/test-comment-dwim-2--commented-line-3--with-reindent ()
  (cd2/test-setup--with-reindent "// Foo // Bar\n"
   (comment-dwim-2) (should-buffer "Foo // Bar\n")
   (comment-dwim-2) (should-buffer "Foo				// Bar\n")
   (comment-dwim-2) (should-buffer "Foo				// Bar\n")))

(ert-deftest cd2/test-comment-dwim-2--multiline-string--with-reindent ()
  (cd2/test-setup--with-reindent "\"Foo\nBar\"\n" (forward-char 3)
   (comment-dwim-2) (should-buffer "/* \"Foo */\nBar\"\n")
   (comment-dwim-2) (should-buffer "\"Foo\nBar\"\n"))
  (cd2/test-setup--with-reindent "\"Foo\nBar\"\n" (forward-line)
   (comment-dwim-2) (should-buffer "\"Foo\n/* Bar\" */\n")
   (comment-dwim-2) (should-buffer "\"Foo\nBar\"				/*  */\n")))

(ert-deftest cd2/test-nested-commented-line--with-reindent ()
  (cd2/test-setup--with-reindent "// // // Foo\n"
   (comment-dwim-2) (should-buffer "// // Foo\n")
   (comment-dwim-2) (should-buffer "// Foo\n")
   (comment-dwim-2) (should-buffer "Foo				/*  */\n")))
