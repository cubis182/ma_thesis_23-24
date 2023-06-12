xquery version "3.1";

module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A";

import module namespace functx = "http://www.functx.com" at "http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq";

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
declare function deh:word-postag($search as item()*, $word as node()*, $postags as item()*)
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
      
    )
};


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
This function takes an sequence of fully written-out strings ($search) which are specified in the $postags var in AGLDT Search Test.xq. The second argument is a document which the function can check. $postags is essentially the "deh:postags()" function :)
declare %public function deh:postag-andSearch($search as item()*, $doc as node(), $postags as item()*) as item()*
{
  (:Loop through every word in the document:)
  for $word in $doc//sentence/word
    (:I made the below FLWOR statement a variable so it does not return the same word more than once:)
    let $results := deh:word-postag($search, $word, $postags)
    return if ($results) then
    $word
    else ()
};
(:
5/19/2023:
Currently overhauling this function: it should take 5 arguments:
$search is a sequence of strings with the full names of the parts of the postag you wish to search
$relation is a single string, should at least partially match the relation you are looking for, does NOT use the expanded version of the relation names. THIS SHOULD ALLOW FOR AN EMPTY STRING, which should indicate a match in any scenario (for the fn:contains function will give a positive result with an empty string)
$lemma is the same, it will only check if the word's lemma CONTAINS the search string
$doc is the SINGLE treebank you wish to search.
$postags is the output of the deh:postags() function

LIMITATIONS REMAIN: How to search for multiple things at once? (All perfect passives AND perfect actives together, for example?), or how this can easily feed into the dependency determining functions. ALSO, we should re-implement the deh:mark-node function, so we have a better handle on these results when exporting them to CSV

Relies on:
deh:word-postag(3 args)
deh:relations()
deh:postag-andSearch
:)
declare %public function deh:search($postag as item()*, $relation as xs:string, $lemma as xs:string, $doc as node(), $postags) 
{
  (: This first statement runs if :)
  if (fn:count($postag) gt 0) then ( deh:test-rel-lemma(deh:postag-andSearch($postag, $doc, $postags), $relation, $lemma))
  else (deh:test-rel-lemma($doc//word, $relation, $lemma)) 
};

(:
5/19/2023:
This function is a helper function to deh:search; it takes $relation and $lemma from that functions arguments directly, and ONLY in that circumstance; the $words var is just a set of <word></word> nodes; it could be from the results of a different search, or could be a whole document, but it MUST only be those nodes
:)
declare %private function deh:test-rel-lemma($words as element()*, $relation as xs:string, $lemma as xs:string) as element()*
{
  for $word in $words[fn:contains(fn:string(@relation), $relation) eq true()]
  return $word[fn:contains(fn:string(@lemma), $lemma) eq true()]
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

(: Winter Break 2022-23 Phase :)
(: Adds attributes to the node with the path of the document and the node's sentence id. Only do this at the end of the process (when spitting out results) and this function is private because it does not check for the type of node :)
declare %private function deh:mark-node($nodes as element(*)*) as element()*
{
  for $node in $nodes
  return functx:add-attributes(functx:add-attributes($node, xs:QName("deh-docpath"), fn:replace(xs:string(fn:base-uri($node)), "%20", " ")), xs:QName("deh-sen-id"), $node/../@id/fn:string())
  
};

(: Winter Break 2022-23 Phase :)
(: Change the confusing terms later: this works either way:)
declare %private function deh:process-pairs($original-dependents as element()*, $processed-dependents as element()*, $original-heads as element()*, $processed-heads as element()*) as element()*
{
  for $first-node at $n in $original-heads
  where functx:index-of-node($processed-heads, $first-node) gt 0
  let $return := 
    for $second-node in $processed-dependents
    where functx:index-of-node($original-dependents, $second-node) gt 0
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
declare %public function deh:parent-return-pairs($dependents as element()*, $heads as element()*) as element()*
{
  
  let $parents := deh:return-parent($dependents)
  for $node in $heads
  where functx:index-of-node($parents, $node) gt 0
  let $childReturn := 
    let $children := deh:return-children($node)
    for $child in $children
    where functx:index-of-node($dependents, $child) gt 0
    return $child
  return 
  <parent-return-pair>
    {deh:mark-node($childReturn)}
    {deh:mark-node($node)}
  </parent-return-pair>
  
};

(: Winter Break 2022-23 Phase :)
(: Returns a list of the WORD (AGLDT) parents of each word. :)
declare %private function deh:return-parent($nodes as element()*) as element()*
{
  for $node in $nodes
  return $node/../word[@id eq $node/@head]
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) children:)
declare %private function deh:return-children($nodes as element()*) as element()*
{
  for $node in $nodes
  return $node/../word[@head eq $node/@id]
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) ancestors from bottom-up, in order:)
declare %private function deh:return-ancestors($nodes as element()*) as element()*
{
  for $node in $nodes
    let $parent := deh:return-parent($node)
    return ($parent, deh:return-ancestors($parent))
    
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) descendants, going branch-by-branch, it will fill out each left-to-right:)
declare %public function deh:return-descendants($nodes as element()*) as element()*
{
  for $node in $nodes
    let $children := deh:return-children($node)
    for $child in $children
      return ($child, deh:return-descendants($child))
};

(: Winter Break 2022-23 Phase :)
declare %private function deh:return-siblings($nodes as element()*) as element()*
{
  for $node in $nodes
    return $node/../word[@head eq $node/@head][@id ne $node/@id] (: This second condition to make sure the word itself is not repeated:)
};

(: 
5/18/2023:
$head-terms is a sequence of strings which has search terms, $children-terms another set of string search terms (both in accordance with the deh:word-postag and deh:postag-andSearch functions), the $depth is what level of children (1 is a child, 2 is a grandchild, 3 a great-grandchilde, MAX IS 4); A VALUE OF 0 DEALS WITH ALL DESCENDANTS)

hängt ab von:
deh:word-postag
deh:postags()
:)
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
