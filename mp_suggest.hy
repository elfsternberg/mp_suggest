#!/usr/local/bin/hy

(def *version* "0.0.1")

(require hy.contrib.anaphoric)
(import eyeD3 os re sys getopt string
        [collections [defaultdict]]
        [django.utils.encoding [smart_str]])

; 0: Short opt, 1: long opt, 2: takes argument, 3: help text

(def optlist [["g" "genre" true "Set the genre"] 
              ["a" "album" true "Set the album"] 
              ["r" "artist" true "Set the artist"] 
              ["n" "usedir" false "Use the directory as the album name, even if it's set in ID3"] 
              ["t" "usefilename" false "Use the filename as the title, even if it's set in ID3"]
              ["h" "help" false "This help message"]
              ["v" "version" false "Version information"]])

(defn print-version []
  (print (.format "mp_suggest (hy version {})" *version*))
  (print "Copyright (c) 2008, 2014 Elf M. Sternberg <elf.sternberg@gmail.com>")
  (sys.exit))

(defn print-help []
  (print "Usage:")
  (ap-each optlist (print (.format "	-{}	--{}	{}" (get it 0) (get it 1) (get it 3))))
  (sys.exit))

; Given a set of command-line arguments, compare that to a mapped
; version of the optlist and return a canonicalized dictionary of all
; the arguments that have been set.

(defn make-opt-assoc [prefix pos]
  (fn [acc it] (assoc acc (+ prefix (get it pos)) (get it 1)) acc)) 

(defn make-options-rationalizer [optlist]
  (let [
        [short-opt-assoc (make-opt-assoc "-" 0)]
        [long-opt-assoc (make-opt-assoc "--" 1)]
        [fullset 
         (ap-reduce (-> (short-opt-assoc acc it)
                        (long-opt-assoc it)) optlist {})]]
    (fn [acc it] (do (assoc acc (get fullset (get it 0)) (get it 1)) acc))))

; Auto-capitalize "found" entries like album name and title. Will not
; affect manually set entries.

(defn sfix [s]
  (let [[seq (.split (.strip s))]]
    (smart_str (string.join (ap-map (.capitalize it) seq) " "))))

; Assuming the directory name looked like "Artist - Album", return the
; two names separately.  If only one name is here, assume a compilation
; or mixtape album and default to "VA" (Various Artists).

(defn artist-album []
  (let [[aa (-> (.getcwd os) (.split "/") (get -1) (.split " - "))]]
    (if (= (len aa) 1) 
      (, "VA" (get aa 0)) 
      (, (.strip (get aa 0)) (.strip (get aa 1))))))

; A long list of substitutions intended to turn a filename into a
; human-readable strategy.  This operation is the result of weeks
; of experimentation.  Doubt it at your peril!  :-)

(defn title-strategy [orig] 
  (->> (.strip orig) 
       (.sub re "\.[Mm][Pp]3$" "")
       (.sub re "_" " ")
       (.strip)
       (.sub re "^.* - " "")
       (.sub re "^[\d\. ]+" "")
       (.sub re ".* \d{2} " "")
       (.sub re "^\W+" "")
       (sfix)))

; Given a list of mp3s, derive the list of ID3 tags.  Obviously,
; filesystem access is a point of failure, but this is mostly
; reliable.

(defn tag-deriver [usefilenames forceartist setartist]
  (defn choose-title [filename title]
    (if usefilenames (title-strategy filename) title))
  (defn choose-artist [artist]
    (if forceartist setartist artist))
  (fn [mp3s]
    (defn derive-tag [pos mp3]
      (try
       (let [[tag (.Tag eyeD3)]]
         (tag.link mp3)
         (, mp3 (str (.getArtist tag)) (str (.getAlbum tag)) 
                (str (.getGenre tag)) (choose-title mp3 (str (.getTitle tag))) pos))
       (catch [err Exception]
         (, mp3 "" "" "" "" 1))))
    (ap-map (apply derive-tag it)  mp3s)))

; For removing subgenre parentheses.  This is why there's the -g option.

(defn clean-paren [s] 
  (if (not (= (.find s "(") -1))
    (.sub re "\(.*?\)" "" s)
    s))

; My FAT-32 based file store via Samba isn't happy with unicode, so
; this is here...

(defn is-ascii [s] 
  (= (.decode (.encode s "ascii" "ignore") "ascii") s))

(defn ascii-or-nothing [s]
  (if (is-ascii s) s ""))

; For all the songs, analyze a consist entry (usually genre and album
; names), and return the one with the most votes.

(defn find-likely [l]
  (let [[cts 
         (->>
          (map (fn [i] (, (get i 1) (get i 0)))
               (.items 
                (ap-reduce
                 (do (assoc acc it (+ 1 (get acc it))) acc) l (defaultdict int))))
          (sorted)
          (reversed)
          (list))]]
    (if (zero? (len cts)) 
      ""
      (get (get cts 0) 1))))

(defn suggest [opts]
  (let [[(, loc_artist loc_album) (artist-album)]

        [artist 
         (cond [(.has_key opts "artist") (get opts "artist")]
               [true (sfix loc_artist)])]

        [mp3s 
         (->> (os.listdir ".") 
              (ap-filter (and (> (len it) 4) (= (slice (.lower it) -4) ".mp3")))
              (sorted)
              (enumerate)
              ((tag-deriver (.has_key opts "usefilename") (.has_key opts "artist") artist))
              (list))]

        [genre 
         (if (.has_key opts "genre") 
           (get opts "genre") 
           (clean-paren (find-likely (map (fn [m] (get m 3)) mp3s))))]

        [pos_album 
         (ascii-or-nothing 
          (find-likely 
           (map (fn [m] (get m 2)) mp3s)))]

        [album 
         (cond 
          [(.has_key opts "album") (get opts "album")]
          [(not (= "" pos_album)) pos_album]
          [true (sfix loc_album)])]
        
        [format-string 
         (string.join ["id3v2 -T \"{}\""	
                       "--album \"{}\""	
                       "--artist \"{}\""
                       "--genre \"{}\""
                       "--song \"{}\""
                       "\"{}\""] "	")]]
    
    (ap-each mp3s 
             (print (.format format-string 
                             (get it 5) 
                             album 
                             (if (get it 1) (get it 1) (sfix loc_artist)) 
                             genre 
                             (get it 4) 
                             (get it 0))))))

(defmain [&rest args]
  (try
   (let [[optstringsshort 
          (string.join (ap-map (+ (. it [0]) (cond [(. it [2]) ":"] [true ""])) optlist) "")]

         [optstringslong 
          (list (ap-map (+ (. it [1]) (cond [(. it [2]) "="] [true ""])) optlist))]

         [(, opt arg) 
          (getopt.getopt (slice args 1) optstringsshort optstringslong)]

         [rationalize-options 
          (make-options-rationalizer optlist)]

         [options 
          (ap-reduce (rationalize-options acc it) opt {})]]

     (cond [(.has_key options "help") (print-help)]
           [(.has_key options "version") (print-version)]
           [true (suggest options)]))))




  


