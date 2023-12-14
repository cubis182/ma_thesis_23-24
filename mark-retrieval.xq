xquery version "4.0";

(:NOTE THAT, FOR THE BASEX IMPLEMENTATION, SET WRITEBACK true IS NECESSARY FOR THIS TO WORK:)

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace stats = "ma-thesis-23-24" at "stats.xqm";



import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";
(:In case it is being weird, get functx from:
C:/Program Files (x86)/BaseX/src/functx_lib.xqm
Website is:
http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

(: This module MUST be stored in the same folder; both should be in my GitHub repository:)
import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";

db:get('proiel')//div[boolean(sentence[boolean(./*[fn:contains(fn:string(@citation-part), 'MARK')])])]
