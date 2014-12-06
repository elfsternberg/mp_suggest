#!/usr/local/bin/hy

(def *version* "0.0.1")

(require hy.contrib.anaphoric)
(import eyeD3 os re sys getopt string
        [collections [defaultdict]]
        [django.utils.encoding [smart_str]])

(def optlist [["g" "genre" true "Set the genre"] 
              ["a" "album" true "Set the album"] 
              ["r" "artist" true "Set the artist"] 
              ["n" "usedir" false "Use the directory as the album name, even if it's set in ID3"] 
              ["t" "usefilename" false "Use the filename as the title, even if it's set in ID3"]
              ["h" "help" false "This help message"]
              ["v" "version" false "Version information"]])

(defn print-version []
  (print (.format "mp_suggest (hy version {})" *version*))
  (sys.exit 0))

(defn find-opt-reducer [acc it]
  (let [[(, o a) it]
        [optmap (ap-reduce (do (assoc acc (+ "-" (. it [0])) (. it [1])) acc) optlist {})]]
    (if (.has_key optmap o) (let [[full (car (get optmap o))]
                            [hasargs (car (cdr (get optmap o)))]]
                        (assoc acc full (if hasargs a true))))
    acc))

(defn artist-album []
  (let [[aa (.split (. (.split (.getcwd os) "/") [-1]) " - ")]
        [sp (fn [i] (.strip i))]]
    (if (= (len aa) 1) 
      (, "VA" (get aa 0)) 
      (, (sp (get aa 0)) (sp (get aa 1))))))

(defn title-strategy [orig] 
  (->> (.strip orig) 
       (.sub re "\.[Mm][Pp]3$" "")
       (.sub re "_" " ")
       (.strip)
       (.sub re "^.* - " "")
       (.sub re "^[\d\. ]+" "")
       (.sub re ".* \d{2} " "")))

(defn derive-tags [mp3s]
  (defn derive-tag [pos mp3]
    (try
     (let [[tag (.Tag eyeD3)]]
       (tag.link mp3)
       (, mp3 (str (.getArtist tag)) (str (.getAlbum tag)) 
              (str (.getGenre tag)) (str (.getTitle tag)) pos))
     (catch [err]
       (, mp3 "" "" "" ""))))
  (ap-map (apply derive-tag it)  mp3s))

(defn print-help []
  (print "Usage:")
  (ap-each optlist (print (.format "	-{}	--{}	{}" (get it 0) (get it 1) (get it 3))))
  (sys.exit 0))

(defn clean-paren [s] 
  (if (not (= (.find s "(") -1))
    (.sub re "\(.*?\)" "" s)
    s))

(defn is-ascii [s] 
  (= (.decode (.encode s "ascii" "ignore") "ascii") s))

(defn ascii-or-nothing [s]
  (if (is-ascii s) s ""))
  

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
    (if (= (len cts) 0) 
      ""
      (get (get cts 0) 1))))

(defn sfix [s]
  (let [[seq (.split (.strip s))]]
    (smart_str (string.join (ap-map (.capitalize it) seq) " "))))

(defn suggest [opts]
  (let [[mp3s 
         (->> (os.listdir ".") 
              (ap-filter (and (> (len it) 4) (= (slice (.lower it) -4) ".mp3")))
              (sorted)
              (enumerate)
              (derive-tags)
              (list))]
        [(, loc_artist loc_album) (artist-album)]

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
        
        [artist 
         (if (.has_key opts "artist")
           (get opts "artist")
           (sfix loc_artist))]]
    
    (print genre album artist)))

(defmain [&rest args]
  (try
   (let [[optstringsshort 
          (string.join (ap-map (. it [0]) optlist) ":")]
         [optstringslong 
          (list (ap-map (+ (. it [1]) (cond [(. it [2]) "="] [true ""])) optlist))]
         [(, opt arg) 
          (getopt.getopt (slice args 1) optstringsshort optstringslong)]
         [options 
          (ap-reduce (find-opt-reducer acc it) opt {})]]
         (cond [(.has_key options "h") (print-help)]
               [(.has_key options "v") (print-version)]
               [true (suggest options)]))))




  


