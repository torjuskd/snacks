;; we can require features
(require 'cl)
(require 'package)

;; add mirrors for list-packages
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
			 ("melpa" . "http://melpa.milkbox.net/packages/")))

;; needed to use things downloaded with the package manager
(package-initialize)


;; install some packages if missing
(let* ((packages '(ac-geiser         ; Auto-complete backend for geiser
		   auto-complete
		   auto-complete     ; auto completion
		   geiser            ; GNU Emacs and Scheme talk to each other
		   ido-vertical-mode
		   monokai-theme
		   multiple-cursors
		   paredit           ; minor mode for editing parentheses
		   pdf-tools
		   pretty-lambdada
		   try
		   undo-tree)) ; `lambda' as the Greek letter.
       (packages (remove-if 'package-installed-p packages)))
  (when packages
    (package-refresh-contents)
    (mapc 'package-install packages)))


;; START Scheme-setup

;; We use racket.
(setq geiser-active-implementations '(racket))

;; Visualize matching parentheses.
(show-paren-mode 1)

;; Make sure these features are loaded.
(require 'auto-complete-config)
(require 'ac-geiser)

;; Standard auto-complete setup.
(ac-config-default)

;; ac-geiser recommended setup.
(add-hook 'geiser-mode-hook 'ac-geiser-setup)
(add-hook 'geiser-repl-mode-hook 'ac-geiser-setup)
(eval-after-load "auto-complete"
  '(add-to-list 'ac-modes 'geiser-repl-mode))

;; pretty-lambdada setup.
(add-to-list 'pretty-lambda-auto-modes 'geiser-repl-mode)
(pretty-lambda-for-modes)

;; Loop the pretty-lambda-auto-modes list.
(dolist (mode pretty-lambda-auto-modes)
  ;; add paredit-mode to all mode-hooks
  (add-hook (intern (concat (symbol-name mode) "-hook")) 'paredit-mode))

;; END Scheme-setup



;; enable system-copy
(setq x-select-enable-clipboard t)

;; no splash screen
(setq inhibit-splash-screen t)

;; La *scratch*-bufferen være tom.
(setq initial-scratch-message nil)

;; show matching parenthesis
(show-paren-mode 1)

;; show column number in mode-line
(column-number-mode 1)

;; overwrite marked text
(delete-selection-mode 1)

;; enable ido-mode, changes the way files are selected in the minibuffer
(ido-mode 1)

;; use ido everywhere
(ido-everywhere 1)

;; show vertically
(ido-vertical-mode 1)

;; use undo-tree-mode globally
(global-undo-tree-mode 1)

;; stop blinking cursor
(blink-cursor-mode 0)

;; no menubar
(menu-bar-mode 0)

;; no toolbar either
(tool-bar-mode 0)

;; scrollbar? no
(scroll-bar-mode 0)

;; global-linum-mode shows line numbers in all buffers, exchange 0
;; with 1 to enable this feature
(global-linum-mode 0)

;; answer with y/n
(fset 'yes-or-no-p 'y-or-n-p)

;; choose a color-theme
(load-theme 'monokai t)

;; get the default config for auto-complete (downloaded with
;; package-manager)
(require 'auto-complete-config)

;; load the default config of auto-complete
(ac-config-default)

;; kills the active buffer, not asking what buffer to kill.
(global-set-key (kbd "C-x k") 'kill-this-buffer)

;; adds all autosave-files (i.e #test.txt#, test.txt~) in one
;; directory, avoid clutter in filesystem.
(defvar emacs-autosave-directory (concat user-emacs-directory "autosaves/"))
(setq backup-directory-alist
      `((".*" . ,emacs-autosave-directory))
      auto-save-file-name-transforms
      `((".*" ,emacs-autosave-directory t)))

;; defining a function that sets more accessible keyboard-bindings to
;; hiding/showing code-blocs
(defun hideshow-on ()
  (local-set-key (kbd "C-c <right>") 'hs-show-block)
  (local-set-key (kbd "C-c <left>")  'hs-hide-block)
  (local-set-key (kbd "C-c <up>")    'hs-hide-all)
  (local-set-key (kbd "C-c <down>")  'hs-show-all)
  (hs-minor-mode t))

;; now we have to tell emacs where to load these functions. Showing
;; and hiding codeblocks could be useful for all c-like programming
;; (java is c-like) languages, so we add it to the c-mode-common-hook.
(add-hook 'c-mode-common-hook 'hideshow-on)

;; adding shortcuts to java-mode, writing the shortcut folowed by a
;; non-word character will cause an expansion.
(defun java-shortcuts ()
  (define-abbrev-table 'java-mode-abbrev-table
    '(("psv" "public static void main(String[] args) {" nil 0)
      ("sop" "System.out.printf" nil 0)
      ("sopl" "System.out.println" nil 0)))
  (abbrev-mode t))

;; the shortcuts are only useful in java-mode so we'll load them to
;; java-mode-hook.
(add-hook 'java-mode-hook 'java-shortcuts)

;; defining a function that guesses a compile command and bindes the
;; compile-function to C-c C-c
(defun java-setup ()
  (set (make-variable-buffer-local 'compile-command)
       (concat "javac " (buffer-name)))
  (local-set-key (kbd "C-c C-c") 'compile))

;; this is a java-spesific function, so we only load it when entering
;; java-mode
(add-hook 'java-mode-hook 'java-setup)

;; defining a function that sets the right indentation to the marked
;; text, or the entire buffer if no text is selected.
(defun tidy ()
  "Ident, untabify and unwhitespacify current buffer, or region if active."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
	(end (if (region-active-p) (region-end)       (point-max))))
    (whitespace-cleanup)
    (indent-region beg end nil)
    (untabify beg end)))

(defun duplicate-thing (comment)
  "Duplicates the current line, or the region if active. If an argument is
given, the duplicated region will be commented out."
  (interactive "P")
  (save-excursion
    (let ((start (if (region-active-p) (region-beginning) (point-at-bol)))
	  (end   (if (region-active-p) (region-end) (point-at-eol))))
      (goto-char end)
      (unless (region-active-p)
	(newline))
      (insert (buffer-substring start end))
      (when comment (comment-region start end)))))

(global-set-key (kbd "C-c d") 'duplicate-thing)

;; bindes the tidy-function to C-TAB
(global-set-key (kbd "<C-tab>") 'tidy)

;;Rename the file while in buffer
(defun rename-this-buffer-and-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
	(filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
	(error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
	(cond ((get-buffer new-name)
	       (error "A buffer named '%s' already exists!" new-name))
	      (t
	       (rename-file filename new-name 1)
	       (rename-buffer new-name)
	       (set-visited-file-name new-name)
	       (set-buffer-modified-p nil)
	       (message "File '%s' successfully renamed to '%s'" name (file-name-nondirectory new-name))))))))

(add-to-list 'auto-mode-alist '("\\.pdf\\'" . pdf-tools-install))
(pdf-tools-install)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (pdf-tools exec-path-from-shell undo-tree try pretty-lambdada paredit multiple-cursors monokai-theme ido-vertical-mode ac-geiser))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;;Some back up stuff
;; This will all place all auto-saves and backups in the directory pointed to by temporary-file-directory (e.g., C:/Temp/ on Windows).
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; If you visit the backup directory from time to time to retrieve an old file version then it’s a good idea to prevent the directory from cluttering up with very old backup files.
;; Automatically purge backup files not accessed in a week:
(message "Deleting old backup files...")
(let ((week (* 60 60 24 7))
      (current (float-time (current-time))))
  (dolist (file (directory-files temporary-file-directory t))
    (when (and (backup-file-name-p file)
               (> (- current (float-time (fifth (file-attributes file))))
                  week))
      (message "%s" file)
      (delete-file file))))