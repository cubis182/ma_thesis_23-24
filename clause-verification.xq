xquery version "4.0";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

(:
let $working := ($all-trees => deh:get-clause-pairs())[array:size(.) > 1]
return fn:distinct-values(for $item in $working return $item(2)/fn:string(@relation)):)

(:fn:distinct-values((($all-trees => deh:get-clause-pairs()) ! deh:relation-head(.))/fn:string(@relation)):)

let $rels := ('xadv', 'xobj', 'narg', 'rel', 'voc')
for $sent in $proiel//sentence
where boolean($sent/*[functx:contains-any-of(fn:string(@relation), $rels)])
return deh:get-clause-pairs($sent)[functx:contains-any-of(deh:relation-head(.)/fn:string(@relation), $rels)]