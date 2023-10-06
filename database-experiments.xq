xquery version "3.1";

(: This module MUST be stored in the same folder; both should be in my GitHub repository:)
import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";
(:
:)

import module namespace functx = "http://www.functx.com" at "C:/Program Files (x86)/BaseX/src/functx_lib.xqm";
(:Backup for functx when the internet is crap: C:/Program Files (x86)/BaseX/src/functx_lib.xqm 
  http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

(:Delete trees by deleting their folder in the 'data' folder in the BaseX directory? :)

db:attribute("proiel", "C-", "part-of-speech")