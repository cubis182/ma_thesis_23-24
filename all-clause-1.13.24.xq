xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

"#from all-clause-1.13.24.xq; TOK-ADDR is the address of the subordinator.",
('WORK,SENT-ADDR,TEXT,SUB.ADDR,SUB,VERB,TAG,SENTLEN,WORKLEN'),
let $works := deh:short-names()

for $work in $works
let $treebank := $all-trees[fn:matches(deh:work-info(.)(1), $work)]
let $total-length := deh:word-count($treebank)
for $tree in ($treebank//sentence)

let $text := deh:print($tree) => fn:replace("[^a-zA-Z ]", "")

let $sent-length := deh:word-count($tree)



let $clause-pairs := deh:get-clause-pairs($tree)[array:size(.) > 1] (:Use fn:count here, not array:size, because deh:get-clause-pairs can put empty arrays in:)

let $temporal := deh:temporal-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_temp'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "temp"}
let $spatial := deh:spatial-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_space'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "space"}
let $causal := deh:causal-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_causal'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "caus"}

let $purpose := deh:purpose-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_purp'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "purp"}
let $object := deh:object-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_obj'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "obj"}
let $conditional := deh:conditional-clause($clause-pairs) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_cond'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "cond"}
let $headless := deh:headless-clause($clause-pairs) ! array{.?2/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_headless'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "headless"}

let $taken := (deh:temporal-clause($clause-pairs), deh:spatial-clause($clause-pairs), deh:causal-clause($clause-pairs),deh:causal-clause($clause-pairs),deh:causal-clause($clause-pairs), deh:conditional-clause($clause-pairs), deh:headless-clause($clause-pairs))

let $reliquiae := for $tok at $n in $clause-pairs where (functx:is-node-in-sequence($tok?1, $taken?1) = false()) and (functx:is-node-in-sequence($tok?2[1], $taken?2) = false()) return $clause-pairs[$n]

let $adjectival := deh:adjectival-clause($reliquiae) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_adj'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "adj"}
let $noun := deh:complement-clause($reliquiae) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_noun'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "noun"}
let $adverbial := deh:adverbial-clause($reliquiae) ! array{.?1/deh:get-tok-address(.), (.?1/deh:process-lemma(fn:string(@lemma)) || '_adv'), .?2[1]/deh:process-lemma(fn:string(@lemma)), "adv"}

(:Now deal with every clause pair which was not identified by any of the functions: see if it is in the sequence we already have, then add an '_unk' tag for 'unknown':)
let $leftovers := for $tok at $n in ($reliquiae)?1 where $tok instance of node() return if (functx:is-node-in-sequence($tok, (deh:adjectival-clause($reliquiae), deh:complement-clause($reliquiae), deh:adverbial-clause($reliquiae))?1) = false()) then (array{($reliquiae[$n]?1/deh:process-lemma(fn:string(@lemma)) || '_unk'), $reliquiae[$n]?2[1]/deh:process-lemma(fn:string(@lemma)), "unk"})

let $full-seq := ($temporal, $spatial, $causal, $purpose, $object, $conditional, $headless, $adjectival, $noun, $adverbial, $leftovers)

let $csv := 
for $array in $full-seq
where array:size($array) = 4
(:('WORK,SENT-ADDR,TEXT,SUB,VERB,TAG,SENTLEN,WORKLEN'),:)
return fn:string-join(($work, deh:get-sent-address($tree), deh:print($tree) => fn:replace("[^a-zA-Z ]", ""), $array?1, $array?2, $array?3, $array?4, $sent-length, $total-length), ",")

return $csv