xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

"#From abl-abs.xq, goes to ablative-absolute.csv; Each line is a different ablative absolute. note that the ABL.ABS column has all the words in the ablative absolute, although the head of the phrase will come first, so it might not be in order",
'WORK,SENT-ADDR,TEXT,ABL.ABS,VERB,SENTLEN,WORKLEN',
let $names := deh:short-names()

for $work in $names

for $doc in $all-trees[fn:matches(deh:work-info(.)(1), $work)]
let $work-length := deh:word-count($doc)

for $sent in $doc//sentence
let $sent-length := deh:word-count($sent)
let $addr := deh:get-sent-address($sent)
let $text := deh:print($sent) => fn:replace("[^a-zA-Z ]", "")
let $abl-abs := deh:ablative-absolute($sent)
for $tok in $abl-abs
return fn:string-join(($work, $addr, $text, fn:string-join(($tok/fn:string(@form), deh:return-descendants($tok)/fn:string(@form)), " ") => fn:replace("[^a-zA-Z ]", ""), $tok/deh:process-lemma(fn:string(@lemma)), $sent-length, $work-length), ",")

