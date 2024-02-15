xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

"#parentheticals.xq; POSITION is the number of preceding nodes divided by the total sentence length",
("WORK,SENT.ADDR,PARENT,PARENTH,FULL.PARENTH,LENGTH,START,NORMLEN,POSITION,ENIM,NAM,SENT,SENTLEN"),
let $parenth := deh:retrieve-parentheticals($all-trees)
for $item in $parenth
let $sentlen := deh:word-count($item/..)

let $full-parenth := (:Full parenthetical:)(for $desc in functx:distinct-nodes(($item, deh:return-descendants($item))) order by $desc/fn:number(@id) return $desc)
let $start := $full-parenth[1] (:This ought to be the first word in the parenthetical:)
let $parenlen := deh:word-count($full-parenth)
let $startPlace :=
if (functx:is-node-in-sequence($item, (deh:split-main-verbs($item/..)(1))[1]/preceding-sibling::*)) then ("before")
else if (functx:is-node-in-sequence($item, (deh:split-main-verbs($item/..)(1))[1]/following-sibling::*)) then ("after")
else ("na")
let $normlen := if ($sentlen > 0) then ($parenlen div $sentlen) else (0)
let $enim := fn:count($full-parenth[deh:lemma(., 'enim')])
let $nam := fn:count($full-parenth[deh:lemma(., 'nam')])
let $position := deh:normed-position($start)
return fn:string-join((:Work:)(deh:get-short-name(deh:work-info($item)(1)), (:Sent.Addr:) deh:get-sent-address($item/..), (:Parent:) if (boolean(deh:return-parent-nocoord($item))) then (deh:return-parent-nocoord($item)) else (""), (:Parenthetical:) $item/fn:string(@form) => fn:replace("[^a-zA-Z ]", ""), (:Full parenthetical:) fn:string-join($full-parenth/fn:lower-case(fn:string(@form)), " ") => fn:replace("[^a-zA-Z ]", ""), (:Length:)$parenlen, (:Start:)$startPlace, (:Normed length:) $normlen, (:Number of preceding words:)$position, $enim, $nam, (:Sentence:) deh:print($item/..) => fn:replace("[^a-zA-Z ]", ""), (:Sentence length:)$sentlen), ",")