;;; omm.el --- Org Minor Mode

;; Copyright (C) from 2014 (not yet) Free Software Foundation, Inc.

;; Author: Thorsten Jolitz <tjolitz at gmail dot com>
;; Keywords: outlines, hypermedia, calendar, wp

;; This file is (not yet) part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary

;; This library implements org-minor-mode, trying to bring as much of
;; Org-mode's look&feel to the (Emacs-)world outside of the org-mode
;; major-mode as possible.

;; It is based on:

;;  - orgstruct-mode :: by [???]
;;  - outshine.el :: by Thorsten Jolitz, Carsten Dominik, Per Abrahamsen

;; It is supposed to be major-mode agnostic, i.e. to work with all
;; kinds of major-modes, even those not yet written. However, in
;; practice there are sometimes a few minor tweaks necessary to make
;; it work with a particular major-mode.

;;; Requires

(eval-when-compile (require 'cl))
(require 'org)
;; (require 'org-macs)
;; (require 'org-compat)
(require 'outorg nil 'noerror)
(require 'navi-mode nil 'noerror)

;;; Declarations
;;;; Vars
;; Declared here to avoid compiler warnings

;; Examples:
;; (defvar outline-mode-menu-heading)

;;;;; Org

(defvar org-BOL)
(defvar org-EOL)
(defvar org-STAR)

;;;; Funs
;; Declared here to avoid compiler warnings

;; Examples:
;; (declare-function cdlatex-compute-tables "ext:cdlatex" ())
;; (declare-function dired-get-filename "dired" (&optional localp no-error-if-not-filep))
;; (declare-function org-gnus-follow-link "org-gnus" (&optional group article))
;; (declare-function org-agenda-skip "org-agenda" ())

;;;;; Org
(declare-function org-regexp-group-p "org" (rgxp))
(declare-function org-rx "org" (rgxp &optional bolp stars eolp enclosing &rest rgxps))

;;; Variables

;;;; Consts

(defconst omm-version "1.0"
  "omm version number.")

;; copied from org-source.el
(defconst omm-level-faces
  '(omm-level-1 omm-level-2 omm-level-3 omm-level-4
                     omm-level-5 omm-level-6 omm-level-7
                     omm-level-8))

(defconst omm-outline-heading-end-regexp "\n"
  "Global default value of `outline-heading-end-regexp'.
Used to override any major-mode specific file-local settings")

(defconst omm-oldschool-elisp-regexp-base-char ";"
  "Oldschool Emacs Lisp regexp base character.")

;; "[;]+"
(defconst omm-oldschool-elisp-outline-regexp-base 
  (format "[%s]+" omm-oldschool-elisp-regexp-base-char)
  "Oldschool Emacs Lisp base for calculating the outline-regexp")

(defconst omm-speed-commands-default
  '(
    ("Outline Navigation")
    ("n" . (omm-speed-move-safe
            'outline-next-visible-heading))
    ("p" . (omm-speed-move-safe
            'outline-previous-visible-heading))
    ("f" . (omm-speed-move-safe
            'outline-forward-same-level))
    ("b" . (omm-speed-move-safe
            'outline-backward-same-level))
    ;; ("F" . omm-next-block)
    ;; ("B" . omm-previous-block)
    ("u" . (omm-speed-move-safe
            'outline-up-heading))
    ("j" . (omm-use-outorg 'org-goto))
    ("g" . (omm-use-outorg 'org-refile))
    ("Outline Visibility")
    ("c" . outline-cycle)
    ("C" . omm-cycle-buffer)
    ;; FIXME needs to be improved!
    (" " . (omm-use-outorg
            (lambda ()
              (message
               "%s" (substring-no-properties
                     (org-display-outline-path)))
               (sit-for 1))
            'WHOLE-BUFFER-P))
    ("r" . omm-narrow-to-subtree)
    ("w" . widen)
    ("=" . (omm-use-outorg 'org-columns))
    ("Outline Structure Editing")
    ("^" . outline-move-subtree-up)
    ("<" . outline-move-subtree-down)
    ;; ("r" . omm-metaright)
    ;; ("l" . omm-metaleft)
    ("+" . outline-demote)
    ("-" . outline-promote)
    ("i" . omm-insert-heading)
    ;; ("i" . (progn (forward-char 1)
    ;;            (call-interactively
    ;;             'omm-insert-heading-respect-content)))
    ("^" . (omm-use-outorg 'org-sort))
    ;; ("a" . (omm-use-outorg
    ;;      'org-archive-subtree-default-with-confirmation))
    ("m" . outline-mark-subtree)
    ;; ("#" . omm-toggle-comment)
    ("Clock Commands")
    ;; FIXME need improvements!
    ("I" . (omm-use-outorg 'org-clock-in))
    ("O" . omm-clock-out)
    ("Meta Data Editing")
    ("t" . (omm-use-outorg 'org-todo))
    ("," . (omm-use-outorg 'org-priority))
    ("0" . (omm-use-outorg (lambda () (org-priority ?\ ))))
    ("1" . (omm-use-outorg (lambda () (org-priority ?A))))
    ("2" . (omm-use-outorg (lambda () (org-priority ?B))))
    ("3" . (omm-use-outorg (lambda () (org-priority ?C))))
    (":" . (omm-use-outorg 'org-set-tags-command))
    ("e" . (omm-use-outorg 'org-set-effort))
    ("E" . (omm-use-outorg 'org-inc-effort))
    ;; ("W" . (lambda(m) (interactive "sMinutes before warning: ")
    ;;       (omm-entry-put (point) "APPT_WARNTIME" m)))
    ;; ("Agenda Views etc")
    ;; ("v" . omm-agenda)
    ;; ("/" . omm-sparse-tree)
    ("Misc")
    ("o" . (omm-use-outorg 'org-open-at-point))
    ("?" . omm-speed-command-help)
    ;; ("<" . (omm-agenda-set-restriction-lock 'subtree))
    ;; (">" . (omm-agenda-remove-restriction-lock))
    )
  "The default speed commands.")

;; (defconst omm-comment-tag "comment"
;;   "The tag that marks a subtree as comment.
;; A comment subtree does not open during visibility cycling.")

(defconst omm-global-org-regexps '(org-list-end-re
  org-table-auto-recalculate-regexp org-table-recalculate-regexp
  org-table-calculate-mark-regexp org-table-border-regexp
  orgtbl-exp-regexp org-outline-regexp-bol org-heading-regexp
  org-dblock-end-re org-drawer-regexp org-property-start-re
  org-property-end-re org-clock-drawer-start-re
  org-clock-drawer-end-re org-table-any-line-regexp
  org-table-line-regexp org-table-dataline-regexp
  org-table-hline-regexp org-table1-hline-regexp
  org-table-any-border-regexp org-TBLFM-regexp)
  "List of all(?) global Org regexps starting with \"^\".")

(defconst omm-org-stars-alternatives
  (org-rx
   (regexp-quote "\\\\*+") nil nil nil 'alt
   (regexp-quote "\\\\(\\\\*+\\\\)")
   (regexp-quote "\\\\(\\\\**\\\\)\\\\(\\\\* \\\\)")
   (regexp-quote "\\*+") 		; typo
   (regexp-quote "*+") 			; bad practice
   (regexp-quote "\\\\*\\\\*+")
   (regexp-quote "\\\\(\\\\*\\\\*\\\\)+")
   (regexp-quote "\\\\*"))
  "Regexp-alternative matching hardcoded forms of org stars.")

(defconst omm-org-regexp-matcher
  ;; wrap with BOL and EOL
  (org-rx
   ;; make groups
   (org-rx
    ;; Group 1: double-quotes
    "\"" nil nil nil 'append
    ;; Group 2: optional special char BOL
     (concat "\\(" (regexp-quote "^") "\\)?")
    ;; Group 3: optional hard-coded header alternatives
    (concat omm-org-stars-alternatives "?")
    ;; Group 4: optional non-greedy content
    "\\([^\\000]\\)*?"
    ;; Group 5: optional special char EOL
    (concat "\\(" (regexp-quote "$") "\\)?")) t nil t nil
   ;; Group 6: double quotes
   "\\(\"\\)")
  "Regexp matching hard-coded Org regexps.
The following sub-groups have a special meaning:

 - Group 2 :: matches the special character '^' (BOL).
 - Group 3 :: matches various forms of hard-coded Org stars (*).
 - Group 4 :: matches the body of the regexp.
 - Group 5 :: matches the special character '$' (EOL).")

;;;; Vars

;; (defvar org-minor-mode nil)

(defvar omm-initialized nil)

(defvar org-local-vars nil
  "List of local variables, for use by `org-minor-mode'.")

(defvar org-fb-vars nil)
(make-variable-buffer-local 'org-fb-vars)

(defvar omm-is-++ nil
  "Is `org-minor-mode' in ++ version in the current-buffer?")
(make-variable-buffer-local 'omm-is-++)

;; "\C-c" conflicts with other modes like e.g. ESS
(defvar outline-minor-mode-prefix "\M-#"
  "New outline-minor-mode prefix.
Does not really take effect when set in the `omm' library.
Instead, it must be set in your init file *before* the `outline'
library is loaded, see the installation tips in the comment
section of `omm'.")

;; from `outline-magic'
(defvar outline-promotion-headings nil
  "A sorted list of headings used for promotion/demotion commands.
Set this to a list of headings as they are matched by `outline-regexp',
top-level heading first.  If a mode or document needs several sets of
outline headings (for example numbered and unnumbered sections), list
them set by set, separated by a nil element.  See the example for
`texinfo-mode' in the file commentary.")
(make-variable-buffer-local 'outline-promotion-headings)

(defvar omm-delete-leading-whitespace-from-outline-regexp-base-p nil
  "If non-nil, delete leading whitespace from outline-regexp-base.")
(make-variable-buffer-local
 'omm-delete-leading-whitespace-from-outline-regexp-base-p)

(defvar omm-enforce-no-comment-padding-p nil
  "If non-nil, make sure no comment-padding is used in heading.")
(make-variable-buffer-local
 'omm-enforce-no-comment-padding-p)

(defvar omm-outline-regexp-base ""
  "Actual base for calculating the outline-regexp")

(defvar omm-imenu-default-generic-expression nil
  "Expression assigned by default to `imenu-generic-expression'.")
(make-variable-buffer-local
 'omm-imenu-default-generic-expression)

(defvar omm-imenu-generic-expression nil
  "Expression assigned to `imenu-generic-expression'.")
(make-variable-buffer-local
 'omm-imenu-generic-expression)

(defvar omm-self-insert-command-undo-counter 0
  "Used for omm speed-commands.")

(defvar omm-speed-command nil
  "Used for omm speed-commands.")

(defvar omm-open-comment-trees nil
  "Cycle comment-subtrees anyway when non-nil.")

(defvar omm-current-buffer-visibility-state nil
  "Stores current visibility state of buffer.")

(defvar omm-use-outorg-last-headline-marker nil
  "Stores current visibility state of buffer.")
(make-variable-buffer-local
 'omm-use-outorg-last-headline-marker)

(defvar omm-bopl-marker (make-marker)
  "Marker that point at bopl of current line.")
(make-variable-buffer-local 'omm-bopl-marker)
(set-marker-insertion-type omm-bopl-marker t)

(defvar omm-bonl-marker (make-marker)
  "Marker that point at bol of next line.")
(make-variable-buffer-local 'omm-bonl-marker)
;; (set-marker-insertion-type omm-bonl-marker t)

(defvar omm-bocl-marker (make-marker)
  "Marker that point at bol of current line.")
(make-variable-buffer-local 'omm-bocl-marker)
(set-marker-insertion-type omm-bocl-marker t)

;; (defvar omm-org-cmds-with-key-bindings nil
;;   "Alist of all Org cmd syms and their keybindings.")

(defvar omm-tmp-storage nil
  "Temporary storage for operations like `mapatom'.")

;; (defvar org-BOL ""
;;   "Special string that signal BOL in regexps.")
;; (make-variable-buffer-local 'org-BOL)

;; (defvar org-EOL ""
;;   "Special string that signals EOL in regexps.")
;; (make-variable-buffer-local 'org-EOL)

;; (defvar org-STAR ""
;;   "Special string that signals headline(-level) in regexps.")
;; (make-variable-buffer-local 'org-STAR)

;;;; Customs

;;;;; Custom Groups

(defgroup omm nil
  "Org Minor Mode."
  :prefix "omm-"
  :group 'lisp)

(defgroup omm-faces nil
  "Faces in Omm."
  :tag "Omm Faces"
  :group 'omm)


;;;;; Custom Vars

(defcustom omm-minor-mode-prefix "\M-#"
  "Prefix key to use for Omm commands in Omm minor mode.
The value of this variable is checked as part of loading Omm mode.
After that, changing the prefix key requires manipulating keymaps."
  :type 'string
  :group 'outlines)


(defcustom omm-imenu-show-headlines-p t
  "Non-nil means use calculated outline-regexp for imenu."
  :group 'omm
  :type 'boolean)

;; from `org'
(defcustom omm-fontify-whole-heading-line nil
  "Non-nil means fontify the whole line for headings.
This is useful when setting a background color for the
pomm-level-* faces."
  :group 'omm
  :type 'boolean)

(defcustom omm-outline-regexp-outcommented-p t
  "Non-nil if regexp-base is outcommented to calculate outline-regexp."
  :group 'omm
  :type 'boolean)

;; FIXME alternative value: "[+\]" ?
(defcustom omm-outline-regexp-special-chars "[][+]"
  "Regexp for detecting (special) characters in outline-regexp.
These special chars will be stripped when the outline-regexp is
transformed into a string, e.g. when the outline-string for a
certain level is calculated. "
  :group 'omm
  :type 'regexp)

;; from `outline-magic'
(defcustom outline-cycle-emulate-tab nil
  "Where should `outline-cycle' emulate TAB.
nil    Never
white  Only in completely white lines
t      Everywhere except in headlines"
  :group 'outlines
  :type '(choice (const :tag "Never" nil)
                 (const :tag "Only in completely white lines" white)
                 (const :tag "Everywhere except in headlines" t)
                 ))

;; from `outline-magic'
(defcustom outline-structedit-modifiers '(meta)
  "List of modifiers for outline structure editing with the arrow keys."
  :group 'outlines
  :type '(repeat symbol))

;; startup options
(defcustom omm-startup-folded-p nil
  "Non-nil means files will be opened with all but top level headers folded."
  :group 'omm
  :type 'boolean)

(defcustom omm-regexp-base-char "*"
  "Character used in outline-regexp base."
  :group 'omm
  :type 'string)

(defvar omm-default-outline-regexp-base 
  (format "[%s]+" omm-regexp-base-char)
  "Default base for calculating the outline-regexp")

(defvar omm-cycle-silently nil
  "Suppress visibility-state-change messages when non-nil.")

(defcustom omm-org-style-global-cycling-at-bob-p nil
  "Cycle globally if cursor is at beginning of buffer and not at a headline.

This makes it possible to do global cycling without having to use
S-TAB or C-u TAB.  For this special case to work, the first line
of the buffer must not be a headline -- it may be empty or some
other text. When this option is nil, don't do anything special at
the beginning of the buffer."
  :group 'omm
  :type 'boolean)

(defcustom omm-use-speed-commands nil
  "Non-nil means activate single letter commands at beginning of a headline.
This may also be a function to test for appropriate locations
where speed commands should be active, e.g.:

    (setq omm-use-speed-commands
      (lambda ()  ( ...your code here ... ))"
  :group 'omm
  :type '(choice
          (const :tag "Never" nil)
          (const :tag "At beginning of headline stars" t)
          (function)))

(defcustom omm-speed-commands-user nil
  "Alist of additional speed commands.
This list will be checked before `omm-speed-commands-default'
when the variable `omm-use-speed-commands' is non-nil
and when the cursor is at the beginning of a headline.
The car if each entry is a string with a single letter, which must
be assigned to `self-insert-command' in the global map.
The cdr is either a command to be called interactively, a function
to be called, or a form to be evaluated.
An entry that is just a list with a single string will be interpreted
as a descriptive headline that will be added when listing the speed
commands in the Help buffer using the `?' speed command."
  :group 'omm
  :type '(repeat :value ("k" . ignore)
                 (choice :value ("k" . ignore)
                         (list :tag "Descriptive Headline" (string :tag "Headline"))
                         (cons :tag "Letter and Command"
                               (string :tag "Command letter")
                               (choice
                                (function)
                                (sexp))))))

(defcustom omm-speed-command-hook
  '(omm-speed-command-activate)
  "Hook for activating speed commands at strategic locations.
Hook functions are called in sequence until a valid handler is
found.

Each hook takes a single argument, a user-pressed command key
which is also a `self-insert-command' from the global map.

Within the hook, examine the cursor position and the command key
and return nil or a valid handler as appropriate.  Handler could
be one of an interactive command, a function, or a form.

Set `omm-use-speed-commands' to non-nil value to enable this
hook.  The default setting is `omm-speed-command-activate'."
  :group 'omm
  :version "24.1"
  :type 'hook)

(defcustom omm-self-insert-cluster-for-undo
  (or (featurep 'xemacs) (version<= emacs-version "24.1"))
  "Non-nil means cluster self-insert commands for undo when possible.
If this is set, then, like in the Emacs command loop, 20 consecutive
characters will be undone together.
This is configurable, because there is some impact on typing performance."
  :group 'omm
  :type 'boolean)


;; FIXME delete with all occurences and related logic
(defcustom omm-heading-prefix-regexp ""
  "Regexp that matches the custom prefix of Org headlines in
org-minor-mode."
  :group 'org
  :version "24.4"
  :package-version '(Org . "8.3")
  :type 'regexp)
;;;###autoload(put 'omm-heading-prefix-regexp 'safe-local-variable 'stringp)

(defcustom org-minor-mode-setup-hook nil
  "Hook run after org-minor-mode-map is filled."
  :group 'org
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'hook)

(defcustom omm-default-exec-diff-program "diff"
  "Diff cmd-line utility used by default."
  :group 'omm
  :type 'string)

;;;; Hooks

(defvar org-minor-mode-hook nil
  "Functions to run after `omm' is loaded.")

;;;; Faces

;; from `org-compat.el'
(defun omm-compatible-face (inherits specs)
  "Make a compatible face specification.
If INHERITS is an existing face and if the Emacs version supports it,
just inherit the face.  If INHERITS is set and the Emacs version does
not support it, copy the face specification from the inheritance face.
If INHERITS is not given and SPECS is, use SPECS to define the face.
XEmacs and Emacs 21 do not know about the `min-colors' attribute.
For them we convert a (min-colors 8) entry to a `tty' entry and move it
to the top of the list.  The `min-colors' attribute will be removed from
any other entries, and any resulting duplicates will be removed entirely."
  (when (and inherits (facep inherits) (not specs))
    (setq specs (or specs
                    (get inherits 'saved-face)
                    (get inherits 'face-defface-spec))))
  (cond   ((and inherits (facep inherits)
         (not (featurep 'xemacs))
         (>= emacs-major-version 22)
         ;; do not inherit outline faces before Emacs 23
         (or (>= emacs-major-version 23)
             (not (string-match "\\`outline-[0-9]+"
                                (symbol-name inherits)))))
    (list (list t :inherit inherits)))
   ((or (featurep 'xemacs) (< emacs-major-version 22))
    ;; These do not understand the `min-colors' attribute.
    (let (r e a)
      (while (setq e (pop specs))
        (cond
         ((memq (car e) '(t default)) (push e r))
         ((setq a (member '(min-colors 8) (car e)))
          (nconc r (list (cons (cons '(type tty) (delq (car a) (car e)))
                               (cdr e)))))
         ((setq a (assq 'min-colors (car e)))
          (setq e (cons (delq a (car e)) (cdr e)))
          (or (assoc (car e) r) (push e r)))
         (t (or (assoc (car e) r) (push e r)))))
      (nreverse r)))
   (t specs)))
(put 'omm-compatible-face 'lisp-indent-function 1)

;; The following face definitions are from `org-faces.el'
;; originally copied from font-lock-function-name-face
(defface omm-level-1
  (omm-compatible-face 'outline-1
    '((((class color) (min-colors 88)
        (background light)) (:foreground "Blue1"))
      (((class color) (min-colors 88)
        (background dark)) (:foreground "LightSkyBlue"))
      (((class color) (min-colors 16)
        (background light)) (:foreground "Blue"))
      (((class color) (min-colors 16)
        (background dark)) (:foreground "LightSkyBlue"))
      (((class color) (min-colors 8)) (:foreground "blue" :bold t))
      (t (:bold t))))
  "Face used for level 1 headlines."
  :group 'omm-faces)

;; originally copied from font-lock-variable-name-face
(defface omm-level-2
  (omm-compatible-face 'outline-2
    '((((class color) (min-colors 16)
        (background light)) (:foreground "DarkGoldenrod"))
      (((class color) (min-colors 16)
        (background dark))  (:foreground "LightGoldenrod"))
      (((class color) (min-colors 8)
        (background light)) (:foreground "yellow"))
      (((class color) (min-colors 8)
        (background dark))  (:foreground "yellow" :bold t))
      (t (:bold t))))
  "Face used for level 2 headlines."
  :group 'omm-faces)

;; originally copied from font-lock-keyword-face
(defface omm-level-3
  (omm-compatible-face 'outline-3
    '((((class color) (min-colors 88)
        (background light)) (:foreground "Purple"))
      (((class color) (min-colors 88)
        (background dark))  (:foreground "Cyan1"))
      (((class color) (min-colors 16)
        (background light)) (:foreground "Purple"))
      (((class color) (min-colors 16)
        (background dark))  (:foreground "Cyan"))
      (((class color) (min-colors 8)
        (background light)) (:foreground "purple" :bold t))
      (((class color) (min-colors 8)
        (background dark))  (:foreground "cyan" :bold t))
      (t (:bold t))))
  "Face used for level 3 headlines."
  :group 'omm-faces)

   ;; originally copied from font-lock-comment-face
(defface omm-level-4
  (omm-compatible-face 'outline-4
    '((((class color) (min-colors 88)
        (background light)) (:foreground "Firebrick"))
      (((class color) (min-colors 88)
        (background dark))  (:foreground "chocolate1"))
      (((class color) (min-colors 16)
        (background light)) (:foreground "red"))
      (((class color) (min-colors 16)
        (background dark))  (:foreground "red1"))
      (((class color) (min-colors 8)
        (background light))  (:foreground "red" :bold t))
      (((class color) (min-colors 8)
        (background dark))   (:foreground "red" :bold t))
      (t (:bold t))))
  "Face used for level 4 headlines."
  :group 'omm-faces)

 ;; originally copied from font-lock-type-face
(defface omm-level-5
  (omm-compatible-face 'outline-5
    '((((class color) (min-colors 16)
        (background light)) (:foreground "ForestGreen"))
      (((class color) (min-colors 16)
        (background dark)) (:foreground "PaleGreen"))
      (((class color) (min-colors 8)) (:foreground "green"))))
  "Face used for level 5 headlines."
  :group 'omm-faces)

 ;; originally copied from font-lock-constant-face
(defface omm-level-6
  (omm-compatible-face 'outline-6
    '((((class color) (min-colors 16)
        (background light)) (:foreground "CadetBlue"))
      (((class color) (min-colors 16)
        (background dark)) (:foreground "Aquamarine"))
      (((class color) (min-colors 8)) (:foreground "magenta")))) "Face used for level 6 headlines."
  :group 'omm-faces)

 ;; originally copied from font-lock-builtin-face
(defface omm-level-7
  (omm-compatible-face 'outline-7
    '((((class color) (min-colors 16)
        (background light)) (:foreground "Orchid"))
      (((class color) (min-colors 16)
        (background dark)) (:foreground "LightSteelBlue"))
      (((class color) (min-colors 8)) (:foreground "blue"))))
  "Face used for level 7 headlines."
  :group 'omm-faces)

 ;; originally copied from font-lock-string-face
(defface omm-level-8
  (omm-compatible-face 'outline-8
    '((((class color) (min-colors 16)
        (background light)) (:foreground "RosyBrown"))
      (((class color) (min-colors 16)
        (background dark)) (:foreground "LightSalmon"))
      (((class color) (min-colors 8)) (:foreground "green"))))
  "Face used for level 8 headlines."
  :group 'omm-faces)


;;; Mode Definitions

;;;###autoload
(define-minor-mode org-minor-mode
  "Toggle the minor mode `org-minor-mode'.

This mode is for using Org-mode commands in other modes.The
following keys behave as if Org-mode were active, if the cursor
is on a headline, on a plain list item (both as defined by
Org-mode) or on a comment line."
  nil " OrgMM"  (make-sparse-keymap)
  ;; (let ((org-minor-mode-map (make-sparse-keymap)))
  ;;   (set-keymap-parent org-minor-mode-map org-mode-map)
  ;;   org-minor-mode-map)
  (funcall (if org-minor-mode
	       'add-to-invisibility-spec
	     'remove-from-invisibility-spec)
	   '(outline . t))
  ;; (list
  ;;  '(outline . t)
  ;;  '(org-cwidth)
  ;;  '(org-hide-block . t)
  ;;  (and org-descriptive-links
  ;;       '(org-link))))
  (when org-minor-mode
    ;; arrange menus
    (if (featurep 'xemacs)
	(when (boundp 'outline-mode-menu-heading)
	  ;; Assume this is Greg's port, it uses easymenu
	  (easy-menu-remove outline-mode-menu-heading)
	  (easy-menu-remove outline-mode-menu-show)
	  (easy-menu-remove outline-mode-menu-hide))
      (define-key org-minor-mode-map [menu-bar headings] 'undefined)
      (define-key org-minor-mode-map [menu-bar hide] 'undefined)
      (define-key org-minor-mode-map [menu-bar show] 'undefined))
    (org-load-modules-maybe)
    (easy-menu-add org-org-menu)
    (easy-menu-add org-tbl-menu)
    (org-install-agenda-files-menu)
    (when (featurep 'xemacs)
      (org-set-local 'line-move-ignore-invisible t))
    ;; set adjusted BOL, EOL and STAR
    (org-set-local 'org-BOL (omm-calc-org-bol))
    (org-set-local 'org-EOL (omm-calc-org-eol))
    (org-set-local 'org-STAR (omm-calc-org-star))
    ;; set (partly adjusted) local variables
    (mapc
     (lambda (--pair)
       (org-set-local
	(car --pair)
	(let ((val (cadr --pair)))
	  (if (org-string-nw-p val)
	      (eval (omm-convert-static-to-dynamic-regexp val))
	    val))))
     (omm-get-local-variables 'org))
    ;; fix and add some local variables
    (setq outline-regexp (omm-calc-full-outline-regexp))
    (setq outline-level 'omm-calc-outline-level)   
    (org-set-local 'org-outline-regexp outline-regexp)
    (org-set-local 'org-outline-regexp-bol
		   (concat "^" outline-regexp))
    (org-set-local 'org-outline-level outline-level)
    ;; set (partly adjusted) global regexps as local variables
    (mapc
     (lambda (--pair)
       (org-set-local
	(car --pair)
	(let ((val (cadr --pair)))
	  (if (org-string-nw-p val)
	      (eval (omm-convert-static-to-dynamic-regexp val))
	    val))))
     (omm-get-global-org-regexps))
    ;; initialize (ex-)orgstruct
    ;; (unless omm-initialized
    ;;   (omm-setup)
    ;;   (setq omm-initialized t))
    ))

;;; Defuns

;;;; Advices
;;;; Functions
;;;;; Mode Initialization

;;;###autoload
(defun turn-on-omm ()
  "Unconditionally turn on `org-minor-mode'."
  (org-minor-mode 1))

;;;###autoload
(defun turn-on-omm++ ()
  "Unconditionally turn on `omm++-mode'."
  (omm++-mode 1))

(defun omm-setup ()
  "Setup orgstruct keymap."
  (dolist (cell '((org-demote . t)
		  (org-metaleft . t)
		  (org-metaright . t)
		  (org-promote . t)
		  (org-shiftmetaleft . t)
		  (org-shiftmetaright . t)
		  org-backward-element
		  org-backward-heading-same-level
		  org-ctrl-c-ret
		  org-ctrl-c-minus
		  org-ctrl-c-star
		  org-cycle
		  org-forward-heading-same-level
		  org-insert-heading
		  org-insert-heading-respect-content
		  org-kill-note-or-show-branches
		  org-mark-subtree
		  org-meta-return
		  org-metadown
		  org-metaup
		  org-narrow-to-subtree
		  org-promote-subtree
		  org-reveal
		  org-shiftdown
		  org-shiftleft
		  org-shiftmetadown
		  org-shiftmetaup
		  org-shiftright
		  org-shifttab
		  org-shifttab
		  org-shiftup
		  org-show-subtree
		  org-sort
		  org-up-element
		  outline-demote
		  outline-next-visible-heading
		  outline-previous-visible-heading
		  outline-promote
		  outline-up-heading
		  show-children))
    (let ((f (or (car-safe cell) cell))
	  (disable-when-heading-prefix (cdr-safe cell)))
      (when (fboundp f)
	(let ((new-bindings))
	  (dolist (binding
		   (nconc (where-is-internal
			   f org-mode-map)
			  (where-is-internal
			   f outline-mode-map)))
	    (push binding new-bindings)
	    ;; TODO use local-function-key-map
	    (dolist (rep '(("<tab>" . "TAB")
			   ("<return>" . "RET")
			   ("<escape>" . "ESC")
			   ("<delete>" . "DEL")))
	      (setq binding (read-kbd-macro
			     (let ((case-fold-search))
			       (replace-regexp-in-string
				(regexp-quote (cdr rep))
				(car rep)
				(key-description binding)))))
	      (pushnew binding new-bindings :test 'equal)))
	  (dolist (binding new-bindings)
	    (let ((key (lookup-key org-minor-mode-map binding)))
	      (when (or (not key) (numberp key))
		(condition-case nil
		    (org-defkey org-minor-mode-map
				binding
				(omm-make-binding
				 f binding
				 disable-when-heading-prefix))
		  (error nil)))))))))
  (run-hooks 'org-minor-mode-setup-hook))


;;;;; Keybindings

;;;;;; Orgstruct Keybinding

(defun omm-make-binding (fun key disable-when-heading-prefix)
  "Create a function for binding in org-minor-mode.

FUN is the command to call inside a table.  KEY is the key that
should be checked in for a command to execute outside of tables.
Non-nil `disable-when-heading-prefix' means to disable the command
if `omm-heading-prefix-regexp' is not empty."
  (let ((name (concat "omm-hijacker-" (symbol-name fun))))
    (let ((nname name)
	  (i 0))
      (while (fboundp (intern nname))
	(setq nname (format "%s-%d" name (setq i (1+ i)))))
      (setq name (intern nname)))
    (eval
     (let ((bindings '((org-heading-regexp
			(concat "^"
				omm-heading-prefix-regexp
				"\\(\\*+\\)\\(?: +\\(.*?\\)\\)?[		]*$"))
		       (org-outline-regexp
			(concat omm-heading-prefix-regexp "\\*+ "))
		       (org-outline-regexp-bol
			(concat "^" org-outline-regexp))
		       (outline-regexp org-outline-regexp)
		       (outline-heading-end-regexp "\n")
		       (outline-level 'org-outline-level)
		       (outline-heading-alist))))
       `(defun ,name (arg)
	  ,(concat "In Structure, run `" (symbol-name fun) "'.\n"
		   "Outside of structure, run the binding of `"
		   (key-description key) "'."
		   (when disable-when-heading-prefix
		     (concat
		      "\nIf `omm-heading-prefix-regexp' is not empty, this command will always fall\n"
		      "back to the default binding due to limitations of Org's implementation of\n"
		      "`" (symbol-name fun) "'.")))
	  (interactive "p")
	  (let* ((disable
		  ,(and disable-when-heading-prefix
			'(not (string= omm-heading-prefix-regexp ""))))
		 (fallback
		  (or disable
		      (not
		       (let* ,bindings
			 (org-context-p 'headline 'item
					,(when (memq fun
						     '(org-insert-heading
						       org-insert-heading-respect-content
						       org-meta-return))
					   '(when omm-is-++
					      'item-body))))))))
	    (if fallback
		(let* ((org-minor-mode)
		       (binding
			(loop with key = ,key
			      for rep in
			      '(nil
				("<\\([^>]*\\)tab>" . "\\1TAB")
				("<\\([^>]*\\)return>" . "\\1RET")
				("<\\([^>]*\\)escape>" . "\\1ESC")
				("<\\([^>]*\\)delete>" . "\\1DEL"))
			      do
			      (when rep
				(setq key (read-kbd-macro
					   (let ((case-fold-search))
					     (replace-regexp-in-string
					      (car rep)
					      (cdr rep)
					      (key-description key))))))
			      thereis (key-binding key))))
		  (if (keymapp binding)
		      (org-set-transient-map binding)
		    (let ((func (or binding
				    (unless disable
				      'omm-error))))
		      (when func
			(call-interactively func)))))
	      (org-run-like-in-org-mode
	       (lambda ()
		 (interactive)
		 (let* ,bindings
		   (call-interactively ',fun)))))))))
    name))


(defun org-contextualize-keys (alist contexts)
  "Return valid elements in ALIST depending on CONTEXTS.

`org-agenda-custom-commands' or `org-capture-templates' are the
values used for ALIST, and `org-agenda-custom-commands-contexts'
or `org-capture-templates-contexts' are the associated contexts
definitions."
  (let ((contexts
	 ;; normalize contexts
	 (mapcar
	  (lambda(c) (cond ((listp (cadr c))
			    (list (car c) (car c) (cadr c)))
			   ((string= "" (cadr c))
			    (list (car c) (car c) (caddr c)))
			   (t c))) contexts))
	(a alist) c r s)
    ;; loop over all commands or templates
    (while (setq c (pop a))
      (let (vrules repl)
	(cond
	 ((not (assoc (car c) contexts))
	  (push c r))
	 ((and (assoc (car c) contexts)
	       (setq vrules (org-contextualize-validate-key
			     (car c) contexts)))
	  (mapc (lambda (vr)
		  (when (not (equal (car vr) (cadr vr)))
		    (setq repl vr))) vrules)
	  (if (not repl) (push c r)
	    (push (cadr repl) s)
	    (push
	     (cons (car c)
		   (cdr (or (assoc (cadr repl) alist)
			    (error "Undefined key `%s' as contextual replacement for `%s'"
				   (cadr repl) (car c)))))
	     r))))))
    ;; Return limited ALIST, possibly with keys modified, and deduplicated
    (delq
     nil
     (delete-dups
      (mapcar (lambda (x)
		(let ((tpl (car x)))
		  (when (not (delq
			      nil
			      (mapcar (lambda(y)
					(equal y tpl)) s))) x)))
	      (reverse r))))))

(defun org-contextualize-validate-key (key contexts)
  "Check CONTEXTS for agenda or capture KEY."
  (let (r rr res)
    (while (setq r (pop contexts))
      (mapc
       (lambda (rr)
	 (when
	  (and (equal key (car r))
	       (if (functionp rr) (funcall rr)
		 (or (and (eq (car rr) 'in-file)
			  (buffer-file-name)
			  (string-match (cdr rr) (buffer-file-name)))
		     (and (eq (car rr) 'in-mode)
			  (string-match (cdr rr) (symbol-name major-mode)))
		     (and (eq (car rr) 'in-buffer)
			  (string-match (cdr rr) (buffer-name)))
		     (when (and (eq (car rr) 'not-in-file)
				(buffer-file-name))
		       (not (string-match (cdr rr) (buffer-file-name))))
		     (when (eq (car rr) 'not-in-mode)
		       (not (string-match (cdr rr) (symbol-name major-mode))))
		     (when (eq (car rr) 'not-in-buffer)
		       (not (string-match (cdr rr) (buffer-name)))))))
	  (push r res)))
       (car (last r))))
    (delete-dups (delq nil res))))

(defun org-context-p (&rest contexts)
  "Check if local context is any of CONTEXTS.
Possible values in the list of contexts are `table', `headline', and `item'."
  (let ((pos (point)))
    (goto-char (point-at-bol))
    (prog1 (or (and (memq 'table contexts)
		    (looking-at "[ \t]*|"))
	       (and (memq 'headline contexts)
		    (looking-at org-outline-regexp))
	       (and (memq 'item contexts)
		    (looking-at "[ \t]*\\([-+*] \\|[0-9]+[.)] \\)"))
	       (and (memq 'item-body contexts)
		    (org-in-item-p)))
      (goto-char pos))))

;;;;;; Compare Keymaps

(defun omm-get-cmd-symbols-with-keys (rgxp mode &optional req)
  "Return alist of (key . sym) pairs where sym matches RGXP.

Require REQ and load MODE in temp buffer before doing the real
work. Push the intermediary results of `mapatoms' to
`omm-tmp-storage'.

Usage example:
 (pp (omm-get-cmd-symbols-with-keys
   \"\\(^org-\\|^orgtbl-\\)\" 'org-mode 'org))"
  (setq omm-tmp-storage nil)
  (mapatoms
   (lambda (--sym)
     (eval
      `(and (commandp --sym)
	    (string-match ,rgxp (symbol-name --sym))
	    (with-temp-buffer
	      (when ,req
		(require (quote ,req)))
	      (funcall (quote ,mode))
	      (let ((cmd-key (substitute-command-keys
			      (concat
			       "\\[" (symbol-name --sym) "]"))))
		(push
		 (cons
		  (if (string-match "^M-x " cmd-key)
		      nil cmd-key)
		  --sym)
		 omm-tmp-storage)))))))
  (delq nil
	(mapcar
	 (lambda (--pair) (if (car --pair) --pair nil))
	 (delq nil omm-tmp-storage))))

(defun omm-get-keybinding-conflicts (cmd-syms1 cmd-syms2)
  "Return alist with common keys of CMD-SYMS1 and CMD-SYMS2.

The return-list consists of sublists of this form

  (event definition-map1 definition-map2)

Usage example:

  (pp (omm-get-keybinding-conflicts
     (omm-get-cmd-symbols-with-keys \"^magit-\" 'magit-mode)
     (omm-get-cmd-symbols-with-keys \"^dired-\" 'dired-mode)))"
  (let ((keys2 (map 'car cmd-syms2))) ; FIXME with org-mode-map
     (delq nil
	   (mapcar
	    (lambda (--pair)
	      (when (member (car --pair) keys2)
		 (list (car --pair)
		       (cdr --pair)
		       (cdr (assoc (car --pair) cmd-syms2)))))
	    cmd-syms1))))


;;;;; Calculate outline-regexp and outline-level

;; from http://emacswiki.org/emacs/ElispCookbook#toc6
(defun omm-chomp (str)
  "Chomp leading and trailing whitespace from STR."
  (save-excursion
    (save-match-data
      (while (string-match
              "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'"
              str)
        (setq str (replace-match "" t t str)))
      str)))


  
;; FIXME
(defun tj/convert-hard-coded-org-regexp (&optional)
  "Convert next hardcoded regexp after point in current buffer."
  (interactive)
  (cond
   ((looking-at (concat
		 (regexp-quote "\\(^\\)") ".*"
		 ;; fixme
		 "\"\\()\\| \\|$\\)")))))

;; dealing with special case of oldschool headers in elisp (;;;+)
(defun omm-modern-header-style-in-elisp-p (&optional buffer)
  "Return nil, if there is no match for a omm-style header.
Searches in BUFFER if given, otherwise in current buffer."
  (let ((buf (or buffer (current-buffer))))
    (with-current-buffer buf
      (save-excursion
        (goto-char (point-min))
        (re-search-forward
         (format "^;; [%s]+ " omm-regexp-base-char)
         nil 'NOERROR)))))

(defun omm-calc-normalized-outline-regexp-base ()
  "Return outline-regexp-base as string.
Furthermore set `omm-enforce-no-comment-padding-p' according to
regexp-base."
  (if (and
       (not (omm-modern-header-style-in-elisp-p))
       (eq major-mode 'emacs-lisp-mode))
      ;; oldschool elisp
      (progn
	(setq omm-enforce-no-comment-padding-p t)
	(setq omm-outline-regexp-base
	      (omm-chomp omm-oldschool-elisp-outline-regexp-base)))
    ;; default
    (setq omm-enforce-no-comment-padding-p nil)
	(setq omm-outline-regexp-base
	      (omm-chomp omm-default-outline-regexp-base))))

(defun omm-calc-comment-region-starter ()
  "Return comment-region starter as string.
Based on `comment-start' and `comment-add'."
(let ((normalized-comment-start (omm-chomp comment-start)))
  (if (or (not comment-add) (eq comment-add 0))
      normalized-comment-start
    (let ((comment-add-string normalized-comment-start))
      (dotimes (i comment-add comment-add-string)
        (setq comment-add-string
              (concat comment-add-string
		      normalized-comment-start)))))))

(defun omm-calc-comment-padding ()
  "Return comment-padding as string"
  (cond
   ;; comment-padding is nil
   ((not comment-padding) " ")
   ;; comment-padding is integer
   ((integer-or-marker-p comment-padding)
    (let ((comment-padding-string ""))
      (dotimes (i comment-padding comment-padding-string)
        (setq comment-padding-string
              (concat comment-padding-string " ")))))
   ;; comment-padding is string
   ((stringp comment-padding)
    comment-padding)
   (t (error "No valid comment-padding"))))

(defun omm-calc-outline-regexp-comment-part ()
  "Calculate comment-part of outline-regexp for current mode."
  (concat
   (and omm-outline-regexp-outcommented-p
         ;; regexp-base outcommented, but no 'comment-start' defined
         (or comment-start
             (message
	      (concat "Cannot calculate outcommented
	      outline-regexp without 'comment-start' character
	      defined!")))
         (concat
          ;; comment-start
          (regexp-quote
           (omm-calc-comment-region-starter))
          ;; comment-padding
          (if omm-enforce-no-comment-padding-p
              ""
            (omm-calc-comment-padding))))))

(defun omm-calc-full-outline-regexp ()
  "Calculate full outline regexp for current mode."
  (let ((rgxp-base (omm-calc-normalized-outline-regexp-base)))
  (concat (omm-calc-outline-regexp-comment-part)
	  rgxp-base " ")))

;; TODO how is this called (match-data?) 'looking-at' necessary?
(defun omm-calc-outline-level ()
  "Calculate the right outline level for the
  omm-outline-regexp"
  (save-excursion
    (save-match-data
      ;; (and
      ;;  (looking-at (omm-calc-outline-regexp))
       ;; ;; FIXME this works?
       ;; (looking-at outline-regexp)
       (let ((m-strg (match-string-no-properties 0)))
         (if omm-enforce-no-comment-padding-p
             ;; deal with oldschool elisp headings (;;;+)
             (setq m-strg
                   (split-string
                    (substring m-strg 2)
                    nil
                    'OMIT-NULLS))
           ;; orgmode style elisp heading (;; *+)
           (setq m-strg
                 (split-string
                  m-strg
                  (format "%s" (omm-chomp comment-start))
                  'OMIT-NULLS)))
         (length
          (mapconcat
           (lambda (str)
             (car
              (split-string
               str
               " "
               'OMIT-NULLS)))
           m-strg
           "")))
       )))

;;;;; Calc BOL, EOL and STAR

(defun omm-calc-org-bol ()
  "Calculate buffer-local variable `org-BOL'."
  (format "^%s"
	  (omm-calc-outline-regexp-comment-part)))


(defun omm-calc-org-eol ()
  "Calculate buffer-local variable `org-EOL'."
  (format "%s$"
	  (if (org-string-nw-p comment-end)
	      (concat (regexp-quote comment-end)
		      "[[:space:]]*")
	    "")))

(defun omm-calc-org-star ()
  "Calculate buffer-local variable `org-STAR'."
  (if omm-enforce-no-comment-padding-p
      (regexp-quote omm-oldschool-elisp-regexp-base-char)
    (regexp-quote omm-regexp-base-char)))

;;;;; Set outline-regexp und outline-level

;; (defun omm-set-local-outline-regexp-and-level
;;   (start-regexp &optional fun end-regexp)
;;    "Set `outline-regexp' locally to START-REGEXP.
;; Set optionally `outline-level' to FUN and
;; `outline-heading-end-regexp' to END-REGEXP."
;;         (make-local-variable 'outline-regexp)
;;         (make-local-variable 'org-outline-regexp)
;;         (setq outline-regexp start-regexp)
;;         (setq org-outline-regexp start-regexp)
;;         (and fun
;;              (make-local-variable 'outline-level)
;;              (setq outline-level fun)
;;              (make-local-variable 'org-outline-level)
;;              (setq org-outline-level fun))
;;         (and end-regexp
;;              (make-local-variable 'outline-heading-end-regexp)
;;              (setq outline-heading-end-regexp end-regexp)))


;;;;; Return outline-string at given level

(defun omm-calc-outline-string-at-level (level)
  "Return outline-string at level LEVEL."
  (let ((base-string (omm-calc-outline-base-string-at-level level)))
    (if (not omm-outline-regexp-outcommented-p)
        base-string
      (concat (omm-calc-comment-region-starter)
              (if omm-enforce-no-comment-padding-p
                  ""
                (omm-calc-comment-padding))
              base-string
              " "))))

(defun omm-calc-outline-base-string-at-level (level)
  "Return outline-base-string at level LEVEL."
  (let* ((star (omm-transform-normalized-outline-regexp-base-to-string))
         (stars star))
       (dotimes (i (1- level) stars)
         (setq stars (concat stars star)))))

(defun omm-transform-normalized-outline-regexp-base-to-string ()
  "Transform 'outline-regexp-base' to string by stripping off special chars."
  (replace-regexp-in-string
   omm-outline-regexp-special-chars
   ""
   (omm-calc-normalized-outline-regexp-base)))

;; make demote/promote from `outline-magic' work
(defun omm-make-promotion-headings-list (max-level)
  "Make a sorted list of headings used for promotion/demotion commands.
Set this to a list of MAX-LEVEL headings as they are matched by `outline-regexp',
top-level heading first."
  (let ((list-of-heading-levels
         `((,(omm-calc-outline-string-at-level 1) . 1))))
    (dotimes (i (1- max-level) list-of-heading-levels)
            (add-to-list
             'list-of-heading-levels
             `(,(omm-calc-outline-string-at-level (+ i 2)) . ,(+ i 2))
             'APPEND))))

;;;;; Convert Org Regexps

;; FIXME conditional list building
(defun omm-convert-static-to-dynamic-regexp (rgxp)
  "Convert static RGXP to dynamically calculated form."
    (with-temp-buffer
      (insert (format "%S" rgxp))
      (goto-char (point-min))
      (re-search-forward omm-org-regexp-matcher nil 'NOERROR)
      (let ((grp2 (ignore-errors (match-string 2)))
	    (grp3 (ignore-errors (match-string 3)))
	    (grp4 (ignore-errors (match-string 4)))
	    (grp5 (ignore-errors (match-string 5))))
	(message "%S" grp3)
	(list 'org-rx (or grp4 "")
	      (if grp2 t nil) 
	      (cond
	       ((or (string= grp3 "\\\\*+")
		    (string= grp3 "\\\\(\\\\*+\\\\)")
		    (string= grp3 "\\\\(\\\\**\\\\)\\\\(\\\\* \\\\)")
		    (string= grp3 "\\*+")
		    (string= grp3 "*+")) t)
		((string= grp3 "\\\\(\\\\*\\\\*\\\\)+") "2-4")
		((string= grp3 "\\\\*\\\\*+") "2+")
		((string= grp3 "\\\\*") 1)
		(t nil))
	      (if grp5 t nil)))))
     
(defun omm-get-local-variables (&optional filter)
  "Return a list of all local variables in an Org mode buffer.

Optional argument FILTER selects variables that match org-keys if
its value is the symbol 'org or the string \"org\", and variables
that do not match org-keys if its any other non-nil value."
  (let ((org-keys (list "org-" "orgtbl-" "outline-"))
	(non-org-keys (list "comment-" "paragraph-" "auto-fill" "normal-auto-fill" "fill-paragraph" "indent-"))
	varlist)
    (with-current-buffer (get-buffer-create "*Org tmp*")
      (erase-buffer)
      (org-mode)
      (setq varlist (buffer-local-variables)))
    (kill-buffer "*Org tmp*")
    (delq nil
          (mapcar
           (lambda (x)
             (setq x
                   (if (symbolp x)
                       (list x)
                     (list (car x) (cdr x))))
                     ;; (cons (car x) (cdr x))))
             (if (and (not (get (car x) 'org-state))
                      (string-match
		       (concat
			"^\\("
			(cond
			 ((and filter
			       (or
				(and (symbolp filter)
				     (eq filter 'org))
				(and (stringp filter)
				     (string-equal filter "org"))))
			  (mapconcat
			   'identity org-keys "\\|"))
			 (filter 
			  (mapconcat
			   'identity non-org-keys "\\|"))
			 (t 
			  (mapconcat
			   'identity
			   (append org-keys non-org-keys)
			   "\\|")))			 
			"\\)")
                       (symbol-name (car x))))
                 x nil))
           varlist))))

(defun omm-get-global-org-regexps ()
  "Return regexps from `omm-global-org-regexps' as key/value pairs."
  (mapcar
   (lambda (--rgxp)
     (list --rgxp (eval --rgxp)))
     omm-global-org-regexps))
  

(defun omm-clone-local-variables (from-buffer &optional filter-rgxp)
  "Clone local variables from FROM-BUFFER.
Optional argument FILTER-RGXP selects variables to clone."
    (mapc
     (lambda (pair)
       (and (symbolp (car pair))
	    (or (null filter-rgxp)
		(string-match filter-rgxp (symbol-name (car pair))))
	    (set (make-local-variable (car pair))
		 ;; FIXME cdr or cadr?
		 (cdr pair))))
     (buffer-local-variables from-buffer)))


;;;;; Run Commands like in Org-mode

(defun omm-comment-line-p ()
  "Return non-nil when current line is out-commented."
  (save-excursion
    (comment-normalize-vars)
    (beginning-of-line)
    (eq (point)
	(comment-search-forward (line-end-position) 'NOERROR))))

(defun omm-outcomment-diff-lines (buf-or-file2 &optional buf-or-file1 exec-diff-program)
  "Call `comment-region' on all lines in diffs of file args.

BUF-OR-FILE1 should be the file (or its visiting buffer) where
new lines have been added, e.g. the current-buffer in its actual
state, BUF-OR-FILE2 the smaller original file (or its visiting
buffer) e.g. a backup of the current-buffer in its former state.

EXEC-DIFF-PROGRAM is not used by this function, but needed to
call `omm-get-diff-lines'. If non-nil, it should be an executable
shell-command.

Expects a nested list of variable length with numeric string
values in sublist of length 1 or 2 as input, e.g. like this

 '((\"3\") (\"14\" \"23\"))

If optional argument BUF-OR-NAME is non-nil, act on this buffer, otherwise on current-buffer."
  (let* ((file1 (if (org-string-nw-p buf-or-file1)
		    (if (get-buffer buf-or-file1)
			;; is buffer
			(or (buffer-file-name
			     (get-buffer buf-or-file1))
			    (with-current-buffer buf-or-file1
			      (let ((tmp-file (make-temp-file
					       "omm-diff-file1-")))
				(write-region nil nil tmp-file)
				tmp-file)))
		      ;; is file name
		      (and (file-readable-p buf-or-file1)
			   (file-writable-p buf-or-file1)
			   buf-or-file1))
		  ;; use current-buffer
		  (or (buffer-file-name (current-buffer))
		      (let ((tmp-file (make-temp-file
				       "omm-diff-file1-")))
			(write-region nil nil tmp-file)
			tmp-file))))
	 (file2 (cond
		 ((and
		   (org-string-nw-p buf-or-file2)
		   (get-buffer buf-or-file2))
		  ;; is buffer
		  (or (buffer-file-name
		       (get-buffer buf-or-file2))
		      (with-current-buffer buf-or-file2
			(let ((tmp-file
			       (make-temp-file
				"omm-diff-file2-")))
			  (write-region nil nil tmp-file)
			  tmp-file))))
		 ;; is file name
		 ((and
		   (org-string-nw-p buf-or-file2)	
		   (file-readable-p buf-or-file2)
		   (file-writable-p buf-or-file2))
		  buf-or-file2)
		 ;; neither buffer nor file
		 (t (error "%s not a valid buffer or file"
			   buf-or-file2))))
	 (big-file (if (>= (nth 7 (file-attributes file1))
			   (nth 7 (file-attributes file2)))
		       file1
		     (progn
		       (message
			(concat "Warning: the optional 2nd diff "
				"file \n%s\n is smaller than the "
				"1st diff file \n%s\n") file2 file1)
		       file2)))
	 (small-file (if (file-equal-p big-file file1)
			 file2 file1)))
    ;; (message "big-file: %s\nsmall-file: %s" big-file small-file)
    (with-current-buffer (find-file big-file)
      (save-excursion
	(save-restriction
	  (widen)
	  ;; (org-mode)
	  ;; (show-all)
	  (mapc
	   (lambda (--lnum)
	     (message "%s" --lnum)
	     (and --lnum
		  ;; FIXME robust enough?
		  (let ((comment-style 'plain))
		    (comment-region
		     (progn
		       (goto-line --lnum)
		       (line-beginning-position))
		     (line-end-position)))))
	   (omm-get-diff-lines
	    small-file big-file exec-diff-program))
	  ;; buffer was saved anyway for the diff call
	  (save-buffer))))))

;; FIXME 2: fix this in calling function
;; FIXME 4: use org trailing empty line or so
(defun omm-get-diff-lines (small-file big-file &optional exec-diff-program)
  "Get line-number of added lines in diff of file args.

Optional string argument EXEC-DIFF-PROGRAM defaults to
`omm-default-exec-diff-program'and should be an executable
shell-command.

This function processes the default output from this command-line
utility (that must have the same input and output format as
`diff'). Here is an output example:

,------------------------------------------------------
| 1,2d0
| < The Way that can be told of is not the eternal Way;
| < The name that can be named is not the eternal name.
| 4c2,3
| < The Named is the mother of all things.
| ---
| > The named is the mother of all things.
`------------------------------------------------------

It first produces a raw diff-list by removing all lines except
those with change
commands \(http://www.chemie.fu-berlin.de/chemnet/use/info/diff/diff_3.html\):

,------------------------------------------------------------------
| There are three types of change commands. Each consists of a line
| number or comma-separated range of lines in the first file, a
| single character indicating the kind of change to make, and a
| line number or comma-separated range of lines in the second
| file. All line numbers are the original line numbers in each
| file. The types of change commands are:
| 
| `lar'
|     Add the lines in range r of the second file after line l of
|     the first file. For example, `8a12,15' means append lines
|     12--15 of file 2 after line 8 of file 1; or, if changing file
|     2 into file 1, delete lines 12--15 of file 2.
| `fct'
|     Replace the lines in range f of the first file with lines in
|     range t of the second file. This is like a combined add and
|     delete, but more compact. For example, `5,7c8,10' means
|     change lines 5--7 of file 1 to read as lines 8--10 of file 2;
|     or, if changing file 2 into file 1, change lines 8--10 of
|     file 2 to read as lines 5--7 of file 1.
| `rdl'
|     Delete the lines in range r from the first file; line l is
|     where they would have appeared in the second file had they
|     not been deleted. For example, `5,7d3' means delete lines
|     5--7 of file 1; or, if changing file 2 into file 1, append
|     lines 5--7 of file 1 after line 3 of file 2.
`------------------------------------------------------------------

Then the change commands are processed, meaning that they are
converted to a list containing a number-sequence of those lines
that are only in the big-file but not in the small-file. That is
done by removing the delete entries (d) and processing the 'r'
side of the add commands (a) as well as the 'f' and 't' side of
the replace commands (c). The resulting 'a-lst', 'c-lst1' and
'cl-lst2' are then appended into one single list and returned.

It would have been possible to achieve the same result by
deleting the 'a' commands and processing the 'd' commands, but
then the order of the file arguments in the call to `diff' must
be reversed. Thus this function only deals with 'a' commands and
expects the SMALL-FILE to be the first file arg when calling the
EXEC-DIFF-PROGRAM, and the BIG-FILE to come second."
  (let* ((diff-prg (or (org-string-nw-p exec-diff-program)
		       omm-default-exec-diff-program))
	 ;; delete all lines except change commands
	 (diff-lst (split-string
		    (shell-command-to-string
		     (format "%s %s %s"
			     diff-prg small-file big-file))
		    "\\(---\\|^<.*$\\|^>.*\\|\\\n\\)"))
	 ;; process the 'a' commands
	 (a-lst (mapcar 'string-to-number
			(car (mapcar
			      (lambda (--pair)
				(split-string (cadr --pair) ","))
			      (mapcar (lambda (--diff)
					(split-string --diff "a"))
				      (remove-if
				       (lambda (--strg)
					 (let ((split
						(split-string
						 --strg "")))
					   (or (not
						(org-string-nw-p
						 --strg))
					       (member "c" split)
					       (member "d" split))))
				       diff-lst))))))
	 ;; pre-process the 'c' commands
	 (c-lst (mapcar
		 (lambda (--diff)
		   (split-string --diff "c"))
		 (remove-if
		  (lambda (--strg)
		    (let ((split (split-string --strg "")))
		      (or (not (org-string-nw-p --strg))
			  (member "a" split)
			  (member "d" split))))
		  diff-lst)))
	 ;; process car of pre-processed 'c' commands
	 (c-lst1 (mapcar 'string-to-number
			 (car (mapcar
			       (lambda (--pair)
				 (split-string
				  (car-safe --pair) ","))
			       c-lst))))
	 ;; process cdr of pre-processed 'c' commands
	 (c-lst2 (mapcar 'string-to-number
			 (car (mapcar
			       (lambda (--pair)
				 (split-string
				  (car-safe (cdr-safe --pair))
				  ","))
			       c-lst)))))
    ;; (message "diff-lst: %s" diff-lst)
    ;; (message "a-lst: %s" a-lst)
    ;; (message "c-lst: %s" c-lst)
    ;; (message "c-lst1: %s" c-lst1)
    ;; (message "c-lst2: %s" c-lst2)
    ;; (message "append: %s"

    ;; append result lists into a singe number-sequence
    (append
     ;; find non-intersecting sub-set of processed car and cdr of
     ;; 'c' commands list
     (set-difference
      (number-sequence (car-safe c-lst1)
		       (car-safe (cdr-safe c-lst1)))
      (number-sequence (car-safe c-lst2)
		       (car-safe (cdr-safe c-lst2))))
     (number-sequence (car-safe a-lst)
		      (car-safe (cdr-safe a-lst)))))) ;)

;;;###autoload
(defun omm-cmd (org-cmd &optional with-non-org-vars-p)
  "Call ORG-CMD from org-minor-mode in current-buffer.

If WITH-NON-ORG-VARS-P is non-nil, this will temporarily bind
local variables that are typically bound in Org-mode to the
values they have in Org-mode - but only those whose names don't
start with 'org-', 'outline-' or 'orgtbl-', because these are
already set permanently in a modified form - and then
interactively call ORG-CMD.

This function takes care of outcommenting any new lines that have
been introduced into the current-buffer by executing ORG-CMD.

It does not do the real work itself but rather calls
`omm-outcomment-diff-lines' and `org-run-like-in-org-mode' after
preparing their function arguments."
  ;; FIXME
  (interactive "COrg Command: \n")
  (let* ((curr-file (or (buffer-file-name (current-buffer))
			(write-file
			 (make-temp-file (buffer-name)))))
	 (tmp-file (make-temp-file "omm-tmp-")))
    (message "curr-file: %s\ntmp-file: %s" curr-file tmp-file)
    (write-region nil nil tmp-file)
    (org-run-like-in-org-mode org-cmd with-non-org-vars-p)
    (save-buffer)
    (omm-outcomment-diff-lines tmp-file)))
      

;;;###autoload
(defun org-run-like-in-org-mode (cmd &optional with-non-org-vars-p)
  "Run a command, pretending that the current buffer is in Org-mode.

This will temporarily bind local variables that are typically
bound in Org-mode to the values they have in Org-mode, and then
interactively call CMD. If WITH-NON-ORG-VARS-P is non-nil, a few
additional variables are set buffer-locally."
  (org-load-modules-maybe)
  (if with-non-org-vars-p
      (progn
	(unless org-local-vars
	  ;; (setq org-local-vars (omm-get-local-variables)))
	  (setq org-local-vars
		(omm-get-local-variables 'non-org)))
	(let (binds)
	  (dolist (var org-local-vars)
	    (when (or (not (boundp (car var)))
		      (eq (symbol-value (car var))
			  (default-value (car var))))
	      (push (list (car var) `(quote ,(cadr var))) binds)))
	  (eval `(let ,binds
		   (call-interactively (quote ,cmd))))))
    (eval `(call-interactively (quote ,cmd)))))

;;;;; Archiving

(defun org-get-category (&optional pos force-refresh)
  "Get the category applying to position POS."
  (save-match-data
    (if force-refresh (org-refresh-category-properties))
    (let ((pos (or pos (point))))
      (or (get-text-property pos 'org-category)
	  (progn (org-refresh-category-properties)
		 (get-text-property pos 'org-category))))))

(defun org-refresh-category-properties ()
  "Refresh category text properties in the buffer."
  (let ((case-fold-search t)
	(inhibit-read-only t)
	(def-cat (cond
		  ((null org-category)
		   (if buffer-file-name
		       (file-name-sans-extension
			(file-name-nondirectory buffer-file-name))
		     "???"))
		  ((symbolp org-category) (symbol-name org-category))
		  (t org-category)))
	beg end cat pos optionp)
    (org-with-silent-modifications
     (save-excursion
       (save-restriction
	 (widen)
	 (goto-char (point-min))
	 (put-text-property (point) (point-max) 'org-category def-cat)
	 (while (re-search-forward
		 "^\\(#\\+CATEGORY:\\|[ \t]*:CATEGORY:\\)\\(.*\\)" nil t)
	   (setq pos (match-end 0)
		 optionp (equal (char-after (match-beginning 0)) ?#)
		 cat (org-trim (match-string 2)))
	   (if optionp
	       (setq beg (point-at-bol) end (point-max))
	     (org-back-to-heading t)
	     (setq beg (point) end (org-end-of-subtree t t)))
	   (put-text-property beg end 'org-category cat)
	   (put-text-property beg end 'org-category-position beg)
	   (goto-char pos)))))))

(defun org-refresh-properties (dprop tprop)
  "Refresh buffer text properties.
DPROP is the drawer property and TPROP is the corresponding text
property to set."
  (let ((case-fold-search t)
	(inhibit-read-only t) p)
    (org-with-silent-modifications
     (save-excursion
       (save-restriction
	 (widen)
	 (goto-char (point-min))
	 (while (re-search-forward (concat "^[ \t]*:" dprop ": +\\(.*\\)[ \t]*$") nil t)
	   (setq p (org-match-string-no-properties 1))
	   (save-excursion
	     (org-back-to-heading t)
	     (put-text-property
	      (point-at-bol) (org-end-of-subtree t t) tprop p))))))))

;;;;; Fontify the headlines

(defun omm-fontify-headlines (outline-regexp)
  "Calculate heading regexps for font-lock mode."
  (let* ((outline-rgxp (substring outline-regexp 0 -1))
         (heading-1-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{1\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-2-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{2\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-3-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{3\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-4-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{4\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-5-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{5\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-6-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{6\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-7-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{7\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)"))
        (heading-8-regexp
         (format "%s%s%s%s"
                 outline-rgxp
                 "\\{8\\} \\(.*"
                 (if omm-fontify-whole-heading-line "\n?" "")
                 "\\)")))
    (font-lock-add-keywords
     nil
     `((,heading-1-regexp 1 'omm-level-1 t)
       (,heading-2-regexp 1 'omm-level-2 t)
       (,heading-3-regexp 1 'omm-level-3 t)
       (,heading-4-regexp 1 'omm-level-4 t)
       (,heading-5-regexp 1 'omm-level-5 t)
       (,heading-6-regexp 1 'omm-level-6 t)
       (,heading-7-regexp 1 'omm-level-7 t)
       (,heading-8-regexp 1 'omm-level-8 t)))))


;;;;; Functions for speed-commands

;; copied and modified from org-mode.el
(defun omm-print-speed-command (e)
  (if (> (length (car e)) 1)
      (progn
        (princ "\n")
        (princ (car e))
        (princ "\n")
        (princ (make-string (length (car e)) ?-))
        (princ "\n"))
    (princ (car e))
    (princ "   ")
    (if (symbolp (cdr e))
        (princ (symbol-name (cdr e)))
      (prin1 (cdr e)))
    (princ "\n")))

(defun omm-speed-command-activate (keys)
  "Hook for activating single-letter speed commands.
`omm-speed-commands-default' specifies a minimal command set.
Use `omm-speed-commands-user' for further customization."
  (when (or (and
             (bolp)
             (looking-at outline-regexp))
             ;; (looking-at (omm-calc-outline-regexp)))
            (and
             (functionp omm-use-speed-commands)
             (funcall omm-use-speed-commands)))
    (cdr (assoc keys (append omm-speed-commands-user
                             omm-speed-commands-default)))))


(defun omm-defkey (keymap key def)
  "Define a KEY in a KEYMAP with definition DEF."
  (define-key keymap key def))

(defun omm-remap (map &rest commands)
  "In MAP, remap the functions given in COMMANDS.
COMMANDS is a list of alternating OLDDEF NEWDEF command names."
  (let (new old)
    (while commands
      (setq old (pop commands) new (pop commands))
      (if (fboundp 'command-remapping)
          (omm-defkey map (vector 'remap old) new)
        (substitute-key-definition old new map global-map)))))

(omm-remap outline-minor-mode-map
             'self-insert-command 'omm-self-insert-command)

;;;;; Use outorg

(eval-after-load 'outorg
  '(defun omm-use-outorg (fun &optional whole-buffer-p &rest funargs)
     "Use outorg to call FUN with FUNARGS on subtree.

FUN should be an Org-mode function that acts on the subtree at
point. Optionally, with WHOLE-BUFFER-P non-nil,
`outorg-edit-as-org' can be called on the whole buffer.

Sets the variable `omm-use-outorg-last-headline-marker' so
that it always contains a point-marker to the last headline this
function was called upon.

The old marker is removed first. Then a new point-marker is
created before `outorg-edit-as-org' is called on the headline."
     (save-excursion
       (unless (outline-on-heading-p)
         (outline-previous-heading))
       (omm--set-outorg-last-headline-marker)
       (if whole-buffer-p
           (outorg-edit-as-org '(4))
         (outorg-edit-as-org))
       (if funargs
           (funcall fun funargs)
         (funcall fun))
       (outorg-copy-edits-and-exit))))

(defun omm--set-outorg-last-headline-marker ()
  "Set a point-marker to current header and remove old marker.

Sets the variable `omm-use-outorg-last-headline-marker'."
  (if (integer-or-marker-p
       omm-use-outorg-last-headline-marker)
      (move-marker omm-use-outorg-last-headline-marker (point))
    (setq omm-use-outorg-last-headline-marker
          (point-marker))))

(defun omm-clock-out ()
  "Stop Org-mode clock started with `omm-use-outorg'."
  (if (integer-or-marker-p
       omm-use-outorg-last-headline-marker)
      (save-excursion
        (goto-char
         (marker-position
          omm-use-outorg-last-headline-marker))
        (omm-use-outorg
         (lambda ()
           (ignore-errors
             (org-clock-cancel))
           (org-clock-in)
           (org-clock-out))))))
    
;;;;; Hook function

;; ;; FIXME move this to (define-minor-mode ...)
;; (defun omm-hook-function ()
;;   "Add this function to outline-minor-mode-hook"
;;   (omm-set-outline-regexp-base)
;;   (omm-normalize-regexps)
;;   (let ((out-regexp (omm-calc-outline-regexp)))
;;     (omm-set-local-outline-regexp-and-level
;;      out-regexp
;;      'omm-calc-outline-level
;;      omm-outline-heading-end-regexp)
;;     (omm-fontify-headlines out-regexp)
;;     (setq outline-promotion-headings
;;           (omm-make-promotion-headings-list 8))
;;     ;; imenu preparation
;;     (and omm-imenu-show-headlines-p
;;          (set (make-local-variable
;;                'omm-imenu-preliminary-generic-expression)
;;                `((nil ,(concat out-regexp "\\(.*$\\)") 1)))
;;          (setq imenu-generic-expression
;;                omm-imenu-preliminary-generic-expression)))
;;   (when omm-startup-folded-p
;;     (condition-case error-data
;;         (outline-hide-sublevels 1)
;;       ('error (message "No outline structure detected")))))

;; ;; ;; add this to your .emacs
;; ;; (add-hook 'outline-minor-mode-hook 'omm-hook-function)
;; (add-hook 'emacs-lisp-mode-hook 'omm-hook-function)

;;;; Commands

(defun omm++-mode (&optional arg)
  "Toggle `org-minor-mode', the enhanced version of it.
In addition to setting org-minor-mode, this also exports all
indentation and autofilling variables from org-mode into the
buffer.  It will also recognize item context in multiline items."
  (interactive "P")
  (setq arg (prefix-numeric-value (or arg (if org-minor-mode -1 1))))
  (if (< arg 1)
      (progn (org-minor-mode -1)
	     (mapc (lambda(v)
		     (org-set-local (car v)
				    (if (eq (car-safe (cadr v)) 'quote) (cadadr v) (cadr v))))
		   org-fb-vars))
    (org-minor-mode 1)
    (setq org-fb-vars nil)
    (unless org-local-vars
      (setq org-local-vars (omm-get-local-variables)))
    (let (var val)
      (mapc
       (lambda (x)
	 (when (string-match
		"^\\(paragraph-\\|auto-fill\\|normal-auto-fill\\|fill-paragraph\\|fill-prefix\\|indent-\\)"
		(symbol-name (car x)))
	   (setq var (car x) val (nth 1 x))
	   (push (list var `(quote ,(eval var))) org-fb-vars)
	   (org-set-local var (if (eq (car-safe val) 'quote) (nth 1 val) val))))
       org-local-vars)
      (org-set-local 'omm-is-++ t))))

(defun omm-error ()
  "Error when there is no default binding for a structure key."
  (interactive)
  (funcall (if (fboundp 'user-error)
	       'user-error
	     'error)
	   "This key has no function outside structure elements"))

;;;;; Speed commands

(defun omm-speed-command-help ()
  "Show the available speed commands."
  (interactive)
  (if (not omm-use-speed-commands)
      (user-error "Speed commands are not activated, customize `omm-use-speed-commands'")
    (with-output-to-temp-buffer "*Help*"
      (princ "User-defined Speed commands\n===========================\n")
      (mapc 'omm-print-speed-command omm-speed-commands-user)
      (princ "\n")
      (princ "Built-in Speed commands\n=======================\n")
      (mapc 'omm-print-speed-command omm-speed-commands-default))
    (with-current-buffer "*Help*"
      (setq truncate-lines t))))

(defun omm-speed-move-safe (cmd)
  "Execute CMD, but make sure that the cursor always ends up in a headline.
If not, return to the original position and throw an error."
  (interactive)
  (let ((pos (point)))
    (call-interactively cmd)
    (unless (and (bolp) (outline-on-heading-p))
      (goto-char pos)
      (error "Boundary reached while executing %s" cmd))))


(defun omm-self-insert-command (N)
  "Like `self-insert-command', use overwrite-mode for whitespace in tables.
If the cursor is in a table looking at whitespace, the whitespace is
overwritten, and the table is not marked as requiring realignment."
  (interactive "p")
  ;; (omm-check-before-invisible-edit 'insert)
  (cond
   ((and omm-use-speed-commands
         (setq omm-speed-command
               (run-hook-with-args-until-success
                'omm-speed-command-hook (this-command-keys))))
    (cond
     ((commandp omm-speed-command)
      (setq this-command omm-speed-command)
      (call-interactively omm-speed-command))
     ((functionp omm-speed-command)
      (funcall omm-speed-command))
     ((and omm-speed-command (listp omm-speed-command))
      (eval omm-speed-command))
     (t (let (omm-use-speed-commands)
          (call-interactively 'omm-self-insert-command)))))   
   (t
    (self-insert-command N)
    (if omm-self-insert-cluster-for-undo
        (if (not (eq last-command 'omm-self-insert-command))
            (setq omm-self-insert-command-undo-counter 1)
          (if (>= omm-self-insert-command-undo-counter 20)
              (setq omm-self-insert-command-undo-counter 1)
            (and (> omm-self-insert-command-undo-counter 0)
                 buffer-undo-list (listp buffer-undo-list)
                 (not (cadr buffer-undo-list)) ; remove nil entry
                 (setcdr buffer-undo-list (cddr buffer-undo-list)))
            (setq omm-self-insert-command-undo-counter
                  (1+ omm-self-insert-command-undo-counter))))))))

;; comply with `delete-selection-mode'
(put 'omm-self-insert-command 'delete-selection t)

;;;;; iMenu and idoMenu Support

(defun omm-imenu-with-navi-regexp
  (kbd-key &optional PREFER-IMENU-P LAST-PARENTH-EXPR-P)
  "Enhanced iMenu/idoMenu support depending on `navi-mode'.

KBD-KEY is a single character keyboard-key defined as a
user-command for a keyword-search in `navi-mode'. A list of all
registered major-mode languages and their single-key commands can
be found in the customizable variable `navi-key-mappings'. The
regexps that define the keyword-searches associated with these
keyboard-keys can be found in the customizable variable
`navi-keywords'. 

Note that all printable ASCII characters are predefined as
single-key commands in navi-mode, i.e. you can define
key-mappings and keywords for languages not yet registered in
navi-mode or add your own key-mappings and keywords for languages
already registered simply by customizing the two variables
mentioned above - as long as there are free keys available for
the language at hand. You need to respect navi-mode's own core
keybindings when doing so, of course.

Please share your own language definitions with the author so
that they can be included in navi-mode, resulting in a growing
number of supported languages over time.

If PREFER-IMENU-P is non-nil, this command calls `imenu' even if
`idomenu' is available.

By default, the whole string matched by the keyword-regexp plus the text
before the next space character is shown as result. If LAST-PARENTH-EXPR-P is
non-nil, only the last parenthetical expression in the match-data is shown,
i.e. the text following the regexp match until the next space character."
  ;; (interactive "cKeyboard key: ")
  (interactive
   (cond
    ((equal current-prefix-arg nil)
     (list (read-char "Key: ")))
    ((equal current-prefix-arg '(4))
     (list (read-char "Key: ")
           nil 'LAST-PARENTH-EXPR-P))
    ((equal current-prefix-arg '(16))
     (list (read-char "Key: ")
           'PREFER-IMENU-P 'LAST-PARENTH-EXPR-P))
    (t (list (read-char "Key: ")
             'PREFER-IMENU-P))))
  (if (require 'navi-mode nil 'NOERROR)
      (let* ((lang (car (split-string
                         (symbol-name major-mode)
                         "-mode" 'OMIT-NULLS)))
             (key (navi-map-keyboard-to-key
                   lang (char-to-string kbd-key)))
             (base-rgx (navi-get-regexp lang key))
             ;; (rgx (concat base-rgx "\\([^[:space:]]+[[:space:]]?$\\)"))
             (rgx (concat base-rgx "\\([^[:space:]]+[[:space:]]\\)"))
             (rgx-depth (regexp-opt-depth rgx))
             (omm-imenu-generic-expression
              `((nil ,rgx ,(if LAST-PARENTH-EXPR-P rgx-depth 0))))
             (imenu-generic-expression
              omm-imenu-generic-expression)
             (imenu-prev-index-position-function nil)
             (imenu-extract-index-name-function nil)
             (imenu-auto-rescan t)
             (imenu-auto-rescan-maxout 360000))
        ;; prefer idomenu
        (if (and (require 'idomenu nil 'NOERROR)
                 (not PREFER-IMENU-P))
            (funcall 'idomenu)
          ;; else call imenu
          (funcall 'imenu
                   (imenu-choose-buffer-index
                    (concat (car
                             (split-string
                              (symbol-name key) ":" 'OMIT-NULLS))
                            ": ")))))
    (message "Unable to load library `navi-mode.el'"))
  (setq imenu-generic-expression
        (or omm-imenu-default-generic-expression
            omm-imenu-preliminary-generic-expression)))


(defun omm-imenu (&optional PREFER-IMENU-P)
  "Convenience function for calling imenu/idomenu from omm."
  (interactive "P")
  (or omm-imenu-default-generic-expression
      (setq omm-imenu-default-generic-expression
            omm-imenu-preliminary-generic-expression))
  (let* ((imenu-generic-expression
          omm-imenu-default-generic-expression)
         (imenu-prev-index-position-function nil)
         (imenu-extract-index-name-function nil)
         (imenu-auto-rescan t)
         (imenu-auto-rescan-maxout 360000))
    ;; prefer idomenu
    (if (and (require 'idomenu nil 'NOERROR)
             (not PREFER-IMENU-P))
        (funcall 'idomenu)
      ;; else call imenu
      (funcall 'imenu
               (imenu-choose-buffer-index
                "Headline: ")))))


;;; Menus and Keybindings
;;;; Menus

;; ;;;;; Advertise Bindings

;; (put 'omm-insert-heading :advertised-binding [M-ret])
;; (put 'outline-cycle :advertised-binding [?\t])
;; (put 'omm-cycle-buffer :advertised-binding [backtab])
;; (put 'outline-promote :advertised-binding [M-S-left])
;; (put 'outline-demote :advertised-binding [M-S-right])
;; (put 'outline-move-subtree-up :advertised-binding [M-S-up])
;; (put 'outline-move-subtree-down :advertised-binding [M-S-down])
;; (put 'outline-hide-more :advertised-binding [M-left])
;; (put 'outline-show-more :advertised-binding [M-right])
;; (put 'outline-next-visible-header :advertised-binding [M-down])
;; (put 'outline-previous-visible-header :advertised-binding [M-up])
;; (put 'show-all :advertised-binding [?\M-# \?M-a])
;; (put 'outline-up-heading :advertised-binding [?\M-# ?\M-u])
;; (put 'outorg-edit-as-org :advertised-binding [?\M-# ?\M-#])

;; ;;;;; Define Menu

;; (easy-menu-define omm-menu outline-minor-mode-map "Omm menu"
;;   '("Omm"
;;      ["Cycle Subtree" outline-cycle
;;       :active (outline-on-heading-p) :keys "<tab>"]
;;      ["Cycle Buffer" omm-cycle-buffer t :keys "<backtab>"]
;;      ["Show More" outline-show-more
;;       :active (outline-on-heading-p) :keys "M-<right>"]
;;      ["Hide More" outline-hide-more
;;       :active (outline-on-heading-p) :keys "M-<left>"]
;;      ["Show All" show-all t :keys "M-# M-a>"]
;;      "--"
;;      ["Insert Heading" omm-insert-heading t :keys "M-<return>"]
;;      ["Promote Heading" outline-promote
;;       :active (outline-on-heading-p) :keys "M-S-<left>"]
;;      ["Demote Heading" outline-demote
;;       :active (outline-on-heading-p) :keys "M-S-<right>"]
;;      ["Move Heading Up" outline-move-heading-up
;;       :active (outline-on-heading-p) :keys "M-S-<up>"]
;;      ["Move Heading Down" outline-move-heading-down
;;       :active (outline-on-heading-p) :keys "M-S-<down>"]
;;     "--"
;;      ["Previous Visible Heading" outline-previous-visible-heading
;;       t :keys "M-<up>"]
;;      ["Next Visible Heading" outline-next-visible-heading
;;       t :keys "M-<down>"]
;;      ["Up Heading" outline-up-heading t]
;;     "--"
;;      ["Mark Subtree" outline-mark-subtree t]
;;      ["Edit As Org" outorg-edit-as-org t]))

;; ;; add "Omm" menu item

;; ;; (easy-menu-add omm-menu outline-minor-mode-map)
;; ;; get rid of "Outline" menu item
;; (define-key outline-minor-mode-map [menu-bar outline] 'undefined)


;;;; Keybindings

(let ((map org-minor-mode-map))
 (define-key map (kbd "C-c RET")
   (lambda () (interactive) (omm-cmd 'org-ctrl-c-ret)))
 (define-key map (kbd "M-p")
   (lambda () (interactive) (omm-cmd 'org-shiftup)))
 (define-key map (kbd "C-c :")
   (lambda () (interactive) (omm-cmd 'org-toggle-fixed-width)))
 (define-key map (kbd "C-o")
   (lambda () (interactive) (omm-cmd 'org-open-line)))
 (define-key map (kbd "C-c C-r")
   (lambda () (interactive) (omm-cmd 'org-reveal)))
 (define-key map (kbd "C-c C-c")
   (lambda () (interactive) (omm-cmd 'org-ctrl-c-ctrl-c)))
 (define-key map (kbd "C-c C-x TAB")
   (lambda () (interactive) (omm-cmd 'org-clock-in)))
 (define-key map (kbd "C-c C-x r")
   (lambda () (interactive) (omm-cmd 'org-metaright)))
 (define-key map (kbd "C-c C-x C-l")
   (lambda () (interactive) (omm-cmd 'org-preview-latex-fragment)))
 (define-key map (kbd "C-c C-x L")
   (lambda () (interactive) (omm-cmd 'org-shiftmetaleft)))
 (define-key map (kbd "C-c C-v C-z")
   (lambda () (interactive) (omm-cmd 'org-babel-switch-to-session)))
 (define-key map (kbd "DEL")
   (lambda () (interactive) (omm-cmd 'org-delete-backward-char)))
 (define-key map (kbd "C-a")
   (lambda () (interactive) (omm-cmd 'org-beginning-of-line)))
 (define-key map (kbd "C-c +")
   (lambda () (interactive) (omm-cmd 'org-table-sum)))
 (define-key map (kbd "<down-mouse-1>")
   (lambda () (interactive) (omm-cmd 'org-mouse-down-mouse)))
 (define-key map (kbd "C-c C-x C-c")
   (lambda () (interactive) (omm-cmd 'org-columns)))
 (define-key map (kbd "C-c C-x <")
   (lambda () (interactive) (omm-cmd 'org-agenda-set-restriction-lock)))
 (define-key map (kbd "C-c {")
   (lambda () (interactive) (omm-cmd 'org-table-toggle-formula-debugger)))
 (define-key map (kbd "C-c C-v C-M-h")
   (lambda () (interactive) (omm-cmd 'org-babel-mark-block)))
 (define-key map (kbd "C-c C-M-l")
   (lambda () (interactive) (omm-cmd 'org-insert-all-links)))
 (define-key map (kbd "C-c C-v j")
   (lambda () (interactive) (omm-cmd 'org-babel-insert-header-arg)))
 (define-key map (kbd "C-c C-*")
   (lambda () (interactive) (omm-cmd 'org-list-make-subtree)))
 (define-key map (kbd "C-c C-x RET g")
   (lambda () (interactive) (omm-cmd 'org-mobile-pull)))
 (define-key map (kbd "C-c C-v s")
   (lambda () (interactive) (omm-cmd 'org-babel-execute-subtree)))
 (define-key map (kbd "C-c C-x C-y")
   (lambda () (interactive) (omm-cmd 'org-paste-special)))
 (define-key map (kbd "C-c C-v c")
   (lambda () (interactive) (omm-cmd 'org-babel-check-src-block)))
 (define-key map (kbd "SPC..~")
   (lambda () (interactive) (omm-cmd 'org-self-insert-command)))
 (define-key map (kbd "C-c C-x q")
   (lambda () (interactive) (omm-cmd 'org-toggle-tags-groups)))
 (define-key map (kbd "C-c SPC")
   (lambda () (interactive) (omm-cmd 'org-table-blank-field)))
 (define-key map (kbd "C-c C-x A")
   (lambda () (interactive) (omm-cmd 'org-archive-to-archive-sibling)))
 (define-key map (kbd "C-c C-x C-b")
   (lambda () (interactive) (omm-cmd 'org-toggle-checkbox)))
 (define-key map (kbd "C-c C-x C-p") 'org-previous-link)
 (define-key map (kbd "C-c .")
   (lambda () (interactive) (omm-cmd 'org-time-stamp)))
 (define-key map (kbd "M-S--")
   (lambda () (interactive) (omm-cmd 'org-shiftcontrolleft)))
 (define-key map (kbd "C-c C->")
   (lambda () (interactive) (omm-cmd 'org-demote-subtree)))
 (define-key map (kbd "C-c C-l")
   (lambda () (interactive) (omm-cmd 'org-insert-link)))
 (define-key map (kbd "C-c C-a")
   (lambda () (interactive) (omm-cmd 'org-attach)))
 (define-key map (kbd "C-c C-x .")
   (lambda () (interactive) (omm-cmd 'org-timer)))
 (define-key map (kbd "C-c C-x c")
   (lambda () (interactive) (omm-cmd 'org-clone-subtree-with-time-shift)))
 (define-key map (kbd "C-c C-x C-j")
   (lambda () (interactive) (omm-cmd 'org-clock-goto)))
 (define-key map (kbd "C-c C-x RET p")
   (lambda () (interactive) (omm-cmd 'org-mobile-push)))
 (define-key map (kbd "C-c #")
   (lambda () (interactive) (omm-cmd 'org-update-statistics-cookies)))
 (define-key map (kbd "C-c C-x R")
   (lambda () (interactive) (omm-cmd 'org-shiftmetaright)))
 (define-key map (kbd "C-c C-x D")
   (lambda () (interactive) (omm-cmd 'org-shiftmetadown)))
 (define-key map (kbd "C-j")
   (lambda () (interactive) (omm-cmd 'org-return-indent)))
 (define-key map (kbd "C-c C-x C-v")
   (lambda () (interactive) (omm-cmd 'org-toggle-inline-images)))
 (define-key map (kbd "C-c C-x v")
   (lambda () (interactive) (omm-cmd 'org-copy-visible)))
 (define-key map (kbd "C-c C-v g")
   (lambda () (interactive) (omm-cmd 'org-babel-goto-named-src-block)))
 (define-key map (kbd "C-c C-x 0")
   (lambda () (interactive) (omm-cmd 'org-timer-start)))
 (define-key map (kbd "C-c C-v C-r") 'org-babel-goto-named-result)
 (define-key map (kbd "C-c C-x C-d")
   (lambda () (interactive) (omm-cmd 'org-clock-display)))
 (define-key map (kbd "M--")
   (lambda () (interactive) (omm-cmd 'org-shiftleft)))
 (define-key map (kbd "M-{")
   (lambda () (interactive) (omm-cmd 'org-backward-element)))
 (define-key map (kbd "C-c C-v f")
   (lambda () (interactive) (omm-cmd 'org-babel-tangle-file)))
 (define-key map (kbd "C-c C-x G")
   (lambda () (interactive) (omm-cmd 'org-feed-goto-inbox)))
 (define-key map (kbd "C-c $")
   (lambda () (interactive) (omm-cmd 'org-archive-subtree)))
 (define-key map (kbd "C-c C-x C-t")
   (lambda () (interactive) (omm-cmd 'org-toggle-time-stamp-overlays)))
 (define-key map (kbd "C-c C-x l")
   (lambda () (interactive) (omm-cmd 'org-metaleft)))
 (define-key map (kbd "C-c C-x C-z")
   (lambda () (interactive) (omm-cmd 'org-resolve-clocks)))
 (define-key map (kbd "<S-return>")
   (lambda () (interactive) (omm-cmd 'org-table-copy-down)))
 (define-key map (kbd "C-c C-z")
   (lambda () (interactive) (omm-cmd 'org-add-note)))
 (define-key map (kbd "C-e")
   (lambda () (interactive) (omm-cmd 'org-end-of-line)))
 (define-key map (kbd "C-c C-x u")
   (lambda () (interactive) (omm-cmd 'org-metaup)))
 (define-key map (kbd "C-c *")
   (lambda () (interactive) (omm-cmd 'org-ctrl-c-star)))
 (define-key map (kbd "C-c C-x p")
   (lambda () (interactive) (omm-cmd 'org-set-property)))
 (define-key map (kbd "C-c C-d")
   (lambda () (interactive) (omm-cmd 'org-deadline)))
 (define-key map (kbd "C-c C-x t")
   (lambda () (interactive) (omm-cmd 'org-inlinetask-insert-task)))
 (define-key map (kbd "C-c C-x M")
   (lambda () (interactive) (omm-cmd 'org-insert-todo-heading)))
 (define-key map (kbd "<C-S-down>")
   (lambda () (interactive) (omm-cmd 'org-shiftcontroldown)))
 (define-key map (kbd "C-c C-j")
   (lambda () (interactive) (omm-cmd 'org-goto)))
 (define-key map (kbd "C-c C-v d")
   (lambda () (interactive) (omm-cmd 'org-babel-demarcate-block)))
 (define-key map (kbd "C-c C-o")
   (lambda () (interactive) (omm-cmd 'org-open-at-point)))
 (define-key map (kbd "C-c C-v b") 'org-babel-execute-buffer)
 (define-key map (kbd "C-c C-v l")
   (lambda () (interactive) (omm-cmd 'org-babel-load-in-session)))
 (define-key map (kbd "C-c C-v v")
   (lambda () (interactive) (omm-cmd 'org-babel-expand-src-block)))
 (define-key map (kbd "<C-S-up>")
   (lambda () (interactive) (omm-cmd 'org-shiftcontrolup)))
 (define-key map (kbd "C-c C-v z")
   (lambda () (interactive) (omm-cmd 'org-babel-switch-to-session-with-code)))
 (define-key map (kbd "C-c C-v a")
   (lambda () (interactive) (omm-cmd 'org-babel-sha1-hash)))
 (define-key map (kbd "C-c C-x f")
   (lambda () (interactive) (omm-cmd 'org-footnote-action)))
 (define-key map (kbd "C-x n e")
   (lambda () (interactive) (omm-cmd 'org-narrow-to-element)))
 (define-key map (kbd "C-c C-x C-x")
   (lambda () (interactive) (omm-cmd 'org-clock-in-last)))
 (define-key map (kbd "C-x n s")
   (lambda () (interactive) (omm-cmd 'org-narrow-to-subtree)))
 (define-key map (kbd "C-c C-x M-w")
   (lambda () (interactive) (omm-cmd 'org-copy-special)))
 (define-key map (kbd "C-c C-x C-r")
   (lambda () (interactive) (omm-cmd 'org-clock-report)))
 (define-key map (kbd "C-x n b")
   (lambda () (interactive) (omm-cmd 'org-narrow-to-block)))
 (define-key map (kbd "C-c C-t")
   (lambda () (interactive) (omm-cmd 'org-todo)))
 (define-key map (kbd "C-c C-x d")
   (lambda () (interactive) (omm-cmd 'org-insert-drawer)))
 (define-key map (kbd "C-c C-x C-n")
   (lambda () (interactive) (omm-cmd 'org-next-link)))
 (define-key map (kbd "M-S-+")
   (lambda () (interactive) (omm-cmd 'org-shiftcontrolright)))
 (define-key map (kbd "C-c C-w")
   (lambda () (interactive) (omm-cmd 'org-refile)))
 (define-key map (kbd "M-n")
   (lambda () (interactive) (omm-cmd 'org-shiftdown)))
 (define-key map (kbd "C-c ;")
   (lambda () (interactive) (omm-cmd 'org-toggle-comment)))
 (define-key map (kbd "<C-down>")
   (lambda () (interactive) (omm-cmd 'org-forward-paragraph)))
 (define-key map (kbd "C-c M-w")
   (lambda () (interactive) (omm-cmd 'org-copy)))
 (define-key map (kbd "<M-down>")
   (lambda () (interactive) (omm-cmd 'org-metadown)))
 (define-key map (kbd "C-c C-x C-w")
   (lambda () (interactive) (omm-cmd 'org-cut-special)))
 (define-key map (kbd "C-k")
   (lambda () (interactive) (omm-cmd 'org-kill-line)))
 (define-key map (kbd "M-}")
   (lambda () (interactive) (omm-cmd 'org-forward-element)))
 (define-key map (kbd "RET")
   (lambda () (interactive) (omm-cmd 'org-return)))
 (define-key map (kbd "C-c C-v C-p")
   (lambda () (interactive) (omm-cmd 'org-babel-previous-src-block)))
 (define-key map (kbd "C-c C-x C-M-v")
   (lambda () (interactive) (omm-cmd 'org-redisplay-inline-images)))
 (define-key map (kbd "C-c &")
   (lambda () (interactive) (omm-cmd 'org-mark-ring-goto)))
 (define-key map (kbd "C-c |")
   (lambda () (interactive) (omm-cmd 'org-table-create-or-convert-from-region)))
 (define-key map (kbd "C-c C-x C-u")
   (lambda () (interactive) (omm-cmd 'org-dblock-update)))
 (define-key map (kbd "C-c C-x ,")
   (lambda () (interactive) (omm-cmd 'org-timer-pause-or-continue)))
 (define-key map (kbd "C-c C-x P")
   (lambda () (interactive) (omm-cmd 'org-set-property-and-value)))
 (define-key map (kbd "C-c C-x o")
   (lambda () (interactive) (omm-cmd 'org-toggle-ordered-property)))
 (define-key map (kbd "<C-S-return>")
   (lambda () (interactive) (omm-cmd 'org-insert-todo-heading-respect-content)))
 (define-key map (kbd "C-c C-v t")
   (lambda () (interactive) (omm-cmd 'org-babel-tangle)))
 (define-key map (kbd "C-c C-x C-a")
   (lambda () (interactive) (omm-cmd 'org-archive-subtree-default)))
 (define-key map (kbd "C-c ,")
   (lambda () (interactive) (omm-cmd 'org-priority)))
 (define-key map (kbd "C-c C-v C-o")
   (lambda () (interactive) (omm-cmd 'org-babel-open-src-block-result)))
 (define-key map (kbd "C-c C-_")
   (lambda () (interactive) (omm-cmd 'org-down-element)))
 (define-key map (kbd "C-c ?")
   (lambda () (interactive) (omm-cmd 'org-table-field-info)))
 (define-key map (kbd "C-c '")
   (lambda () (interactive) (omm-cmd 'org-edit-special)))
 (define-key map (kbd "C-c C-s")
   (lambda () (interactive) (omm-cmd 'org-schedule)))
 (define-key map (kbd "C-c C-x ;")
   (lambda () (interactive) (omm-cmd 'org-timer-set-timer)))
 (define-key map (kbd "C-c C-x :")
   (lambda () (interactive) (omm-cmd 'org-timer-cancel-timer)))
 (define-key map (kbd "TAB")
   (lambda () (interactive) (omm-cmd 'org-cycle)))
 (define-key map (kbd "C-c C-v I")
   (lambda () (interactive) (omm-cmd 'org-babel-view-src-block-info)))
 (define-key map (kbd "C-c C-x !")
   (lambda () (interactive) (omm-cmd 'org-reload)))
 (define-key map (kbd "C-c C-v C-e")
   (lambda () (interactive) (omm-cmd 'org-babel-execute-maybe)))
 (define-key map (kbd "M-RET")
   (lambda () (interactive) (omm-cmd 'org-insert-heading)))
 (define-key map (kbd "C-c /")
   (lambda () (interactive) (omm-cmd 'org-sparse-tree)))
 (define-key map (kbd "C-#")
   (lambda () (interactive) (omm-cmd 'org-table-rotate-recalc-marks)))
 (define-key map (kbd "C-c M-b")
   (lambda () (interactive) (omm-cmd 'org-previous-block)))
 (define-key map (kbd "C-c \\")
   (lambda () (interactive) (omm-cmd 'org-match-sparse-tree)))
 (define-key map (kbd "|")
   (lambda () (interactive) (omm-cmd 'org-force-self-insert)))
 (define-key map (kbd "C-c C-x b")
   (lambda () (interactive) (omm-cmd 'org-tree-to-indirect-buffer)))
 (define-key map (kbd "C-c =")
   (lambda () (interactive) (omm-cmd 'org-table-eval-formula)))
 (define-key map (kbd "C-c M-f")
   (lambda () (interactive) (omm-cmd 'org-next-block)))
 (define-key map (kbd "C-c C-x \\")
   (lambda () (interactive) (omm-cmd 'org-toggle-pretty-entities)))
 (define-key map (kbd "C-c C-x C-f")
   (lambda () (interactive) (omm-cmd 'org-emphasize)))
 (define-key map (kbd "C-c }")
   (lambda () (interactive) (omm-cmd 'org-table-toggle-coordinate-overlays)))
 (define-key map (kbd "C-c C-x g")
   (lambda () (interactive) (omm-cmd 'org-feed-update-all)))
 (define-key map (kbd "C-y")
   (lambda () (interactive) (omm-cmd 'org-yank)))
 (define-key map (kbd "C-c C-k")
   (lambda () (interactive) (omm-cmd 'org-kill-note-or-show-branches)))
 (define-key map (kbd "M-h")
   (lambda () (interactive) (omm-cmd 'org-mark-element)))
 (define-key map (kbd "<C-up>")
   (lambda () (interactive) (omm-cmd 'org-backward-paragraph)))
 (define-key map (kbd "C-c C-x C-s")
   (lambda () (interactive) (omm-cmd 'org-advertized-archive-subtree)))
 (define-key map (kbd "C-c C-x C-o")
   (lambda () (interactive) (omm-cmd 'org-clock-out)))
 (define-key map (kbd "C-c @")
   (lambda () (interactive) (omm-cmd 'org-mark-subtree)))
 (define-key map (kbd "M-t")
   (lambda () (interactive) (omm-cmd 'org-transpose-words)))
 (define-key map (kbd "C-c C-<")
   (lambda () (interactive) (omm-cmd 'org-promote-subtree)))
 (define-key map (kbd "M-+") 'org-shiftright)
 (define-key map (kbd "C-c C-x m")
   (lambda () (interactive) (omm-cmd 'org-meta-return)))
 (define-key map (kbd "C-c C-x -")
   (lambda () (interactive) (omm-cmd 'org-timer-item)))
 (define-key map (kbd "C-c C-x >")
   (lambda () (interactive) (omm-cmd 'org-agenda-remove-restriction-lock)))
 (define-key map (kbd "C-c !")
   (lambda () (interactive) (omm-cmd 'org-time-stamp-inactive)))
 (define-key map (kbd "C-c C-x e")
   (lambda () (interactive) (omm-cmd 'org-set-effort)))
 (define-key map (kbd "C-d")
   (lambda () (interactive) (omm-cmd 'org-delete-char)))
 (define-key map (kbd "<C-return>")
   (lambda () (interactive) (omm-cmd 'org-insert-heading-respect-content)))
 (define-key map (kbd "<drag-mouse-3>")
   (lambda () (interactive) (omm-cmd 'org-mouse-yank-link)))
 (define-key map (kbd "C-c r")
   (lambda () (interactive) (omm-cmd 'org-capture)))
 (define-key map (kbd "<mouse-3>") 'org-mouse-show-context-menu)
 (define-key map (kbd "C-c C-q")
   (lambda () (interactive) (omm-cmd 'org-set-tags-command)))
 (define-key map (kbd "C-c <")
   (lambda () (interactive) (omm-cmd 'org-date-from-calendar)))
 (define-key map (kbd "C-c >")
   (lambda () (interactive) (omm-cmd 'org-goto-calendar)))
 (define-key map (kbd "C-c C-y")
   (lambda () (interactive) (omm-cmd 'org-evaluate-time-range)))
 (define-key map (kbd "C-'")
   (lambda () (interactive) (omm-cmd 'org-cycle-agenda-files)))
 (define-key map (kbd "C-c C-e")
   (lambda () (interactive) (omm-cmd 'org-export-dispatch)))
 (define-key map (kbd "M-a")
   (lambda () (interactive) (omm-cmd 'org-backward-sentence)))
 (define-key map (kbd "C-c C-x U")
   (lambda () (interactive) (omm-cmd 'org-shiftmetaup)))
 (define-key map (kbd "C-M-t")
   (lambda () (interactive) (omm-cmd 'org-transpose-element)))
 (define-key map (kbd "C-c C-v C-u")
   (lambda () (interactive) (omm-cmd 'org-babel-goto-src-block-head)))
 (define-key map (kbd "C-c ^")
   (lambda () (interactive) (omm-cmd 'org-sort)))
 (define-key map (kbd "C-c C-x i")
   (lambda () (interactive) (omm-cmd 'org-insert-columns-dblock)))
 (define-key map (kbd "C-c C-f")
   (lambda () (interactive) (omm-cmd 'org-forward-heading-same-level)))
 (define-key map (kbd "C-c C-v x")
   (lambda () (interactive) (omm-cmd 'org-babel-do-key-sequence-in-edit-buffer)))
 (define-key map (kbd "C-c a")
   (lambda () (interactive) (omm-cmd 'org-agenda)))
 (define-key map (kbd "M-;")
   (lambda () (interactive) (omm-cmd 'org-comment-dwim)))
 (define-key map (kbd "C-c C-x E")
   (lambda () (interactive) (omm-cmd 'org-inc-effort)))
 (define-key map (kbd "<C-tab>")
   (lambda () (interactive) (omm-cmd 'org-force-cycle-archived)))
 (define-key map (kbd "C-c C-x C-q")
   (lambda () (interactive) (omm-cmd 'org-clock-cancel)))
 (define-key map (kbd "C-c C-x a")
   (lambda () (interactive) (omm-cmd 'org-toggle-archive-tag)))
 (define-key map (kbd "C-c ~")
   (lambda () (interactive) (omm-cmd 'org-table-create-with-table\.el)))
 (define-key map (kbd "C-c %")
   (lambda () (interactive) (omm-cmd 'org-mark-ring-push)))
 (define-key map (kbd "C-c M-l")
   (lambda () (interactive) (omm-cmd 'org-insert-last-stored-link)))
 (define-key map (kbd "<backtab>")
   (lambda () (interactive) (omm-cmd 'org-shifttab)))
 (define-key map (kbd "C-c C-v C-n")
   (lambda () (interactive) (omm-cmd 'org-babel-next-src-block)))
 (define-key map (kbd "M-e")
   (lambda () (interactive) (omm-cmd 'org-forward-sentence)))
 (define-key map (kbd "C-c C-b")
   (lambda () (interactive) (omm-cmd 'org-backward-heading-same-level)))
 (define-key map (kbd "C-c C-v h")
   (lambda () (interactive) (omm-cmd 'org-babel-describe-bindings)))
 (define-key map (kbd "C-c C-v i")
   (lambda () (interactive) (omm-cmd 'org-babel-lob-ingest)))
 (define-key map (kbd "C-c C-^")
   (lambda () (interactive) (omm-cmd 'org-up-element)))
 (define-key map (kbd "C-c C-x _")
   (lambda () (interactive) (omm-cmd 'org-timer-stop)))
 (define-key map (kbd "C-c -")
   (lambda () (interactive) (omm-cmd 'org-ctrl-c-minus)))
 (define-key map (kbd "C-c `")
   (lambda () (interactive) (omm-cmd 'org-table-edit-field)))
 (define-key map (kbd "C-c C-x [")
   (lambda () (interactive) (omm-cmd 'org-reftex-citation))))


;;; Run hooks and provide

(run-hooks 'org-minor-mode-hook)

(provide 'org-minor-mode)

;; Local Variables:
;; coding: utf-8
;; ispell-local-dictionary: "en_US"
;; generated-autoload-file: "org-loaddefs.el"
;; End:


;;; omm.el ends here
