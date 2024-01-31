xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

declare variable $clause-text := ("cum", "cumque", "ubi", "ubi(que|)(nam|)", "ubicumque", "quando", "dum", "donec", "dummodo", "modo", "antequam", "posteaquam", "postmodum quam", "postquam", "priusquam", "quotiens", "quotiens(cum|)que", 'quatenus', 'quo', 'quorsum', 'utroque', 'ubiubi', 'quoquo', 'undecumque', 'quaqua', 'sicubi', 'siquo', 'sicunde', 'siqua', "quoniam", "quod", "quia");
"#From sentence-stats.xq; parataxis-overall-x.xx.xx.csv; NORMSUB is the SUB value divided by the SENTLEN value",
fn:string-join(('WORK,SENT-ADDR,TEXT,MAIN,PRED,PARENTH,O.R.', $clause-text ! fn:upper-case(.), 'ADV,COMP,ATR,ABLABS,SUB,NORMSUB,SENTLEN,WORKLEN,GENRE,SUM,COORD,ASYND'), ","),
let $names := deh:short-names()

for $work in $names
for $sent in $all-trees[fn:matches(deh:work-info(.)(1), $work)]//sentence
let $addr := deh:get-sent-address($sent)
let $text := deh:print($sent) => fn:replace("[^a-zA-Z ]", "")

let $split-mainverbs := deh:split-main-verbs($sent)
let $main := fn:count($split-mainverbs?*)
let $pred := fn:count($split-mainverbs?1)
let $parenth := fn:count(functx:distinct-nodes(($split-mainverbs?2, $sent/*[deh:is-parenthetical(., false())])))
let $or := fn:count($split-mainverbs?3)



let $clauses := deh:get-clause-pairs($sent)
let $lemma-counts :=  for $item in $clause-text return fn:count($clauses[.(1)/deh:lemma(., $item)])

let $adv := fn:count(deh:adverbial-clause($clauses))
let $comp := fn:count(deh:complement-clause($clauses))
let $atr := fn:count(deh:adjectival-clause($clauses))
let $ablabs := deh:ablative-absolute($sent)
let $sub := fn:count($clauses) (:Don't forget this needs to be counted the same way as in pos-summary.xq:)
let $len := deh:word-count($sent)
let $normsub := if ($len > 0) then ($sub div $len) else (0)
let $worklen := deh:word-count($all-trees[fn:base-uri(.) = fn:base-uri($sent)])
let $genre := if (deh:get-short-name(deh:work-info($sent)(1)) = ("Fab", "Elegi", "Sati", "Aen", "Met", "Carm", "Amor")) then ("poetry") else ("prose")
let $sum := fn:string-join(($adv, $comp, $atr), "|")
let $coord := fn:count(deh:clause-coordination($sent))
let $asynd := if ($main > 0) then ($coord div $main) else ("NA") (:Main, that is, all types of unsubordinated verbs:)
return fn:string-join(($work, $addr, $text, $main, $pred, $parenth, $or, $lemma-counts, $adv, $comp, $atr, $ablabs, $sub, $normsub, $len, $worklen, $genre, $sum, $coord, $asynd), ",")
