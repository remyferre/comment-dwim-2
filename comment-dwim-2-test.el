(add-to-list 'load-path ".")
(require 'comment-dwim-2)

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
       ,@body)))


(ert-deftest cd2/test-line-contains-comment-p ()
  (cd2/test-setup "Foo //"     	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo // Bar" 	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "// Foo"     	  (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo /**/"      (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo /* Bar */" (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "/* Foo */"     (should (cd2/line-contains-comment-p)))
  (cd2/test-setup "Foo"           (should (not (cd2/line-contains-comment-p)))))


(ert-deftest cd2/test-line-ends-with-multiline-comment-p ()
  (cd2/test-setup "\"Foo\""
   (should (not (cd2/line-ends-with-multiline-string-p))))
  (cd2/test-setup "\"Foo\"\n\"Bar\""
   (should (not (cd2/line-ends-with-multiline-string-p)))
   (forward-line)
   (should (not (cd2/line-ends-with-multiline-string-p))))
  (cd2/test-setup "\"Foo\nBar\""
   (should (cd2/line-ends-with-multiline-string-p))
   (forward-line)
   (should (not (cd2/line-ends-with-multiline-string-p)))))


(ert-deftest cd2/test-comment-dwim-2--uncommented-line ()
  (cd2/test-setup "Foo"
   (comment-dwim-2) (setq last-command 'comment-dwim-2)
   (should (string-equal "/* Foo */" (buffer-substring (point-min)
  						       (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo				/*  */"
			 (buffer-substring (point-min)
					   (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo" (buffer-substring (point-min)
						 (point-max))))))

(ert-deftest cd2/test-comment-dwim-2--commented-line ()
  (cd2/test-setup " 	// Foo"
   (comment-dwim-2) (setq last-command 'comment-dwim-2)
   (should (string-equal " 	Foo" (buffer-substring (point-min)
						       (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "      /* 	Foo */" (buffer-substring (point-min)
							 (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "      	Foo			/*  */"
			 (buffer-substring (point-min)
					   (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo" (buffer-substring (point-min)
						 (point-max))))))

(ert-deftest cd2/test-comment-dwim-2--commented-line-2 ()
  (cd2/test-setup "Foo // Bar"
   (comment-dwim-2) (setq last-command 'comment-dwim-2)
   (should (string-equal "/* Foo // Bar */" (buffer-substring (point-min)
							      (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo				// Bar"
			 (buffer-substring (point-min)
					   (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo"
			 (buffer-substring (point-min)
					   (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "/* Foo */" (buffer-substring (point-min)
						       (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo				/*  */"
			 (buffer-substring (point-min)
					   (point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "Foo"
			 (buffer-substring (point-min)
					   (point-max))))))

(ert-deftest cd2/test-comment-dwim-2--multiline-string ()
  (cd2/test-setup "\"Foo\nBar\""
   (comment-dwim-2) (setq last-command 'comment-dwim-2)
   (should (string-equal "/* \"Foo */\nBar\"" (buffer-substring (point-min)
								(point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "\"Foo\nBar\""
			 (buffer-substring (point-min)
					   (point-max)))))
  (cd2/test-setup "\"Foo\nBar\""
   (forward-line)
   (comment-dwim-2) (setq last-command 'comment-dwim-2)
   (should (string-equal "\"Foo\n/* Bar\" */" (buffer-substring (point-min)
								(point-max))))
   (font-lock-fontify-buffer) (comment-dwim-2)
   (should (string-equal "\"Foo\nBar\"				/*  */"
			 (buffer-substring (point-min)
					   (point-max))))))
