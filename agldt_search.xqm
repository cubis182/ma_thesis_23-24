xquery version "3.1";

module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A";

import module namespace functx = "http://www.functx.com" at "C:/Program Files (x86)/BaseX/src/functx_lib.xqm";
(:Backup for functx when the internet is crap: C:/Program Files (x86)/BaseX/src/functx_lib.xqm :)

(:
5/18/2023: 
This function takes the TAGSET.xml from the dependency treebank and returns a sequence, which has the possible postags in order.
--------OBSOLETE NOTES BELOW-----------
Function to test whether a postag matches search terms (5/18/2023: I have repurposed this temporarily, old arg list was ($search as item()*, $postag as xs:string) as xs:boolean). The tagset.xml from the GitHub treebank master must be in the same directory as this file; IN THE FUTURE, this should pull straight from the internet:)
declare %public function deh:postags() as item()*
{
  let $tagset := doc("TAGSET.xml")
  let $results :=
  for $values in $tagset//attributes//values
  let $maps := 
  for $tag in $values/*
  return map{$tag/postag/text() : $tag/long/text() }
  return map:merge($maps)
  return $results
};

(:
7/3/2023
This function, by the end of the project, should be able to take any treebank XML document and spit out its URN. The ideal scenario is the whole URN starting from "urn" and ending with the end of the work title, say, "phi001" being an example. This needs to be able to match up with the URN as it is in the Perseus catalogue, from which I will draw this info.

The return value will be a string with the author and work title all in one.

$doc: A single LDT (normal or Harrington) word
:)

(:--------------------------START NAMES/URNS SECTION------------------------------:)

declare function deh:cts-urn($doc as node()*)
{
  for $xml in $doc (:get each document one at a time:)
  return if ($xml/*/name() eq "treebank") then (
    let $id := $xml//sentence[1]/fn:string(@document_id)
    let $end := (functx:index-of-string($id, ".perseus") - 1)
    return fn:substring($id, 1, $end)
)
  else if (($xml/name() eq "word") or ($doc/name() eq "sentence")) then (
    deh:cts-urn(doc(fn:base-uri($xml)))
  )
  else (
    "Error! Not a recognized format."
  )
  
};

(:
7/3/2023:
Takes only a single doc as its argument, and returns an array with the title and author in that order. Doesn't always work, it does provide a weird result for the Vulgate, but that is more the fault of the authors for using a more general URN for Revelation in the New Testament and not referring to the Vulgate specifically.

$doc: a SINGLE XML treebank document
:)
declare function deh:info-from-html($doc as node()*)
{
  
  let $html := html:parse(fetch:binary(fn:concat("https://catalog.perseus.org/catalog/", deh:cts-urn($doc)))) (:Get the Perseus Catalog entry:)
  let $node := $html//h4[text() eq "Work Information"]/../dl (:Gets the bundle of work info:)
  let $work-info := $node/dd (:Get the nodes which contain the work info:)
  let $title := $work-info[2]
  let $author := $node//*[text() eq "Author:"]/following-sibling::dd[1]/a/text()
  return array{fn:concat($title, ", "), $author}
};

(:
7/3/2023:
This function returns, for each of the supplied documents (whether one or more) one or more arrays with the title (plus possibly other additional info) and then the author.

$doc: One or more documents
:)
declare function deh:work-info($doc as node()*)
{
  for $xml in $doc
  return if ($xml/*/fn:string(@version) eq "2.1") then ( (:For the newer, 2.1 version of the official LDT:)
    array{fn:concat($xml//title/text(), " ", $xml//biblScope/text()), $xml//author/text()}
  )  
  else if ($xml/*/fn:string(@version) eq "1.5") then ( (:For the older version (1.5) of the official LDT:)
    deh:info-from-html($xml)
  )
};

(:-------------------------END NAMES/URNS SECTION---------------------------:)

(:
5/19/2023:
This function takes the TAGSET.xml file from AGLDT and extracts a list of the relations; the potential suffixes (such as "CO" or "ExD" (without quotes)) are listed separately; therefore, YOU MUST MAKE SURE TO SEARCH FOR PARTIAL, NOT FULL, MATCHES. It takes no arguments, and returns the strings in a simple sequence

This function relies on no other functions. It is currently public, BUT MAYBE MAKE IT PRIVATE LATER, IF NECESSARY
:)
declare %public function deh:relations() as item()*
{
  let $tagset := doc("TAGSET.xml")
  for $values in ($tagset//labels, $tagset//suffixes) 
  for $tag in $values/*
  return $tag//short/text()
};

(: KINDA OBSOLETE, THERE IS LIKELY A BETTER WAY TO DO THIS... Winter Break 2022-23 Phase :)
(:IF YOU WANT TO UPDATE PUNCTUATION, COME HERE
This function takes a string, and returns true if it matches punctuation. This is meant to take the 
form of a word and check if it is punctuation so it does not get counted when checking sentence length:)
declare %private function deh:check-punct($form as xs:string) as xs:boolean
{
   let $illegal-chars :=  ('!', ',', '.', ';', '?', '-')
   return functx:is-value-in-sequence($form, $illegal-chars)
};

(:Returns a sequence of the length of each sentence in a given document. This function will automatically remove instances of punctuation. In order to update the punctuation removing function, modify the deh:check-punct function:)
declare %public function deh:sentence-lengths($docs as node()*) as item()*
{
  for $doc in $docs
    for $sentence in $doc//sentence
      let $words := $sentence/word[deh:check-punct(fn:string(@form)) ne true()]
        return <count sentenceid='{$sentence/fn:string(@id)}'>{fn:count($words)}</count>
};

(:
5/18/2023:


:)


(:------------------START deh:postag-andSearch AND DEPENDENCIES/OTHER SEARCH TOOLS------------------------------:)
(: 
5/19/2023 remarks:
$search is a sequence of strings which matches the long, elaborated string in the TAGSET for part of speech
$doc is a treebank document
$postags is the result of the deh:postags() function

Usage example:
I want to get every word which is a third-person singular perfect verb:
deh:postag-andSearch(("third person", "singular", "perfect"), doc("C:\Users\*treebank"), deh:postags())

---------------------kinda OBSOLETE NOTES BELOW----------------------------
 Winter Break 2022-23 Phase
This function takes an sequence of fully written-out strings ($search) which are specified in the $postags var in AGLDT Search Test.xq. The second argument is a document which the function can check. $postags is essentially the "deh:postags()" function 

6/25/2023:----------------OBSOLETE---------------------
Changed the loop at the start from "for $word in $doc//sentence/word" to "in $doc//word", no need to have extra steps. Also added the below description.

This function is primarily used in the deh:search function, as part of a fuller search by pos, relation, lemma, etc. However, it is used in a variety of circumstances. It takes a sequence of characteristics of part of speech in the $search (as a string, "third person", "gerund" etc.), and handles the search for words which match all of these in the provided $doc. It does none of the searching itself (the following updated 6/27/2023) (deh:andSearch shell takes a sequence of <word/> elements, handles whether to keep or discard them, deh:word-postag, descendant on it, actually tests each word), this function simply makes sure the input is a sequence of words (NOT a hierarchical structure including sentences), and returns the output from the deh:word-postag function. See the description to deh:andSearch-handler for more details.


$search: A set of POS tag search parameters, like ("comparative", "nominative", "plural"); can also be a single, lone string
$doc: A treebank, like "C:\Users\T470s\Documents\2023 Spring Semester\Latin Dependency Treebank (AGLDT)\vulgate.xml"
$postags: Just the deh:postags function, every time; in this case, usually passed from a parent function

Depends on:
deh:andSearch-handler()
:)
declare %public function deh:postag-andSearch($search as item()*, $doc, $postags as item()*) as item()*
{
  let $tokens := deh:tokens-from-unk($doc) (:function added 7/12/2023 to handle extracting just the sequence of tokens:)
  return deh:andSearch-handler($search, $tokens, $postags)
};

(:
6/27/2023:
This function is a helper function to deh:postag-andSearch. I wanted to be able to pass a series of <word/> elements, which were already pulled by a search (that is, if I find a list of every word descendant on a PRED, )

Depends on:
deh:word-postag()

:)
declare %private function deh:andSearch-handler($search as item()*, $doc as element()*, $postags as item()*) as item()*
{
  (:Loop through every word in the document:)
  for $word in $doc (:This function is private BECAUSE we assume $doc is a series of individual <word/> elements:)
    (:I made the below FLWOR statement a variable so it does not return the same word more than once:)
    let $results := deh:word-postag($search, $word, $postags)
    return if ($results) then
    $word
    else ()
};

(:
Spring 2023 Phase:
THIS IS WHERE THE CHEESE IS MADE, the search functionality really hinges on this.
This function is meant as a helper function to the deh:postag-andSearch (in that it does all the actual searching, the deh:postag-andSearch really only chooses to return or discard what this function spits out). It is also used elsewhere, though. What it does is go through each position in the postag, and wherever it finds a positive result, it returns true() in a sequence. If the sequence holds the same number of "true()s" as there are search terms, we return a true() value, and false() if not.

$search: A set of POS tag search parameters, like ("comparative", "nominative", "plural")
$word: A single word node from an LDT treebank
$postags: Just the deh:postags function, every time, usually passed from a previous function

Depends on:

:)
declare function deh:word-postag($search as item()*, $word as element(), $postags as item()*) as xs:boolean
{
  let $postag := $word/fn:string(@postag)
  (:I made the below FLWOR statement a variable so it does not return the same word more than once:)
    let $check :=
    for $teststr in $search
      for $char at $n in functx:chars(fn:string($postag))
      where $postags[$n](xs:string($char)) eq $teststr
      return true()
    (:Now, if the number of "trues" is equal to the number of search terms, we know it is a match:)
    return if (fn:count($check) eq fn:count($search)) then (
      true()
    )
    else (
      false()
    )
};

(:
5/19/2023:
Currently overhauling this function: it should take 5 arguments:

7/5/2023 note: Consider using the following scheme:

$a: A map with the following possibilities (I use double slashes (//) to denote a comment):

map {
  //option : value
  "postag": A sequence or single string equivalent to the parameters set out for $search in the deh:search() function description (how to handle the LDT postag, which handles morphology (kinda) and POS, and PROIEL, which separates those into <part-of-speech/> and <morphology/>?)
  "relation": A single string which is not case-sensitive and it what will appear in the @relation attribute of words/tokens. See the deh:test-rel-lemma() function for more info.
  "lemma": A single string which is the lemma you are looking for (doesn't have to match the full string, but what you enter must be at least part of the full string) There is no option to only find exact matches.
}

$search is a sequence of strings (or just a single string if only one search term) with the full names of the parts of the postag you wish to search. Just put an empty sequence if you don't need to use this parameter.
$relation is a single string, should at least partially match the relation you are looking for, does NOT use the expanded version of the relation names. THIS SHOULD ALLOW FOR AN EMPTY STRING, which should indicate a match in any scenario (for the fn:contains function will give a positive result with an empty string. It also, as of 7/3/2023, is not case-sensitive)
$lemma is the same, it will only check if the word's lemma CONTAINS the search string; therefore, leave it as an empty string if you don't want to specify; also not case-sensitive, as it says for $relation. There is no option to only find exact matches. There is no option to only find exact matches.
$doc is the SINGLE treebank you wish to search, or a set of <word/> elements
$postags is the output of the deh:postags() function

LIMITATIONS REMAIN: How to search for multiple things at once? (All perfect passives AND perfect actives together, for example?), or how this can easily feed into the dependency determining functions. ALSO, we should re-implement the deh:mark-node function, so we have a better handle on these results when exporting them to CSV

Relies on:
deh:word-postag(3 args)
deh:relations()
deh:postag-andSearch
deh:test-rel-lemma
:)
declare %public function deh:search($postag as item()*, $relation as xs:string, $lemma as xs:string, $doc, $postags) 
{
  (: This first statement runs if :)
  if (fn:count($postag) gt 0) then ( deh:test-rel-lemma(deh:postag-andSearch($postag, $doc, $postags), $relation, $lemma))
  else (deh:test-rel-lemma($doc, $relation, $lemma)) (:7/12/23: changed again, because the deh:tokens-from-unk now exists, which will return a sequence of tokens no matter whether a document is passed, or set of nodes, and does not depend on whether it is LDT or PROIEL:)
};

(:
5/19/2023:
This function is a helper function to deh:search; it takes $relation and $lemma from that functions arguments directly, and ONLY in that circumstance; the $words var is just a set of <word></word> nodes; it could be from the results of a different search, or could be a whole document, but it MUST only be those nodes; the changes I made 6/27/2023 to the deh:search function should ensure that. As of 7/3/2023, this function is no longer case sensitive.
:)
declare %private function deh:test-rel-lemma($words as element()*, $relation as xs:string, $lemma as xs:string) as element()*
{
  let $words := deh:tokens-from-unk($words)
  return $words[(fn:contains(fn:lower-case(fn:string(@relation)), fn:lower-case($relation)) eq true()) and (fn:contains(fn:lower-case(fn:string(@lemma)), fn:lower-case($lemma)) eq true())]
};

(:
deh:tokens-from-unk()
7/12/2023:

Deals with the issue of functions where I can pass either a document or the individual word-nodes; this function, whether it receives an LDT or PROIEL Treebank, returns just the token nodes no matter what. I would make this a %private function, but it is pretty harmless.

$tokens: either a document or series of nodes

Depends on:
:)
declare function deh:tokens-from-unk($tokens as node()*) as element()*
{
  if (($tokens[1]/name() eq "word") or ($tokens[1] eq "token")) then ($tokens)
  else if (fn:count($tokens//word) ne 0) then ($tokens//word)
  else if (fn:count($tokens//token) ne 0) then ($tokens//token)
  else ()
};


(: Winter Break 2022-23 Phase :)
(: $search is a sequence of strings, $doc is 1 or more documents, and the $postages (HOPEFULLY TO BE REPLACED - 5/18/2023) var stores a map of all the appropriate terms

Dieses Funktion müß so operiert werden; Beispiele:

let $doc := ("C:\Users\etwas_nonsinn.txt")
let $search := ("participle", "present", "active")
return deh:postag-andSearch($search, $doc)

auch lassen uns mehrere Beispiele aufzählen:
$search := ("nominative", "adjective")
$search := ("adjective", "nominative")
...usw.

hängt ab von:
deh:postag-orSearch
:)
(:
declare %public function deh:postag-andSearch($search as item()*, $doc as node())
{
  let $postags := deh:postags()
  let $embed :=
  for $teststr in $search
  return deh:postag-orSearch($teststr, $doc, $postags)
  for $node in $embed
  return if (fn:count(functx:index-of-node($embed, $node)) eq fn:count ($search)) then (
    $node
  )
  else (
  )
};
:)

(:-------------------------START deh:query AND DEPENDENCIES------------------------------------------:)

(:
deh:query()
7/4/2023:
This function should be the main entry point for searching the treebanks and getting data back in a reasonable format. Much of the description of the way it works is below in the function itself.

$a: A map with the following possibilities (I use double slashes (//) to denote a comment):

map {
  //option : value
  "postag": (7/5, MUST BE AN EMPTY SEQUENCE IF UNUSED) A sequence or single string equivalent to the parameters set out for $search in the deh:search() function description (how to handle the LDT postag, which handles morphology (kinda) and POS, and PROIEL, which separates those into <part-of-speech/> and <morphology/>?)
  "relation": A single string which is not case-sensitive and it what will appear in the @relation attribute of words/tokens. See the deh:test-rel-lemma() function for more info.
  "lemma": A single string which is the lemma you are looking for (doesn't have to match the full string, but what you enter must be at least part of the full string) There is no option to only find exact matches.
}
$b: Same as $a above

$a-to-b-rel: This is a map with the keys "relation", "depth" and "width". See below:

  "relation": the options for this argument are listed below:
    "child": results of $a must be children of results of $b
    "parent": results of $a must be parents of results of $b
    "sibling": results of $a must be siblings of results of $b
    "ancestor": results of $a must be parents or parents of parents of results of $b
    "descendant": results of $a must be descended from or descendants of words descended from results of $b
  "depth": An integer, to be used in only a few circumstances. If "relation" is "ancestor" or "descendant", (you can leave this empty if you want, default is 0 which signals deh:return-ancestors or deh:return-descendants to use their default behavior) "ancestor " at depth of 1 will return a parent, 2 the grandparent, etc. Same for descendant.
    
   "width": Another integer, only used if "relation" is "parent" or "ancestor". At 0, uses the default behavior of each function, and this is what the parser uses by default (if you provide no "width" option). At 1, this applies the deh:return-siblings function to the results, making it the whole previous generation.

$options:

map{
  //option : value
  "export": Takes a single string; if "xml", it will output results in an xml-friendly format (EXPAND ON THIS LATER); if "csv", will export the same results to a .csv format (actually comma-separated); if "bare", it will return the nodes alone just like a search; if  The default is "xml"
}
Notes:
Don't need a function yet for 

Depends on:
deh:results-to-csv
deh:check-rel-options() (private)
:)
declare %public function deh:query($a as map(*), $b as element()*, $a-to-b-rel as map(*), $options as map(*))
{
  (:Have the default return options ready if no options are submitted:)
  let $def-options := map{
    "export":"xml"
  }
  let $xml-str := "xml" (:So we can change the strings in one place, here are the export modes:)
  let $csv-str := "csv"
  let $node-str := "node"
  let $bare-str := "bare"
  
  let $postags := deh:postags()
  
  (:1 Removed this step, but this is where I would have generated the results for $b :)
  
  (:2: Use on of the relations set by $a-to-b-rel to determine the appropriate function
  Below are the available function, with the appropriate $a-to-b-rel string to its right:
    deh:return-children()   //child
    deh:return-parent()     //parent
    deh:return-siblings()   //sibling
    deh:return-ancestors()  //ancestor (only direct, one parent to another)
    deh:return-descendants()//descendant (all children, and their children, and their children, etc.; that whole section of the tree)
    
    Each of these functions should get results in the order they appear in the sentence, from beginning to end, at least in principle; that has not been tested. However, the point is, there is no need to go and create new 'next-sibling' or 'preceding sibling' stuff, since the order is maintained within each individual sentence anyway and the XPath axes should be good enough for finer distinctions.
  :)
  
   let $options-final := 
  if (map:size($options) eq 0) then (
    $def-options
  )
  else ($options)
    
  let $final-results := 
  for $node in $b (:Go through each of the already retrieved results:)
  let $b-rels := deh:use-rel-func($a-to-b-rel, $node) (:This and next line get targeted relatives of the node from $b, and do the search specified in this function's arguments:)
  let $search :=  deh:search($a("postag"), $a("relation"), $a("lemma"), $b-rels, $postags)
  return if (fn:count($search) gt 0) then (
    if ($options-final("export") eq $xml-str or $options-final("export") eq $node-str) then ( (:export each result as an XML node, if that option was chosen:)
      <tree-search>
        <head>
          {deh:mark-node($node)}
        </head>
        <results>
          {deh:mark-node($search)}
        </results>
        <search>
          <postag>{for $n in $a("postag") return fn:tokenize($n)}</postag>
          <relation>{$a("relation")}</relation>
          <lemma>{$a("lemma")}</lemma>
          <relation-to-head>
            <relationship>{$a-to-b-rel("relation")}</relationship>
            <all-siblings>{$a-to-b-rel("width")}</all-siblings>
            <depth>{$a-to-b-rel("depth")}</depth>
          </relation-to-head>
        </search>
      </tree-search>
    )
    else if ($options("export") eq $bare-str) then ( (:If "bare" was chosen, just return the unmarked results:)
      $search
    )
    else ("Error! Incorrect options set for export")
  )
  
  (:4: Removed this step, this is where I would have gotten $a:)
  
 
  
  return if ($options("export") eq $xml-str) then (<root>{$final-results}</root>)
  else ($final-results)
  (:5: Convert these to an XML format, or return them if "export":"node" is set :)
  
  (:6: Return those results, or export to .csv and then return:)
  
  
};

(:
7/4/2023:

:)
declare function deh:results-to-csv($results as node()*)
{
  (:About to create this: if a certain option is set:)
};

(:
deh:xml-export()
7/5/2023:
This function needs to mark each node up with the proper info (7/5 note, you should update deh:mark-node to do all this) and the bulk of this function is organizing it in an xml which can easily be converted to csv. That way, we can just export it as the xml if we want, but it is already in a good format if we want to look at it in another program.

CSV Notes:
The structure is <csv><record></record></csv>, where each record is a row, and the column is indicated by the tag on the elements in the <record/>
:)
declare %private function deh:xml-export($results as element()*)
{
  
};

(:
deh:get-rel-func()
7/4/2023:
This is a helper function to deh:query, which returns the appropriate relation to $b. For example, if I want to count perfect passives, and $a is the set of auxiliaries and $b is the set of participles, then I would pass $b with a map that has "relation":"child" and nothing else.

$map: Is the $a-to-b-rel argument from the deh:query function, this function tests whether it is valid and modifies it if it is slightly off
$nodes: Nodes to search, which should be arg $b

Depends on:
deh:check-rel-options
deh:return-children
deh:return-parent
deh:return-descendants
deh:return-ancestors
deh:return-siblings
:)

declare %private function deh:use-rel-func($map as map(*), $nodes as element()*)
{
  (:
  Relevant function declarations:
  declare %public function deh:return-parent($nodes as element()*, $width as xs:integer) as element()*
  declare %public function deh:return-children($nodes as element()*) as element()*
  declare function deh:return-ancestors($nodes as element()*, $depth as xs:string, $width as xs:integer) as element()*
  declare %public function deh:return-descendants($nodes as element()*, $depth as xs:integer) as element()*
  declare function deh:return-siblings($nodes as element()*, $include as xs:boolean) as element()*
  :)
  let $map := deh:check-rel-options($map)
  let $width := $map("width")
  let $depth := $map("depth")
  return if (fn:count($map("relation")) eq 0) then
  ("Error! No relation")
  else if ($map("relation") eq "child") then
  (deh:return-children($nodes))
  else if ($map("relation") eq "parent") then
  (deh:return-parent($nodes, $width))
  else if ($map("relation") eq "descendant") then
  (deh:return-descendants($nodes, $depth))
  else if ($map("relation") eq "ancestor") then
  (deh:return-ancestors($nodes, $depth, $width))
  else if ($map("relation") eq "sibling") then
  (deh:return-siblings($nodes, false()))
  else ()
};

(:
deh:check-rel-options
7/4/2023:
Used in deh:query to normalize the search options; if any option is left out, it puts a default one in.

:)
declare %private function deh:check-rel-options($map as map(*)) as map(*)
{
  (:Takes the $a-to-b-rel arg from deh:query and pretties is up.
  It must do the following:
  If "relation" is "ancestor" or "descendant", and a "depth" option is not set, set it to "0".
  If "relation" is set to "ancestor" and or "parent" and "width" is not set, set it to "0"
  :)
  
  let $rel := $map("relation") (:Pull out the relation now, same with depth and width:)
  let $depth := $map("depth")
  let $width := $map("width")
  return if ($rel eq "ancestor") then (
    if (fn:count($depth) eq 0) then (
      if (fn:count($width) eq 0) then (
        map {
          "relation":$rel,
          "depth":0,
          "width":0
        }
      )
      else (
        map {
          "relation":$rel,
          "depth":0,
          "width":$width
        }
      )
    )
    else if (fn:count($width) eq 0) then (
      map {
        "relation":$rel,
        "width":0,
        "depth":$depth
      }
    )
    else ($map)
  )
  else if ($rel eq "parent") then (
    if (fn:count($width) eq 0) then (
      map{
        "relation":$rel,
        "depth":0
      }
    )
    else ($map)
  )
  else if ($rel eq "descendant") then (
    if (fn:count($depth) eq 0) then (
      map{
        "relation":$rel,
        "depth":0
      }
    )
    else ($map)
  )
  else ($map)
};

(:-------------------------END deh:query AND DEPENDENCIES------------------------------------------:)

(:---------------------------END deh:postag-andSearch AND DEPENDENCIES/OTHER SEARCH TOOLS------------------------------:)

(: Winter Break 2022-23 Phase :)
(: Adds attributes to the node with the path of the document and the node's sentence id. Only do this at the end of the process (when spitting out results) and (6/25/2023) IGNORE THE FOLLOWING: (this function is private because it does not check for the type of node) INSTEAD, I made this public because it can be used optionally that way. Instead, it simply ignores nodes which are not "words"

7/3/2023: because of deh:ldt2.1-workinfo, this currently is incompatible with any other format

Depends on:
deh:ldt2.1-workinfo
:)
declare function deh:mark-node($nodes as element(*)*) as element()*
{
  
  for $node in $nodes
  where $node/name() eq "word" (:Change this later to be an if statement, where I can switch it to "token" to account for PROIEL:)
  let $work-info := deh:ldt2.1-workinfo($node) (:Remember that work-info[1] is the author, work-info[2] is the title, and work-info[3] is the subdoc (i.e., book and section number):)
  
  return functx:add-attributes(functx:add-attributes(functx:add-attributes(functx:add-attributes(functx:add-attributes(functx:add-attributes($node, xs:QName("deh-urn"), deh:cts-urn(doc(fn:base-uri($node)))), xs:QName("deh-subdoc"), $work-info[3]), xs:QName("deh-title"), $work-info[2]), xs:QName("deh-author"), $work-info[1]), xs:QName("deh-docpath"), fn:replace(xs:string(fn:base-uri($node)), "%20", " ")), xs:QName("deh-sen-id"), $node/../@id/fn:string())
  
  
};

(:
6/28/2023:

Kind of a hacked-together function, but if you want to know the number of times in a set of LDT <word/>'s '(presumably coming from a search) occurs with certain relations, this will give a list of each relation with its frequency below it.

$words: a series of LDT <word> nodes

:)
declare function deh:relation-freq($words as element()*) as item()*
{
  let $val :=
    for $word in $words
    return $word/fn:string(@relation)
  for $item in fn:distinct-values($val)
  return ($item, fn:count(fn:index-of($val, $item)))
};

(: Winter Break 2022-23 Phase :)
(: Change the confusing terms later: this works either way:)
declare %private function deh:process-pairs($original-descendants as element()*, $processed-descendants as element()*, $original-heads as element()*, $processed-heads as element()*) as element()*
{
  for $first-node at $n in $original-heads
  where functx:index-of-node($processed-heads, $first-node) gt 0
  let $return := 
    for $second-node in $processed-descendants
    where functx:index-of-node($original-descendants, $second-node) gt 0
    return $second-node
  return ($first-node, $return[$n])
  
};

(: Winter Break 2022-23 Phase :)
(: THIS WON'T WORK, COME UP WITH ANOTHER SOLUTION:)
(: Just note that the proc-results function should return a list which includes elements that overlap with the targets list, and that the proc-targets function should return a list which overlaps with the results list:)
declare %public function deh:return-pairs($results as element()*, $targets as element()*, $proc-results, $proc-targets)
{
  let $proc-results := $proc-targets($targets)
  let $proc-heads := $proc-results($results)
  return deh:process-pairs($targets, $proc-targets, $results, $proc-results)
};

(: Winter Break 2022-23 Phase :)
(: Should be private and used in the deh:return-pairs function later!!! :)
declare %public function deh:parent-return-pairs($descendants as element()*, $heads as element()*) as element()*
{
  
  let $parents := deh:return-parent($descendants, 0)
  for $node in $heads
  where functx:index-of-node($parents, $node) gt 0
  let $childReturn := 
    let $children := deh:return-children($node)
    for $child in $children
    where functx:index-of-node($descendants, $child) gt 0
    return $child
  return 
  <parent-return-pair>
    {deh:mark-node($childReturn)}
    {deh:mark-node($node)}
  </parent-return-pair>
  
};

(: Winter Break 2022-23 Phase :)
(: Returns a list of the WORD (AGLDT) parents of each word.
7/5/2023:
Now has a second argument $width. This allows you to return all the siblings of 
 :)
declare %public function deh:return-parent($nodes as element()*, $width as xs:integer) as element()*
{
  for $node in $nodes
  return if ($width eq 0) then
  $node/../word[@id eq $node/@head]
  else (
    deh:return-siblings($node/../word[@id eq $node/@head], true())
  )
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) children:)
declare %public function deh:return-children($nodes as element()*) as element()*
{
  for $node in $nodes
  return $node/../word[@head eq $node/@id]
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) ancestors from bottom-up, in order
7/4/2023: Added these args:
$depth: A number; if 0, just gets each parent by each parent one at a time; if not, it is the number of times we travel back up the tree
$width: whether or not we apply the deh:return-siblings function to the results

Depends on:
deh:return-parent
deh:return-siblings
:)
declare function deh:return-ancestors($nodes as element()*, $depth as xs:string, $width as xs:integer) as element()*
{
  if ($depth eq "0") then ( (:If depth is 0, just do the default thing:) 
  for $node in $nodes
    let $parent := deh:return-parent($node, 0)
    return if ($width eq "0") then ($parent, deh:return-ancestors($parent, $depth, $width)) (:Still must account for width: if 0, don't give siblings:)
    else if ($width eq "1") then (deh:return-siblings(($parent, deh:return-ancestors($parent, $depth, $width)), true())) (: If 1, return the siblings of each result:)
    else("Error!") 
  )
  else (
    if ($width eq "0") then 
    (deh:return-ancestors($nodes, "0", "0")[$depth])  (:No need to rewrite code; just use the default function, but this time pick out the right level, since we should only enter this code at a certain depth:)    
    else (deh:return-siblings(deh:return-ancestors($nodes, "0", "0")[$depth], true()))
  )    
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) descendants, going branch-by-branch, it will fill out each left-to-right
7/5/2023:
Previous statement is true if you set $depth to 0, in which case the function does simply perform the deh:return-function iteratively, returning that entire sub-branch of the tree. $depth allows you to specify whether you want a specific generation within those results. If you start from the highest word in the tree, you could specify any level you wanted, in other words

$nodes: One or many nodes, each of which is processed individually. Currently must be an LDT node
$depth: The depth within the 'descendants' results which you want to return; if 0, this returns all descendants, but, for example, a depth of 2 would return all the grandchildren of each $node passed into the function

Depends on:
deh:return-children()
deh:return-depth()

:)
declare %public function deh:return-descendants($nodes as element()*, $depth as xs:integer) as element()*
{
  if ($depth eq 0) then
  (
    for $node in $nodes
      let $children := deh:return-children($node)
      for $child in $children
        return ($child, deh:return-descendants($child, 0)) (:Instead of passing depth directly, just passing "0" just in case:)
    )
    else (
      for $node in $nodes
        let $node-depth := deh:return-depth($node, 1) (:Get the absolute depth from the root of the $node:)
        let $final-depth := $node-depth + $depth (:Add the specified depth to the node depth to get the absolute depth of the final values:)
        for $word in deh:return-descendants($node, 0)
          return $word[deh:return-depth(., 1) eq $final-depth] (:Only return descendants which match the right depth:)
    )
};

(:
deh:return-depth()
7/5/2023:
Gets the depth of the node, which is the number of steps back to the root (the root, not just the first word-node)
$iter: should always be 1

Currently private, as deh:return-descendants relies on it alone for its depth value

Depends on:
deh:return-parent
:)
declare function deh:return-depth($node, $iter as xs:integer)
{
  if (fn:count(deh:return-parent($node, 0)) eq 0) then
    ($iter)
  else (
    deh:return-depth(deh:return-parent($node, 0), ($iter + 1))
  )
};


(: Winter Break 2022-23 Phase
7/4/2023: Added this:
$include if $true, includes the node passed to the function (primarily if this is being used to implement the $width argument of deh:return-ancestors or deh:return-parent)
 :)
declare function deh:return-siblings($nodes as element()*, $include as xs:boolean) as element()*
{
  for $node in $nodes
    let $final := $node/../word[@head eq $node/@head]
    return if ($include) then
    $final
    else (
      $final[fn:string(@id) ne $node/fn:string(@id)]
    )
};

(: 
DEPRECATED
5/18/2023:
$head-terms is a sequence of strings which has search terms, $children-terms another set of string search terms (both in accordance with the deh:word-postag and deh:postag-andSearch functions), the $depth is what level of children (1 is a child, 2 is a grandchild, 3 a great-grandchilde, MAX IS 4); A VALUE OF 0 DEALS WITH ALL DESCENDANTS)

hängt ab von:
deh:word-postag
deh:postags()
:)
(:
declare %public function deh:feature-search($doc as node()*, $head-terms as item()*, $children-terms as item()*, $depth as xs:integer) as node()*
{
  let $postags := deh:postags()
  let $first-layer := deh:postag-andSearch($head-terms, $doc,$postags)
  for $word in $first-layer
  let $comparison := deh:return-depth($first-layer, $depth)
  for $sub-word in $comparison
  return if (deh:word-postag($children-terms, $sub-word, $postags)) then
  $word/..
  else (
    
  )
  (:
    Tasks:
    -go through an optional number of search parameters, be able to organize them by type of treebank for best modularity
    -get the search results for each and keep them separate, but also be aware that there can be multiple search parameters in a single arg
    -
  :)
};
:)

(:
DEPRECATED
Winter Break 2022-23 Phase:
This function returns all the nodes of a certain depth; goes no farther than 4, for now; there is likely a better algorithm for this
:)
(:
declare function deh:return-depth($nodes as element()*, $depth as xs:integer)
{
  if ($depth eq 0) then
  deh:return-descendants($nodes)
  else if ($depth eq 1) then 
  deh:return-children($nodes)
  else if ($depth eq 2) then
  deh:return-children(deh:return-children($nodes))
  else if ($depth eq 3) then
  deh:return-children(deh:return-children(deh:return-children($nodes)))
  else if ($depth eq 4) then
  deh:return-children(deh:return-children(deh:return-children($nodes)))
};
:)

(:
6/25/2023:
This function takes postag search parameters in $postag-search (like the ones that go in the first argument of deh:postag-andSearch), any individual LDT treebank document in $doc, and the output of the deh:postags functions in $postags. It finds the highest word in the hierarchy with a certain part of speech, starting at the head, but making its way down one generation at a time. This recursion occurs in the helper function deh:proc-highest, which is listed below.

The impetus was that sometimes PRED is not going to be the base node of a sentence, so I might want a function which encapsulates sentences where the PRED is elliptical or the sentence has no main clause.

$postag-search: A set of POS tag search parameters, like ("comparative", "nominative", "plural")
$doc: A treebank, like "C:\Users\T470s\Documents\2023 Spring Semester\Latin Dependency Treebank (AGLDT)\vulgate.xml"
$postags: Just the deh:postags function, every time

Depends on:
deh:proc-highest (private, made for this function to handle looping through each level of the sentence)
deh:postag-andSearch
:)
declare function deh:find-highest($postag-search as item()*, $doc as node()*, $postags)
{
  for $sent in $doc//sentence
    let $head := $sent/word[fn:number(@head) eq 0]
    return deh:proc-highest($postag-search, $head, $postags)
};

(:
6/25/2023
This is a private helper function to deh:find-highest. It starts with the head, which is only one word, but runs a deh:postag-andSearch on it. If it matches, then it gets returned, but if the sequence is empty, it passes the results of the deh:return-children function back into deh:proc-highest, with the other args remaining the same.

$postag-search: A set of POS tag search parameters, like ("comparative", "nominative", "plural")
$element: A set of <word/> elements, can be one or several.
$postags: Just the deh:postags function, every time

:)
declare %private function deh:proc-highest($postag-search as item()*, $elements as element()*, $postags)
{
  let $results := 
    for $element in $elements
    return if (deh:word-postag($postag-search, $element, $postags) eq true()) then
        $element
    else (
      
    )
  return if (fn:count($elements) eq 0) then
  (
  )
  else if (fn:count($results) gt 0) then
    $results
  else (
    deh:proc-highest($postag-search, deh:return-children($elements), $postags)
  )
};

(:
6/25/2023:

Depends on:
:)

(:
7/3/2023:
Takes a single element from a document, and finds its author, work name, and place, and returns it in a sequence in that order
:)
declare function deh:ldt2.1-workinfo($word as element())
{
  ($word/ancestor::treebank//author/text(), $word/ancestor::treebank//title/text(), $word/../fn:string(@subdoc)) 
};
(:----------------------------------------------------------------------------------------------------------------------
START OF corpus.csv FUNCTIONS
:)

(: Currently used in the csv test.xq file, in the future should be used to help in another function to return work and author information from the corpus.csv file. In the future, figure out how MyCapytains works.:)
declare function deh:clip-urns($seq as item()*) as item()*
{
  for $entry in $seq/csv/record/File
  return deh:clip-urn($entry/text())
};

(: Removes anything before "urn..." and maybe removes anything at "-lat1" or later:)
declare function deh:clip-urn($entry as xs:string) as xs:string
{
  
  let $urn-start := functx:index-of-string($entry, "urn")
  let $string := fn:substring($entry, $urn-start, (fn:string-length($entry) - $urn-start))
  
  return if (fn:contains($string, "-lat")) then
  fn:substring-before($string, "-lat")
  else (
    $string
  )
};


(:
Depends on:
deh:clip-urns

This function uses the "corpus.csv" file from Lasciva Roma (Currently at the path */Documents/2023 Summer/Thesis/NLP DB/corpus.csv) to get the title of a work which is stored as a CTS:URN in the $name var
:)
declare function deh:work-info-fromcsv($urn as xs:string) as item()*
{
  (:Do this directly here, it will make this easier to deal with:)
  let $options := map{'separator': 'comma', 'header': 'yes'}
  let $seq := csv:doc("C:/Users/T470s/Documents/2023 Summer/Thesis/NLP DB/corpus.csv", $options)
  
  (:This ensures the urn is appropriately formatted:)
  let $processed := deh:clip-urn($urn)
  let $check-title := deh:clip-urns($seq)
  let $index := fn:index-of($check-title, $processed)
  return $seq/csv/record[$index]
};
