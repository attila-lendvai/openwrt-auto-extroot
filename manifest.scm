;; This is the complete list of Guix packages necessary for building.
;;
;; The following shell command will run the tests:
;;
;; guix shell -m manifest.scm --pure -- ./build.sh ath79 generic tplink_tl-wdr4300-v1
;;
;; TODO ...ideally. some dependencies are not listed, and it fails when using --pure

;;
;; Quircks on Guix: the check for git fails, must edit
;; build/openwrt-imagebuilder-19.07.9-ath79-generic.Linux-x86_64/include/prereq-build.mk
;; and comment out the git check.
;;

(specifications->manifest
 '("coreutils"
   "bash"
   "make"
   "perl"
   "python2"
   "gcc-toolchain"
   "git"
   "git:gui"
   ;; "man-pages"
   "less"
   "time"))
