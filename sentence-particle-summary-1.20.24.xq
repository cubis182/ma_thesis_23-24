xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

"#from sentence-particle-summary-1.20.24.xq; Has the count of adverbs retrieved by deh:causal-adverb and deh:spatio-temporal-adverb.",
('WORK,SENT-ADDR,TEXT,CAUS.COUNT,TIME.COUNT,SENTLEN,WORKLEN'),
let $works := deh:short-names()

for $work in $works
let $treebank := $all-trees[fn:matches(deh:work-info(.)(1), $work)]
let $work-length := deh:word-count($treebank)
for $tree in ($treebank//sentence)

let $sent-addr := deh:get-sent-address($tree)
let $text := deh:print($tree) => fn:replace(",", "")
let $space := fn:count((deh:spatio-temporal-adverb($tree)))
let $cause := fn:count((deh:causal-adverb($tree)))
let $sent-length := deh:word-count($tree)
return fn:string-join(($work, $sent-addr, $text, $cause, $space, $sent-length, $work-length),",")
