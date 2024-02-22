xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)
'clause-place.xq;clause-place-x.xx.xx.csv; START gives whether the clause appears before or after the main verb, and selects the main verb which it is dependent on, not any main verb',
'WORK,SENT-ADDR,TEXT,CLAUSE,START,WORKLEN',
let $works := deh:short-names()

for $work in $works
let $treebank := $all-trees[fn:matches(deh:work-info(.)(1), $work)]
let $total-length := deh:word-count($treebank)
let $clauses := deh:get-clause-pairs($treebank)


for $clause in $clauses
let $sentMain := deh:split-main-verbs($clause?1/..)(1) (:If there are multiple main clauses, I want it to be focused around the correct one:)
let $sentMain :=
if (fn:count($sentMain[functx:is-node-in-sequence($clause?1[1], deh:return-descendants(.))]) > 0) then ($sentMain[functx:is-node-in-sequence($clause?1[1], deh:return-descendants(.))])
else if (fn:count($sentMain) > 0) then (deh:closest-pred($clause?1))
let $start := 
if (boolean($sentMain)) then (
if (functx:is-node-in-sequence($clause?1[1], $sentMain[1]/preceding-sibling::*)) then ("before")
else if (functx:is-node-in-sequence($clause?1[1], $sentMain[1]/following-sibling::*)) then ("after"))
else ("NA")
let $lemma := $clause?1/fn:replace(deh:process-lemma(fn:string(@lemma)), ",", "")
return fn:string-join(($work, deh:get-sent-address($clause?1/..), deh:print($clause?1/..) => fn:replace("[^a-zA-Z ]", ""), $lemma, $start, $total-length), ',')