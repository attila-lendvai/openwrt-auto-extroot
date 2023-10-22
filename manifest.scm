;; This is the complete list of Guix packages necessary for building.
;;
;; The following shell command will run the tests:
;;
;; guix shell -m manifest.scm --pure -- ./build.sh ath79 generic tplink_tl-wdr4300-v1
;;
;; TODO ...ideally. some dependencies are not listed, and it fails when using --pure

(specifications->manifest
 '("coreutils"
   "bash"
   "make"
   "perl"
   "gcc-toolchain"
   "git"
   "git:gui"
   ;; "man-pages"
   "less"
   "time"))
