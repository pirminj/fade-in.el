;;; fade-in-mode.el --- Fade in inserted text -*- lexical-binding: t; -*-

;; Copyright (C) 2025 pirminj

;; Author: pirminj
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, faces
;; URL: https://github.com/pirminj/fade-in.el

;;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; This package provides a minor mode that creates a fade-in effect
;; for newly inserted text.

;;; Code:

(provide 'fade-in-mode)
;;; fade-in-mode.el ends here

(require 'color)

(defgroup fade-in nil
  "Settings for fade-in effect on insertion."
  :group 'convenience)

(defcustom fade-in-steps 10
  "Number of steps for the fade-in animation."
  :type 'integer
  :group 'fade-in)

(defcustom fade-in-duration 0.2
  "Total duration of the fade-in animation in seconds."
  :type 'float
  :group 'fade-in)

(defcustom fade-in-excluded-modes '(minibuffer-mode eshell-mode)
  "List of major modes where fade-in should not be active."
  :type '(repeat symbol)
  :group 'fade-in)

(defun fade-in--blend-color (fg bg factor)
  "Calculate blended color for FACTOR.
FG and BG are foreground and background colors to blend. FACTOR
determines the blend ratio (0.0 = all BG, 1.0 = all FG)."
  (let ((fgc (color-name-to-rgb (or fg (face-foreground 'default))))
        (bgc (color-name-to-rgb (or bg (face-background 'default)))))
    (apply #'color-rgb-to-hex (append (color-blend fgc bgc factor) (list 2)))))

(defun fade-in--update-overlay (overlay fg bg step)
  "Update OVERLAY's color between BG and FG depending on STEP."
  (when (overlay-buffer overlay)
    (if (> step fade-in-steps)
        (delete-overlay overlay)
      (let* ((factor (/ (float step) (float fade-in-steps)))
             (color (fade-in--blend-color fg bg factor))
             (interval (/ fade-in-duration fade-in-steps)))
        (overlay-put overlay 'face `((:foreground ,color)))
        (run-at-time interval nil #'fade-in--update-overlay overlay fg bg (1+ step))))))

(defun fade-in--should-skip-p ()
  "Return non-nil if fade-in should be skipped in current context."
  (and (boundp 'major-mode)
       (memq major-mode fade-in-excluded-modes)))

(defun fade-in--after-change (beg end _)
  "Fade in text between BEG and END."
  (unless (or (fade-in--should-skip-p)
              (<= end beg))
    (let* ((face (or (get-text-property beg 'face) 'default))
           (bg (face-background face))
           (fg (face-foreground face))
           (overlay (make-overlay beg end)))
      (fade-in--update-overlay overlay fg bg 0))))

;;;###autoload
(define-minor-mode fade-in-mode
  "Fade in text upon insertion.
This creates a smooth transition effect where newly inserted text
gradually appears by fading in from background color to foreground."
  :lighter " FadeIn"
  :group 'fade-in
  (if fade-in-mode
      (add-hook 'after-change-functions #'fade-in--after-change nil t)
    (remove-hook 'after-change-functions #'fade-in--after-change t)))

(provide 'fade-in)
;;; fade-in-mode.el ends here
