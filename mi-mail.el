;;; mi-mail.el --- mail stuff

;;; Commentary:
;; mail related stuff here.

(require 'smtpmail)

;; compose & send mail with gnus-user-agent
; even when we are not within gnus

;;; Code:

(setq mail-user-agent 'gnus-user-agent)

;; common smtp configuration
(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-debug-info t
      smtpmail-debug-verb t)

;; pop3 configuration
(setq mail-sources '((file :path "/var/mail/dhg")))
	  

(defun mi-message-smtpmail-tls (server port user passwd key cert auth-file)
  "Send mail using tls method.
Argument SERVER server name or ip address.
Argument PORT server port number.
Argument USER user name.
Argument PASSWD password.
Argument KEY key.
Argument CERT certificate.
Argument AUTH-FILE authentication file."
  (setq smtpmail-smtp-server "smtp.xbsd.name"
	smtpmail-default-smtp-server "smtp.xbsd.name"
	smtpmail-smtp-service 25
	starttls-gnutls-program "gnutls_cli"
	starttls-extra-arguments nil
	smtpmail-auth-credentials auth-file
	smtpmail-starttls-credentials (list (list server port user passwd key cert)))
  (message
   "Setting SMTP server to `%s:%s' for user `%s'."
   server port user))

;; we have opensmtpd to deal different
;; smtp severs.
(defun mi-message-smtp-send ()
  "Send mail directly to smtp service provided by OpenSMTPD."
  (save-excursion
    (mi-message-smtpmail-tls
     "smtp.xbsd.name"
     25
     "dhg"
     nil
     nil
     nil
     "~/.authinfo")))

;; mail envelopes
;;
;; initialize my own vars
(defvar mi-header-to nil)
(defvar mi-header-subject nil)
(defvar mi-header-cc nil)
(defvar mi-header-bcc nil)
(defvar mi-header-envelope nil)

(defun mi-message-header-setup-hook ()
  "Set up mail headers before posting."
  (interactive)
  (setq
   subject-content (gnus-fetch-field "Subject")
   cc-content (gnus-fetch-field "Cc")
   gcc-content (gnus-fetch-field "Gcc")
   newsgroup-content (gnus-fetch-field "Newsgroups")
   envelope-content (or (gnus-fetch-field "To")
			newsgroup-content))
  
  (if (null envelope-content)
      (progn
	(setq envelope-content
	      (read-from-minibuffer "Send a mail to: "))
	(if (not (null envelope-content))
	    (setq mi-header-to envelope-content)
	  (setq mi-header-to nil))))
  
  (if (null subject-content)
      (progn
	(setq subject-content
	      (read-from-minibuffer "Subject: "))
	(if (not (null subject-content))
	    (setq mi-header-subject
		  (concat "\"" subject-content "\""))
	  (setq mi-header-subject nil))))
  
  (if (not (or cc-content newsgroup-content))
      (progn
	(setq cc-content
	      (read-from-minibuffer "Cc: "))
	(if (equal 0 (string-width cc-content))
	    (setq mi-header-cc nil)
	  (progn
	    (setq mi-header-cc (concat cc-content "\n"))))))
  
  (if (string-equal "nnml:mail.sent.mail" gcc-content)
      (setq mi-header-bcc
	    (concat "Bcc: " mi-message-user-mail-address "\n"))
    (setq mi-header-bcc nil))

  (setq
   mi-header-envelope
   (concat "X-Envelope-To: "
	   (replace-regexp-in-string
	    "\(.*\)" ""
	    (replace-regexp-in-string
	     ">.*" ""
	     (replace-regexp-in-string ".*<" "" envelope-content)))
	   "\n"))
  
  (insert mi-header-envelope)

  (if (not (null mi-header-bcc))
      (insert mi-header-bcc))
  
  (if (not (null mi-header-to))
      (progn
	(goto-char (point-min))
	(while (search-forward-regexp "^To: $" (point-max) t)
	  (replace-match (concat "To: " mi-header-to)))))
  
  (if (not (null mi-header-subject))
      (progn
	(goto-char (point-min))
	(while (search-forward-regexp "^Subject: $" (point-max) t)
	  (replace-match (concat "Subject: " mi-header-subject)))))
  
  (if (not (null mi-header-cc))
      (progn
	(if (or (null (gnus-fetch-field "Cc"))
		(eq "" (gnus-fetch-field "Cc"))
	    (progn
	      (insert (concat "\nCc: " mi-header-cc))
	      (goto-char (point-min))
	      (delete-blank-lines)))))

  (setq
   mi-header-envelope nil
   mi-header-to nil
   mi-header-subject nil
   mi-header-cc nil
   mi-header-bcc nil)))

;; hooks
(add-hook 'message-header-setup-hook
	  'mi-message-header-setup-hook)
(add-hook 'message-send-hook 'mi-message-smtp-send)

(provide 'mi-mail)

;;; mi-mail.el ends here
