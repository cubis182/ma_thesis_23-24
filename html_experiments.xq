xquery version "3.1";

import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

declare variable $treebanks := fn:collection("./treebank_data/v2.1/Latin/texts");

for $treebank in $treebanks
let $html := html:parse(fetch:binary(fn:concat("https://catalog.perseus.org/catalog/", deh:cts-urn($treebank))))
let $node := $html//h4[text() eq "Work Information"]/../dl (:Gets the bundle of work info:)
let $work-info := $node/dd
let $title := $work-info[2]
let $author := $node//*[text() eq "Author:"]/following-sibling::dd[1]/a/text()
return $author