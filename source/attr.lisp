(in-package :de.anvi.croatoan)

(defparameter *color-alist*
  '((:default . -1)
    (:black   . 0)
    (:red     . 1)
    (:green   . 2)
    (:yellow  . 3)
    (:blue    . 4)
    (:magenta . 5)
    (:cyan    . 6)
    (:white   . 7)))

(defun color->number (color-name)
  "Take a keyword, returns the corresponding color number.

Example: (color->number :white) => 7"
  (let ((pair (assoc color-name *color-alist*)))
    (if pair
        (cdr pair)
      (error "color doesnt exist."))))

;; keys are 2 element lists of the form: (:fg :bg)
;; fg and bg are keyword symbols
;; vals are integers that represent ncurses color pairs
;; only one color pair, 1, is predefined: (:white :black).
(defparameter *color-pair-alist*
  '(((:white :black) . 0)))

;; adds the pair to curses.
(defun pair->number (pair)
  "Take a 2 element list of color keywords, return the pair number.

Example: (pair->number '(:white :black)) => 0"
  (let ((result (assoc pair *color-pair-alist* :test #'equal)))
    (if result
        ;; if the entry already exists, just return the pair number.
        (cdr result)
      ;; if the pair doesnt exist, create a new pair number
      (let ((new-pair-number (list-length *color-pair-alist*)))
        ;; add it to the alist first.
        (setf *color-pair-alist* (acons pair new-pair-number *color-pair-alist*))
        ;; then add it to ncurses.
        (%init-pair new-pair-number (color->number (car pair)) (color->number (cadr pair)))
        ;; return the newly added pair number.
        new-pair-number))))

;; TODO: cross check with the ncurses primitives that we get the same result.
(defun number->pair (number)
  "Take a pair number, return a color pair in a 2 element list of keywords."
  (car (rassoc number *color-pair-alist*)))




(defun add-attributes (winptr attributes)
  "Takes a list of keywords and turns the appropriate attributes on."
  (dolist (i attributes)
    (%wattron winptr (get-bitmask i))))

(defun remove-attributes (winptr attributes)
  "Takes a list of keywords and turns the appropriate attributes off."
  (dolist (i attributes)
    (%wattroff winptr (get-bitmask i))))

;; (set-attributes scr '(:bold :underline))
;; vorsicht: set-attributes overwrites color settings because it treats color as an attribute.
(defun set-attributes (winptr attributes)
  "Takes a list of keywords and sets the appropriate attributes.

Overwrites any previous attribute settings including the color."
  (%wattrset winptr
             (apply #'logior (loop for i in attributes collect (get-bitmask i)))))

;; (set-color window '(:black :white))
(defun set-color-pair (winptr color-pair)
  "Sets the color attribute only."
  (%wcolor-set winptr (pair->number color-pair) (null-pointer)))

;;In general, only underline, bold and reverse work.
(defparameter *bitmask-alist*
  '((:normal     . #x00000000)
    (:attributes . #xffffff00)
    (:chartext   . #x000000ff)
    (:color      . #x0000ff00)
    (:standout   . #x00010000)
    (:underline  . #x00020000)
    (:reverse    . #x00040000)
    (:blink      . #x00080000)
    (:dim        . #x00100000)
    (:bold       . #x00200000)
    (:altcharset . #x00400000)
    (:invis      . #x00800000)
    (:protect    . #x01000000)
    (:horizontal . #x02000000)
    (:left       . #x04000000)
    (:low        . #x08000000)
    (:right      . #x10000000)
    (:top        . #x20000000)
    (:vertical   . #x40000000)))

(defun get-bitmask (attribute)
  "Returns an ncurses attr/chtype representing the attribute keyword."
  (cdr (assoc attribute *bitmask-alist*)))

(defparameter *valid-attributes*
  '(:standout
    :underline 
    :reverse 
    :blink 
    :dim 
    :bold 
    :altcharset 
    :invis 
    :protect 
    :horizontal 
    :left 
    :low 
    :right 
    :top 
    :vertical))

;;; ------------------------------------------------------------------


;; Example: (x2c (c2x 2490466)) => 2490466

(defun x2c (ch)
  "Converts a croatoan complex char to a ncurses chtype."
  (logior (if (.simple-char ch)
              (char-code (.simple-char ch))
              0) ; logioring something with 0 has no effect.

          ;; if an attribute is there, add its integer or a 0.
          ;; TODO: abstract away the c&p orgy, z.B in a local macro.
          (if (member :underline  (.attributes ch)) (get-bitmask :underline)  0)
          (if (member :reverse    (.attributes ch)) (get-bitmask :reverse)    0)
          (if (member :blink      (.attributes ch)) (get-bitmask :blink)      0)
          (if (member :dim        (.attributes ch)) (get-bitmask :dim)        0)
          (if (member :bold       (.attributes ch)) (get-bitmask :bold)       0)
          (if (member :altcharset (.attributes ch)) (get-bitmask :altcharset) 0)
          (if (member :invis      (.attributes ch)) (get-bitmask :invis)      0)
          (if (member :protect    (.attributes ch)) (get-bitmask :protect)    0)
          (if (member :horizontal (.attributes ch)) (get-bitmask :horizontal) 0)
          (if (member :left       (.attributes ch)) (get-bitmask :left)       0)
          (if (member :low        (.attributes ch)) (get-bitmask :low)        0)
          (if (member :right      (.attributes ch)) (get-bitmask :right)      0)
          (if (member :top        (.attributes ch)) (get-bitmask :top)        0)
          (if (member :vertical   (.attributes ch)) (get-bitmask :vertical)   0)

          ;; right shift by 8 to get the color bits at their proper place in a chtype.
          ;; you cannot simply logior the pair number because that would overwrite the char.
          (ash (pair->number (.color-pair ch)) 8)))

(defun c2x (ch)
  "Converts a ncurses chtype to croatoan complex-char."
  (make-instance 'complex-char
                 :simple-char (code-char (logand ch (get-bitmask :chartext)))
                 :attributes (loop for i in *valid-attributes*
                                   if (logtest ch (get-bitmask i)) collect i)
                 ;; first get the color attribute bits by log-AND-ing them with ch.
                 ;; then right shift them by 8 to extract the color int from them.
                 ;; then get the color pair (:white :black) associated with that number.
                 :color-pair (number->pair (ash (logand ch (get-bitmask :color)) -8))))


(defgeneric convert-char (char result-type)
  (:documentation "Take a char and convert it to a char of result-type."))

;; The lisp class representing chtype is complex-char.
(defmethod convert-char ((char complex-char) result-type)
  (case result-type
    (:simple-char (.simple-char char))
    (:chtype (x2c char))))

;; Lisps character object is here called "simple-char".
(defmethod convert-char ((char character) result-type)
  (case result-type
    (:complex-char (make-instance 'complex-char :simple-char char :attributes nil))
    (:chtype (char-code char))))

;; chtype is a ncurses unsigned long, an integer.
(defmethod convert-char ((char integer) result-type)
  (case result-type
    (:simple-char (code-char (logand char (get-bitmask :chartext))))
    (:complex-char (c2x char))))


;;; TODOs

;; todo: convert-char -> convert

;; [ ] add type asserts.
;; what is an attr_t? get all ncurses types definitions.

;; make it clear which routines use xchars and which use chtypes.
;; make all user visible apis use xchars and only internally convert to chtypes.
;; functions to manipulate attributes and colors of xchars.
;; the char part of an xchar should not be changeable.
