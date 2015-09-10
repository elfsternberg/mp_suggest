#!/usr/local/bin/hy

(def *version* "0.0.2")

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
; the arguments that have been set.  For example "-g" and "--genre"
; will both be mapped to "genre".

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

; For removing subgenre parentheses.  This is why there's the -g
; option.  Parenthetical sub-genre "commentary" are a pre ID3v2
; abomination.

(defn clean-paren [s] 
  (if (not (= (.find s "(") -1))
    (.sub re "\(.*?\)" "" s)
    s))

; My FAT-32 based file store via Samba isn't happy with unicode, so
; this is here.  I had the weirdest time with non-unicode album names,
; especially when trying to load them onto my old iPod classic.

(defn is-ascii [s] 
  (= (.decode (.encode s "ascii" "ignore") "ascii") s))

(defn ascii-or-nothing [s]
  (if (is-ascii s) s ""))

; Assuming the directory name looked like "Artist - Album", return the
; two names separately.  If only one name is here, assume a compilation
; or mixtape album and default to "VA" (Various Artists).

(defn artist-album []
  (let [[aa (-> (.getcwd os) (.split "/") (get -1) (.split " - "))]]
    (if (= (len aa) 1) 
      (, "VA" (sfix (get aa 0)))
      (, (sfix (.strip (get aa 0))) (sfix (.strip (get aa 1)))))))

; Priorities:
;
;     Artist:
;         (1) Command Line
;         (2) Command Line Force-Use-Dir
;         (3) In Existing Tag
;         (4) Found Dir
;
;     Album: 
;         (1) Command line 
;         (2) Command Line Force-Use-Dir
;         (3) Found-Likely 
;         (4) Found Dir
;
;     Genre:
;         (1) Command Line
;         (2) Found-Likely
;
;     Title:
;         (1) Command Line Force-Use-Filename
;         (2) In Existing Tag
;         (3) Derived From Filename
;
; The "found-likely" algorithm is straightforward: for a given
; directory, find the album name or genre most commonly expressed in
; the ID3 tags, and assign that to all the ID3 tags in the directory.
; This will really mess you up if you accidentally have two albums in
; the same directory; use with caution.

(defn make-artist-deriver [opts found likely]
  (cond [(.has_key opts "artist") (fn [tag file] (get opts "artist"))]
        [(.has_key opts "usedir") (fn [tag file] found)]
        [true (fn [tag file] (or tag (sfix found) (sfix likely)))]))

(defn make-album-deriver [opts found likely]
  (cond [(.has_key opts "album") (fn [tag file] (get opts "album"))]
        [(.has_key opts "usedir") (fn [tag file] found)]
        [true (fn [tag file] (or (ascii-or-nothing likely) (sfix found)))]))

(defn make-genre-deriver [opts found likely]
  (cond [(.has_key opts "genre") (fn [tag file] (get opts "genre"))]
        [true (fn [tag file] likely)]))

(defn make-title-deriver [opts found likely]
  (cond [(.has_key opts "usefilename") (fn [tag file] (title-strategy file))]
        [true (fn [tag file] (or tag (title-strategy file)))]))

; Given a list of mp3s, derive the list of ID3 tags.  Obviously,
; filesystem access is a point of failure, but this is mostly
; reliable.

(defn fetch-tags [filenames]
  (defn fetch-tag [pos filename]
    (try
     (let [[tag (.Tag eyeD3)]]
       (tag.link filename)
       (, pos (str (.getArtist tag)) (str (.getAlbum tag))
              (str (.getGenre tag)) (str (.getTitle tag)) filename))
     (catch [err Exception]
       (, filename "" "" "" "" 1))))
  (ap-map (apply fetch-tag it) filenames))

(defn derive-tags [mp3s artist-deriver album-deriver genre-deriver title-deriver]
  (defn derive-tag [mp3]
    (let [[file (get mp3 5)]]
      (, (get mp3 0) (artist-deriver (get mp3 1) file) (album-deriver (get mp3 2) file)
         (genre-deriver (get mp3 3) file) (title-deriver (get mp3 4) file) (get mp3 5))))
  (ap-map (derive-tag it) mp3s))

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

(defn tap [a] (print a) a)

(defn suggest [opts]
  (let [[(, local-artist local-album) (artist-album)]

        [mp3s 
         (->> (os.listdir ".") 
              (ap-filter (and (> (len it) 4) (= (slice (.lower it) -4) ".mp3")))
              (sorted)
              (enumerate)
              (fetch-tags)
              (list)
              )]

        [likely-genre (sfix (clean-paren (find-likely (map (fn [m] (get m 3)) mp3s))))]
        [likely-album (find-likely (map (fn [m] (get m 2)) mp3s))]
        [likely-artist (find-likely (map (fn [m] (get m 1)) mp3s))]

        [artist-deriver (make-artist-deriver opts local-artist likely-artist)]
        [album-deriver (make-album-deriver opts local-album likely-album)]
        [genre-deriver (make-genre-deriver opts "" likely-genre)]
        [title-deriver (make-title-deriver opts "" "")]
    
        [newmp3s (derive-tags mp3s artist-deriver album-deriver genre-deriver title-deriver)]
        
        [format-string 
         (string.join ["id3v2 -T \"{}\""	
                       "--artist \"{}\""
                       "--album \"{}\""	
                       "--genre \"{}\""
                       "--song \"{}\""
                       "\"{}\""] "	")]

        [finalizer (fn (seq) (+ [format-string] (list (map (fn [i] (get seq i)) (xrange 0 6)))))]]

    (ap-each newmp3s 
             (print (apply .format (finalizer it))))))

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
           [true (suggest options)]))
   (catch [err getopt.GetoptError]
     (print (str err))
     (print-help))))
