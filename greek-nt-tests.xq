
import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";

declare variable $proiel := db:get('proiel');

let $greek-nt := doc('C:/Users/T470s/Documents/GitHub/ma_thesis_23-24/PROIEL-DATA/syntacticus-treebank-data/greek-nt.xml')
for $tok in $proiel//token[deh:lemma(., 'nam')]
return $greek-nt//token[@id=$tok/@alignment-id]/..