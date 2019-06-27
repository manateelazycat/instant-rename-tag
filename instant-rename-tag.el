;;; instant-rename-tag.el --- Instant rename tag

;; Filename: instant-rename-tag.el
;; Description: Instant rename tag
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; Maintainer: Andy Stewart <lazycat.manatee@gmail.com>
;; Copyright (C) 2019, Andy Stewart, all rights reserved.
;; Created: 2019-03-14 22:14:00
;; Version: 0.2
;; Last-Updated: 2019-06-27 07:38:27
;;           By: Andy Stewart
;; URL: http://www.emacswiki.org/emacs/download/instant-rename-tag.el
;; Keywords:
;; Compatibility: GNU Emacs 26.1.92
;;
;; Features that might be required by this library:
;;
;; `web-mode' `sgml-mode'

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; It's wonderful if we can rename tag instantly, not rename from minibuffer.
;; And yes, this plugin is design for do this.
;;

;;; Installation:
;;
;; Put instant-rename-tag.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'instant-rename-tag)
;;
;; No need more.

;;; Customize:
;;
;;
;;
;; All of the above can customize by:
;;      M-x customize-group RET instant-rename-tag RET
;;

;;; Change log:
;;
;; 2019/06/27
;;      * Refactory code.
;;
;; 2019/06/26
;;      * Use overlay re-implement code.
;;
;; 2019/03/14
;;      * First released.
;;

;;; Acknowledgements:
;;
;;
;;

;;; TODO
;;
;; * Try to remove web-mode depend.
;; * Fix mark wrong place that not include close tag.
;; * Cancel mark after tag area not change, don't need cancel manually.
;;

;;; Require
(require 'web-mode)
(require 'sgml-mode)

;;; Code:

(defgroup instant-rename-tag nil
  "Instant rename tag."
  :group 'instant-rename-tag)

(defface instant-rename-tag-mark-face
  '((t (:foreground "White" :background "#007aff" :bold t)))
  "Face tag."
  :group 'instant-rename-tag)

(defun instant-rename-tag ()
  (interactive)
  (cond ((instant-rename-tag-in-open-tag-p)
         (if (instant-rename-tag-is-marking)
             (instant-rename-tag-unmark)
           (instant-rename-tag-mark)))
        ((instant-rename-tag-in-close-tag-p)
         (if (instant-rename-tag-is-marking)
             (instant-rename-tag-unmark)
           (instant-rename-tag-mark)))
        (t
         (message "Not in tag area."))))

(defun instant-rename-tag-is-marking ()
  (and (boundp 'instant-rename-tag-is-mark)
       instant-rename-tag-is-mark))

(defun instant-rename-tag-mark ()
  (ignore-errors
    (let* ((open-tag-pos (save-excursion
                           (web-mode-element-beginning)
                           (point)))
           (start-pos (save-excursion
                        (goto-char open-tag-pos)
                        (forward-char 1)
                        (point)))
           (end-pos (save-excursion
                      (goto-char start-pos)
                      (unless (looking-at ">")
                        (forward-symbol 1))
                      (point))))
      (when (and start-pos end-pos)
        (set (make-local-variable 'instant-rename-tag-open-overlay) (make-overlay start-pos end-pos))
        (overlay-put instant-rename-tag-open-overlay 'face 'instant-rename-tag-mark-face)
        )))

  (ignore-errors
    (let* ((close-tag-pos (save-excursion
                            (instant-rename-tag-jump-to-match)
                            (point)))
           (start-pos (save-excursion
                        (goto-char close-tag-pos)
                        (forward-char 2)
                        (point)))
           (end-pos (save-excursion
                      (goto-char start-pos)
                      (unless (looking-at ">")
                        (forward-symbol 1))
                      (point))))
      (when (and start-pos end-pos)
        (set (make-local-variable 'instant-rename-tag-close-overlay) (make-overlay start-pos end-pos))
        (overlay-put instant-rename-tag-close-overlay 'face 'instant-rename-tag-mark-face)
        )))

  (set (make-local-variable 'instant-rename-tag-is-mark) t)
  )

(defun instant-rename-tag-unmark ()
  (when instant-rename-tag-open-overlay
    (delete-overlay instant-rename-tag-open-overlay)
    (set (make-local-variable 'instant-rename-tag-open-overlay) nil))

  (when instant-rename-tag-close-overlay
    (delete-overlay instant-rename-tag-close-overlay)
    (set (make-local-variable 'instant-rename-tag-close-overlay) nil))

  (set (make-local-variable 'instant-rename-tag-is-mark) nil))

(defun instant-rename-tag-in-open-tag-p ()
  (let ((open-tag-pos (save-excursion
                        (sgml-skip-tag-backward 1)
                        (point))))
    (and (equal (line-number-at-pos open-tag-pos) (line-number-at-pos (point)))
         (save-excursion
           (search-backward-regexp "<" open-tag-pos t))
         (not (save-excursion
                (search-backward-regexp "\\s-" open-tag-pos t))))))

(defun instant-rename-tag-in-close-tag-p ()
  (let ((close-tag-pos (save-excursion
                         (instant-rename-tag-jump-to-match)
                         (point))))
    (and (equal (line-number-at-pos close-tag-pos) (line-number-at-pos (point)))
         (save-excursion
           (search-backward-regexp "</" close-tag-pos t))
         (not (save-excursion
                (search-backward-regexp "\\s-" close-tag-pos t))))))

(defun instant-rename-tag-jump-to-match ()
  (web-mode-element-beginning)
  (cond ((looking-at "<>")
         (web-mode-tag-match))
        (t
         (sgml-skip-tag-forward 1)))
  (search-backward-regexp "</"))

(defun instant-rename-tag-after-change-function (begin end length)
  (when (and
         (derived-mode-p 'web-mode)
         (instant-rename-tag-is-marking)
         instant-rename-tag-open-overlay
         instant-rename-tag-close-overlay)
    (let* ((disable-company-mode (when (featurep 'company-mode)
                                   (company-mode -1)))
           (open-tag-start-pos (overlay-start instant-rename-tag-open-overlay))
           (open-tag-end-pos (overlay-end instant-rename-tag-open-overlay))
           (close-tag-start-pos (overlay-start instant-rename-tag-close-overlay))
           (close-tag-end-pos (overlay-end instant-rename-tag-close-overlay)))
      (cond ((and (>= (point) open-tag-start-pos)
                  (<= (point) (+ 1 open-tag-end-pos)))
             (let ((new-tag (buffer-substring open-tag-start-pos (max open-tag-end-pos (point)))))
               (save-excursion
                 (delete-region close-tag-start-pos close-tag-end-pos)
                 (goto-char close-tag-start-pos)
                 (insert new-tag)
                 (move-overlay instant-rename-tag-open-overlay open-tag-start-pos (+ open-tag-start-pos (length new-tag)))
                 (move-overlay instant-rename-tag-close-overlay (- (point) (length new-tag)) (point))
                 )))
            ((and (>= (point) close-tag-start-pos)
                  (<= (point) (+ 1 close-tag-end-pos)))
             (let* ((open-tag (buffer-substring open-tag-start-pos open-tag-end-pos))
                    (current-point (max close-tag-end-pos (point)))
                    (new-tag (buffer-substring close-tag-start-pos current-point))
                    (tag-offset (- (length new-tag) (length open-tag)))
                    (close-tag-new-start-pos (+ close-tag-start-pos tag-offset)))
               (save-excursion
                 (delete-region open-tag-start-pos open-tag-end-pos)
                 (goto-char open-tag-start-pos)
                 (insert new-tag)
                 (move-overlay instant-rename-tag-close-overlay close-tag-new-start-pos (+ close-tag-new-start-pos (length new-tag)))
                 (move-overlay instant-rename-tag-open-overlay (- (point) (length new-tag)) (point))))
             )))))

(add-hook 'after-change-functions #'instant-rename-tag-after-change-function)

(provide 'instant-rename-tag)

;;; instant-rename-tag.el ends here
