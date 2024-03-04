xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

"#pos-summary.xq; pos-summary-x.xx.xx.csv;the counts in participle, noun, and preposition include also the number of words dependent on each within the sentence",
"WORK,SENT.ADDR,TEXT,PRED,SUB,PARTICIPLE,NOUN,PREPOSITION,PRONOUN,SENTLEN,WORKLEN",
let $works := deh:short-names()

for $work in $works
let $treebank := $all-trees[fn:matches(deh:work-info(.)(1), $work)]

let $worklen := deh:word-count($treebank)

for $tree in $treebank//sentence
where deh:get-sent-address($tree) != ("/proiel/caes-gal.xml|53107", '/harrington/7535/lattb.7535.1.tb.xml|20', '/proiel/caes-gal.xml|54138') (:Exclude ones over 100 sentences:)
let $sentlen := deh:word-count($tree)
let $sentaddr := deh:get-sent-address($tree)
let $text := deh:print($tree) => fn:replace(",", "")

let $pred := fn:count(deh:split-main-verbs($tree)?1)
let $sub := fn:count(deh:get-clause-pairs($tree)) (:Don't forget this needs to be counted the same way as in sentence-stats.xq:)
let $participles := $tree/*[deh:mood(.) = 'p' and deh:is-periphrastic-p(.) = false()]
let $participles := deh:word-count(($participles, deh:return-descendants-nonp($participles)))

let $nouns := $tree/*[deh:is-noun(.)]
let $nouns := deh:word-count(($nouns, deh:return-descendants($nouns)))

let $prepositions := $tree/*[deh:part-of-speech(.) = ('r', 'R')]
let $prepositions := deh:word-count($prepositions)

let $pronouns := $tree/*[deh:part-of-speech(.) = ('p', 'Pd', 'Px', 'Pp', 'Pk', 'Pc') and deh:is-relative(.) = false()] (:Includes, on the proiel side, demonstratives, indefinites, personal pronouns, personal reflexive pronouns, and reciprocal pronouns:)
let $pronouns := deh:word-count($pronouns)

return fn:string-join(($work, $sentaddr, $text, $pred, $sub, $participles, $nouns, $prepositions, $pronouns, $sentlen, $worklen), ",")