xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

('WORK,SENT-ADDR,MAIN,PRED,PARENTH,O.R.,ADV,COMP,ATR,SUB,SENTLEN'),
let $names := deh:short-names()
for $work in $names
for $sent in $all-trees[fn:matches(deh:work-info(.)(1), $work)]//sentence
let $addr := deh:get-sent-address($sent)

let $split-mainverbs := deh:split-main-verbs($sent)
let $main := fn:count($split-mainverbs?*)
let $pred := fn:count($split-mainverbs?1)
let $parenth := fn:count($split-mainverbs?2)
let $or := fn:count($split-mainverbs?3)

let $clauses := deh:get-clause-pairs($sent)
let $adv := fn:count(deh:adverbial-clause($clauses))
let $comp := fn:count(deh:complement-clause($clauses))
let $atr := fn:count(deh:adjectival-clause($clauses))
let $sub := fn:count($clauses)
let $len := deh:word-count($sent)
return fn:string-join(($work, $addr, $main, $pred, $parenth, $or, $adv, $comp, $atr, $sub, $len), ",")
