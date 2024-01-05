xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)


("WORK,SENT.ADDR,PARENTH,SENT"),
let $parenth := ($all-trees//sentence/*[deh:is-parenthetical(., false())])
for $item in $parenth
return fn:string-join((deh:get-short-name(deh:work-info($item)(1)), deh:get-sent-address($item/..), fn:string-join((for $desc in functx:distinct-nodes(($item, deh:return-descendants($item))) order by $desc/fn:number(@id) return $desc/fn:string(@form)), " ") => fn:replace("[^a-zA-Z ]", ""), deh:print($item/..) => fn:replace("[^a-zA-Z ]", "")), ",")