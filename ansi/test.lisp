(in-package :de.anvi.ansi-escape.test)

(defun t01 ()
  (erase)
  (cursor-position 0 0)
  (princ "0")
  (cursor-position 2 2)
  (princ "1")
  (cursor-position 5 15)
  (princ "test")
  (cursor-position 10 15)
  (force-output)
  (let ((a (read-line)))
    (cursor-position 12 15)
    (princ a)
    (force-output)))

(defun t02 ()
  (print "normal")
  (sgr 1)
  (print "bold")
  (sgr 4)
  (print "bold underline")
  (sgr 7)
  (print "bold underline reverse")
  (sgr 22)
  (print "underline reverse")
  (sgr 24)
  (print "reverse")
  (sgr 27)
  (print "normal")
  (sgr 1 4 7)
  (print "bold underline reverse")
  (sgr 0)
  (print "normal")
  (force-output))

(defun t03 ()
  "Display the 256 color palette."
  (loop for i from 0 to 255 do
    (sgr 48 5 i)
    (princ #\space))
  (terpri)
  (sgr 0)
  (loop for i from 0 to 255 do
    (sgr 38 5 i)
    (princ "X"))
  (sgr 0)
  (force-output))
