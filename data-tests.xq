xquery version "4.0";

import module namespace stats = "ma-thesis-23-24" at "stats.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";
(:In case it is being weird, get functx from:
C:/Program Files (x86)/BaseX/src/functx_lib.xqm
Website is:
http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

(: This module MUST be stored in the same folder; both should be in my GitHub repository:)
import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

declare variable $ola := db:get('ola');(:fn:collection("./../latinnlp/texts/ola");:)

declare variable $full-proiel := db:get("Full-PROIEL"); (:This is PROIEL with the full Vulgate back, not absolutely every PROIEL treebank:)

let $works := deh:short-names()

for $work in $works
let $tree := $all-trees[fn:matches(deh:work-info(.)(1), $work)]

let $work-length := fn:count($tree//sentence/*[deh:is-punc(.) = false() and deh:is-empty(.) = false()])

let $causal-adv := for $item in (deh:causal-adverb($tree)) return array{$item/fn:string(@lemma), ('causal', 'para', $work-length)}

let $sp-temp-adv := deh:spatio-temporal-adverb($tree)
let $mixed-adv := for $item in $sp-temp-adv[.(2) = 'mixed-spatial-temporal'] return array{$item(1)/fn:string(@lemma), ('mixed', 'para', $work-length)}
let $spatial-adv := for $item in $sp-temp-adv[.(2) = 'spatial'] return array{$item(1)/fn:string(@lemma), ('spatial', 'para', $work-length)}
let $temporal-adv := for $item in $sp-temp-adv[.(2) = 'temporal'] return array{$item(1)/fn:string(@lemma), ('temporal', 'para', $work-length)}

(:clause:)
let $clause-pairs := deh:get-clause-pairs($tree) 
let $causal-clause := for $item in ($clause-pairs => deh:causal-clause() => deh:format-clause-pairs()) return array{$item, ('causal', 'hypo', $work-length)}
let $spatial-clause := for $item in (($clause-pairs => deh:spatial-clause()) => deh:format-clause-pairs()) return array{$item, ('spatial', 'hypo', $work-length)}
let $temporal-clause :=  for $item in ($clause-pairs => deh:temporal-clause() => deh:format-clause-pairs()) return array{$item, ('temporal', 'hypo', $work-length)}

for $item at $n in ($causal-adv, $mixed-adv, $spatial-adv, $temporal-adv, $causal-clause, $spatial-clause, $temporal-clause)
return fn:string-join(($n, $work, fn:lower-case(fn:replace($item?1, "[#0-9]", "")), $item?2, $item?3, $work-length), ",")