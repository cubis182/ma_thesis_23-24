xquery version "3.1";

module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A";

import module namespace functx = "http://www.functx.com" at "C:/Program Files (x86)/BaseX/src/functx_lib.xqm";
(:Backup for functx when the internet is crap: C:/Program Files (x86)/BaseX/src/functx_lib.xqm :)

(:
5/18/2023: 
This function takes the TAGSET.xml from the dependency treebank and returns a sequence, which has the possible postags in order; it does the same from PROIEL-TAGSET.xml in the repository, which I copied from the PROIEL treebank caes-gall.xml. I did this so both would be able to pull the tagset without an example node

$example-node: A string, either "ldt" or "proiel", depending on the chosen treebank
--------OBSOLETE NOTES BELOW-----------
Function to test whether a postag matches search terms (5/18/2023: I have repurposed this temporarily, old arg list was ($search as item()*, $postag as xs:string) as xs:boolean). The tagset.xml from the GitHub treebank master must be in the same directory as this file; IN THE FUTURE, this should pull straight from the internet:)
declare %public function deh:postags($treebank) as item()* (:7/22/2023: removed the type declaration for $example-node, I want it to be possible to pass an empty sequence :)
{
  let $tagset := doc("TAGSET.xml")
  let $proiel-tagset := doc("PROIEL-TAGSET.xml")
  return if ($treebank = "ldt") then 
  (
    for $postag in $tagset//attributes/*
    return map:merge(for $tag in $postag/values/* return map{$tag/postag/text():$tag/long/text()}) (:for each postag position, return a map with all the values for each possibility (so, under <pos/>, you have noun, adj, adv, conj, prep, pron, excl, verb, nrl, punct, irreg, which each has a 'long' and 'postag' value:)
    
) (:Get each part of the tag in order (pos, person, number, tense, mood, voice, gender, case, degree):)
  else if ($treebank = "proiel") then 
  (
    let $postag := $proiel-tagset/annotation/morphology/field
    for $tag in $postag
    return map:merge(for $value in $tag/value return map{$value/fn:string(@tag):$value/fn:string(@summary)})
  )
  else ()
};

(:
deh:get-postags
7/30/2023

Returns the postags in text format, from LDT or PROIEL (although you must supply the postag set), for a given word
:)
declare function deh:get-postags($tokens as element()*, $postags as item()*)
{
   for $token in $tokens
   return if ($token/name() = 'token') then (
     for $char at $n in functx:chars($token/fn:string(@morphology))
     return $postags[$n]($char)
   )
   else if ($token/name() = 'word') then (
     for $char at $n in functx:chars($token/fn:string(@postag))
     return $postags[$n]($char)
   )
};

(:
7/3/2023
This function, by the end of the project, should be able to take any treebank XML document and spit out its URN. The ideal scenario is the whole URN starting from "urn" and ending with the end of the work title, say, "phi001" being an example. This needs to be able to match up with the URN as it is in the Perseus catalogue, from which I will draw this info.

The return value will be a string with the author and work title all in one.

$doc: A single LDT (normal or Harrington) tree!
:)

(:--------------------------START NAMES/URNS SECTION------------------------------:)

declare function deh:cts-urn($doc as node()*)
{
  let $xml := doc(fn:base-uri($doc)) (:This should make sure we start with the full document, no matter what:)
  return if ($xml/*/name() eq "treebank") then ( (:Only if it is LDT for this:)
      let $id := $xml//sentence[1]/fn:string(@document_id) (:The urn is usually in the sentences, although it can be found elsewhere too:)
      return if (fn:contains($id, "urn")) then (
        let $end := (functx:index-of-string($id, ".pers")[1]) (:We have two jobs: cut off the end with all the ".perseus-lat1" stuff, and make sure the front is cut off:)
        let $urn-index := functx:index-of-string($id, "urn")
        let $final := fn:substring($id, $urn-index[fn:count(.)], ($end - $urn-index[fn:count(.)]))
        return if (fn:contains($final, "urn")) then ($final)
        else ()
    )
    else ("")
  )
  else if ($xml/*/name() = "proiel") then ("") (:PROIEL does not store the URN or a link to where I can get it....:)
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
  let $urn := deh:cts-urn($doc) 
  return if (fn:string-length($urn) > 0) then (
  let $html := html:parse(fetch:binary(fn:concat("https://catalog.perseus.org/catalog/", $urn))) (:Get the Perseus Catalog entry:)
  let $node := $html//h4[text() eq "Work Information"]/../dl (:Gets the bundle of work info:)
  let $work-info := $node/dd (:Get the nodes which contain the work info:)
  let $title := $work-info[2]
  let $author := $node//*[text() eq "Author:"]/following-sibling::dd[1]/a/text()
  return deh:return-info(fn:concat($title, ", "), $author) (:Updated 8/1/2023, now uses a function to ensure each array has two fields; whichever was empty is replaced with "UNK":)
)
else ()
};

(:
7/3/2023:
This function returns, for each of the supplied documents (whether one or more) one or more arrays with the title (plus possibly other additional info) and then the author. If either cannot be found, it will return "unknown"

$doc: One or more treebank documents (not nodes)
:)
declare function deh:work-info($doc as node()*)
{
  let $xml := $doc (:May remove this redundant step later; originally, this accepted nodes as well as documents:)
  return if ($xml/*/fn:string(@version) eq "2.1") then ( (:For the newer, 2.1 version of the official LDT:)
    let $words := $xml//sentence[1]//word (:Get some example words: perhaps an intermediate step, but I want to be call this with a whole document in the args:)
    return deh:ldt2.1-work-info($words[1]) 
  )  
  else if ($xml/*/fn:string(@version) eq "1.5") then ( (:For the older version (1.5) of the official LDT:)
    deh:info-from-html($xml)
  )
  else if ($xml/*/name() = "proiel" and $xml/*/fn:string(@schema-version) = "2.1") then (
    let $tokens := $xml//div[1]/sentence[1]//token
    return deh:proiel-work-info($tokens[1])
  )
};

(:
deh:token-info()
8/1/2023:

See deh:work-info desc for more details; this just works on individual words
:)
declare function deh:token-info($token as element()) as array(*)
{
  if ($token/ancestor::treebank/fn:string(@version) eq "2.1") then ( (:For the newer, 2.1 version of the official LDT:)
    deh:ldt2.1-work-info($token) 
  )  
  else if ($token/ancestor::treebank/fn:string(@version) eq "1.5") then ( (:For the older version (1.5) of the official LDT:)
    deh:info-from-html(doc(fn:base-uri($token))) (:Must pass the whole document without changing the function; but, since it is rare that this needs to happen, it is fine by me.:)
  )
  else if ($token/name() = "token" and $token/ancestor::proiel/fn:string(@schema-version) = "2.1") then (
    deh:proiel-work-info($token)
  )
};

(:
deh:proiel-work-info()
8/1/2023

Intended to compartmentalize the PROIEL work info retrieval in deh:work-info

:)
declare function deh:proiel-work-info($token as element())
{
    let $title := fn:string($token/ancestor::proiel//source/title/text())
    let $author := fn:string($token//ancestor::proiel/source/author/text())
    return deh:return-info($title, $author)
};

(:
deh:ldt2.1-work-info()
8/1/2023

:)
declare function deh:ldt2.1-work-info($word as element()) as array(*)
{
  let $title := fn:concat($word/ancestor::treebank//title/text(), " ", $word/ancestor::treebank//biblScope/text())
  let $author := $word/ancestor::treebank//author/text()
  return deh:return-info($title, $author)
};

(:
deh:return-info()
8/1/2023

Helper function to the set of work-info functions, only completes one small part of the process: it takes the given values, and will replace one with "UNK" if it is empty
:)
declare %public function deh:return-info($title, $author) as array(*)
{
  array{if (fn:string-length($title) > 0) then ($title) else ("UNK"), if (fn:string-length($author) > 0) then ($author) else ("UNK")}
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


$search: A set of POS tag search parameters, like ("comparative", "nominative", "plural"); can also be a single, lone string. If a negative search term, add '!' (without quotes, of course) to the very front, AND ONLY TO THE VERY FRONT, since deh:word-postag will remove the first character without looking.
$doc: A treebank, like "C:\Users\T470s\Documents\2023 Spring Semester\Latin Dependency Treebank (AGLDT)\vulgate.xml"
$postags: Just the deh:postags function, every time; in this case, usually passed from a parent function

Depends on:
deh:andSearch-handler()
:)
(:
declare %private function deh:postag-andSearch($search as item()*, $doc, $postags as item()*) as item()*
{
  let $tokens := deh:tokens-from-unk($doc) (:function added 7/12/2023 to handle extracting just the sequence of tokens:)
  return deh:andSearch-handler($search, $tokens, $postags)
};
:)

(:
6/27/2023:
This function is a helper function to deh:postag-andSearch. I wanted to be able to pass a series of <word/> elements, which were already pulled by a search (that is, if I find a list of every word descendant on a PRED, )

$search: Same as described in deh:search()
$words: a sequence of words/tokens ONLY
$postags: the output of the deh:postags() function

Depends on:
deh:word-postag()

:)
declare %private function deh:andSearch-handler($search as item()*, $words as element()*, $postags as item()*) as item()*
{
  (:Loop through every word in the document:)
  for $word in $words (:This function is private BECAUSE we assume $doc is a series of individual <word/> elements:)
    (:I made the below FLWOR statement a variable so it does not return the same word more than once:)
    let $results := deh:word-postag($search, $word, $postags)
    return if ($results) then
    $word
    else ()
};

(:-----------------------------------START deh:word-postag() AND DEPENDENCIES-----------------------------------------:)

(:
Spring 2023 Phase:
THIS IS WHERE THE CHEESE IS MADE (7/17/23: well, not anymore, really it is deh:test-postag() now), the search functionality really hinges on this.
This function is meant as a helper function to the deh:postag-andSearch (in that it does all the actual searching, the deh:postag-andSearch really only chooses to return or discard what this function approves or disapproves of, respectively). It is also used elsewhere, though. What it does is go through each position in the postag, and wherever it finds a positive result, it returns true() in a sequence. If the sequence holds the same number of "true()s" as there are search terms, we return a true() value, and false() if not.

Updated 7/17/2023: 
This now needs to work with LDT and PROIEL; this will search either LDT's word/@postag attribute or PROIEL's token/@morphology attribute, since they work in similar ways. Both sets of attributes are retrieved from the deh:postags() function, which should already be passed through the $postags arg.

$search: A set of POS tag search parameters, like ("comparative", "nominative", "plural"). If a negative search term, add '!' (without quotes, of course) to the very front, AND ONLY TO THE VERY FRONT, since deh:word-postag will remove the first character without looking.
$word: A single word node from an LDT treebank
$postags: Just the deh:postags function, every time, usually passed from a previous function; remember that this now can retrieve either PROIEL or LDT postags



Depends on:
deh:remove-excl()
deh:normalize-terms
deh:test-postag
:)
declare function deh:word-postag($search as item()*, $word as element(), $postags as item()*) as xs:boolean
{
  (:Separate the negative search terms (the ones we don't want, fronted with '!' (without quotes) from the positive ones, without the '!'. This also removes the '!' from the search term, since they are now differentiated:)
  let $neg-terms := deh:remove-excl(for $str in $search where fn:contains($str, "!") return $str)
  let $pos-terms := for $str in $search where (fn:contains($str, "!") != true()) return $str
  
  let $negs := deh:normalize-terms($neg-terms, $postags) (:Added this to make sure we are not checking against an incompatible term (i.e., we put "noun" in the search terms, but the current word is a PROIEL one):)
  let $poss := deh:normalize-terms($pos-terms, $postags)
  
  let $postag := 
    if ($word/name() = "word") then ($word/fn:string(@postag))
    else if ($word/name() = "token") then ($word/fn:string(@morphology))
    else ()
  (:Deal with search results here; we see how many of the search terms match the neg parameters, and how many match the positive parameters, passing the word/token element's postag, and :)
  let $neg-trues := deh:test-postag($negs, $postag, $postags)
  let $pos-trues := deh:test-postag($poss, $postag, $postags)
  
  return if ((fn:count($neg-trues[. > 0]) = 0) and (fn:count($pos-trues[. > 0]) = fn:count($poss)) and (fn:count($pos-trues[. > 0]) > 0 or (deh:contains-proiel-pos($search)))) then (true()) (:7/24/2023: Added a third condition, so that we only return a positive result if there is more than one search match, not just if the number of positive terms matches the expected number (which of course would be 0 and 0:)
  else (false())
};

declare %public function deh:contains-proiel-pos($postag as item()*) as xs:boolean
{
  let $tags :=
    for $item in $postag
    where functx:contains-any-of($item, deh:get-proiel-pos())
    return $item
  return if (fn:count($tags) > 0) then (true())
  else (false())
};

(:
deh:normalize-terms (private)
Summer 2023 Phase:

Because I am updating deh:search so it can take both treebanks at once, if I have given a search term only compatible with the other treebank, the one not being currently searched, I want it removed. A helper function to deh:word-postag

$terms: 0 or more strings submitted in the "postag" sequence in deh:search or deh:query;
$postags: The supplied postags for a given treebank, from deh:postags()
:)
declare %private function deh:normalize-terms($terms as item()*, $postags)
{
  for $term in $terms
  where fn:index-of((for $map in $postags return $map?*), $term) > 0 (:These parentheses SHOULD return all the supplied postags:)
    return $term
};

(:

:)

(:
deh:test-postag
7/17/2023:

:)
declare %public function deh:test-postag($search as item()*, $tag as xs:string, $postags as item()*) as xs:integer*
{
  (:I made the below FLWOR statement a variable so it does not return the same word more than once:)
  if (fn:count($search) = 0) then (0)
  else (
      for $char at $n in functx:chars(fn:string($tag))
      return if ($postags[$n](xs:string($char)) = $search) then (1)
      else (-1)
    )
};

(:
deh:remove-excl()
7/17/2023:
This function is used in the deh:word-postag() function, and helps it out by removing the '!' from postag search terms

$terms: A sequence of strings (or could be a null sequence, even, or a single string) which we need to remove '!' from.
:)
declare %private function deh:remove-excl($terms as item()*) as item()*
{
  for $str in $terms
  return fn:substring($str, 2)
};

(:-----------------------------------END deh:word-postag() AND DEPENDENCIES-------------------------------------------:)

(:
7/22/2023: NOTE, THIS ONLY SUPPORTS PROIEL OR LDT
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

$search is a sequence of strings (or just a single string if only one search term) with the full names of the parts of the postag you wish to search. If a negative search term, add '!' (without quotes, of course) to the very front, AND ONLY TO THE VERY FRONT, since deh:word-postag will remove the first character without looking. Just put an empty sequence if you don't need to use this parameter.
$relation is an empty string, empty sequence, single string, or sequence of strings, which should at least partially match the relation you are looking for, does NOT use the expanded version of the relation names. THIS SHOULD ALLOW FOR AN EMPTY STRING, which should indicate a match in any scenario (for the fn:contains function will give a positive result with an empty string. It also, as of 7/3/2023, is not case-sensitive). Can be made a negative search (i.e., searches for every example WITHOUT the specified relation), but make sure to append the '!' (without quotes) to the start of the search term. 
$lemma:  is an empty string, empty sequence, single string, or sequence of strings, which you want to use to search for the lemma. Now uses, unlike $relation (may change later), fn:matches for the search, which means it accepts regular expression notation and you can be more precise in exact matches. Still accepts an empty string if lemmas is not a desirable part of the search. Is not case sensitive. Can make it a negative search (i.e., search for every example which does NOT have the lemma), but MAKE SURE THE '!' (WITHOUT QUOTES) IS APPENDED TO THE VERY START OF THE REGEX
$doc is the SINGLE treebank you wish to search, or a set of <word/> elements
$postags is the output of the deh:postags() function

LIMITATIONS REMAIN: How to search for multiple things at once? (All perfect passives AND perfect actives together, for example?), or how this can easily feed into the dependency determining functions. ALSO, we should re-implement the deh:mark-node function, so we have a better handle on these results when exporting them to CSV

Relies on:
deh:word-postag(3 args)
deh:relations()
deh:postag-andSearch
deh:test-rel-lemma
:)
declare %public function deh:search($postag as item()*, $relation as item()*, $lemma as item()*, $doc) 
{
  let $tokens := deh:tokens-from-unk($doc)
  let $pr := $tokens[name() = "token"]
  let $ldt := $tokens[name() = "word"]
  
  return (deh:search-execute($postag, deh:align-relation($relation, $ldt[1]), $lemma, $ldt, deh:postags("ldt")), deh:search-execute($postag, deh:align-relation($relation, $pr[1]), $lemma, $pr (:this is a good spot to put a function to search the PROIEL part-of-speech field:), deh:postags("proiel"))) (:7/23/2023: added deh:align-relation, to make sure only relevant @relation search terms are passed to each function:)
};

(:
deh:search-execute()
7/22/2023

This function does what the deh:search function used to do, except the deh:search function now separates the LDT and PROIEL tokens and passes each to this.

Depends on:
deh:word-postag(3 args)
deh:relations()
deh:postag-andSearch
deh:test-rel-lemma
:)
declare %private function deh:search-execute($postag as item()*, $relation as item()*, $lemma as item()*, $doc, $postags)
{
  let $tokens := deh:tokens-from-unk($doc) (:7/22/23: no need to do this in subordinate functions, just do it once, here:)
  let $final-tokens := 
    if ($tokens[1]/name() = "word") then ($tokens)
    else if ($tokens[1]/name() = "token") then (deh:proiel-pos($postag, $tokens)) (:Added 7/24/2023:)
  (: This first statement runs if :)
  return if (fn:count($postag) gt 0 or $postag != "") then ( deh:test-rel-lemma(deh:andSearch-handler($postag, $final-tokens, $postags), $relation, $lemma))
  else (deh:test-rel-lemma($final-tokens, $relation, $lemma)) (:7/12/23: changed again, because the deh:tokens-from-unk now exists, which will return a sequence of tokens no matter whether a document is passed, or set of nodes, and does not depend on whether it is LDT or PROIEL:)
};

(:
deh:proiel-pos() (private)
7/24/2023:

Helper function to deh:search-execute, which returns only the PROIEL tokens which match POS search parameters set in the postag sequence.

$postags: confusingly, the $postag arg from deh:search-execute
$tokens: $tokens from deh:search-execute

:)
declare %public function deh:proiel-pos($postags as item()*, $tokens as element()*) as element()*
{
  let $pos-master := deh:get-proiel-pos()
  let $pos-terms := 
    for $term in $postags
    where functx:contains-any-of($term, $pos-master)
    return $term
  return if (fn:count($pos-terms) > 0) then ($tokens[functx:contains-any-of(fn:string(@part-of-speech), $pos-terms)])
  else ($tokens)
};

(:
deh:get-proiel-pos() (private)
7/24/2023


:)
declare %public function deh:get-proiel-pos() as item()*
{
  doc("PROIEL-TAGSET.xml")//parts-of-speech/value/fn:string(@tag)
};

declare function deh:get-proiel-pos-map() as item()*
{
  let $maps :=
  for $item in doc("PROIEL-TAGSET.xml")//parts-of-speech/value
  return map{$item/fn:string(@tag):$item/fn:string(@summary)}
  return map:merge($maps)
};

(:
5/19/2023:
This function is a helper function to deh:search; it takes $relation and $lemma from that functions arguments directly, and ONLY in that circumstance; the $words var is just a set of <word></word> nodes; it could be from the results of a different search, or could be a whole document, but it MUST only be those nodes; the changes I made 6/27/2023 to the deh:search function should ensure that. As of 7/3/2023, this function is no longer case sensitive.

THIS IS WHERE THE CODE FOR TESTING THE LEMMA IS! ALSO NOTE, THIS IS ALREADY TOTALLY COMPATIBLE WITH PROIEL

$words: 7/23/23, changed so that it only accepts a series of elements (since deh:token-from-unk is now applied earlier, in deh:search-execute, which calls this funciton)
$relation: 0, 1 or more strings which we want to match with the words' relations (a partial match also works, so if we are looking for PRED, it will also return PRED_CO)
$lemma: 0, 1 or more strings wh
:)
declare %public function deh:test-rel-lemma($words as element()*, $relation as item()*, $lemma as item()*) 
{
  let $neg-rel := deh:remove-excl(for $term in $relation where fn:contains($term, "!") return $term) ! fn:lower-case(.) (:May be hard to parse, but this takes the negative terms, extracts them, makes that sequence lower case with a map, removes the exclamation point, and joins them into one string delimited by spaces:)
  let $pos-rel := (for $term in $relation where fn:contains($term, "!") = false() return $term) ! fn:lower-case(.)
  
  (:YES, I'M REPEATING CODE; FIX THIS LATER!!!!! PUT THIS INTO A FUNCTION OR SOMETHING:)
  let $pos-lemma := (for $term in $lemma where fn:contains($term, '!') = false() return $term) ! fn:lower-case(.)
  let $neg-lemma := deh:remove-excl(for $term in $lemma where fn:contains($term, '!') return $term) ! fn:lower-case(.)
  
  return $words[
    (deh:relation-match(fn:string(@relation), $pos-rel) gt -1)  (:Check if the relation is correct:)
    and
    (deh:relation-match(fn:string(@relation), $neg-rel) lt 1) (:Make sure it matches no negative terms:)
    and 
    (deh:lemma-match(fn:string(@lemma), $pos-lemma) gt -1)
    and
    (deh:lemma-match(fn:string(@lemma), $neg-lemma) lt 1)
]
};

(:
deh:lemma-match
7/23/2023:

This function tests whether a lemma matches one of a whole sequence of regular expressions; can be an empty sequence though! If the lemma matches any of the regular expressions, this function returns 1, if not, -1, and if there is no search term, 0

$lemma: a string, which is supposed to be the <word/> or <token/>'s @lemma attribute, made lower-case, and passed from the deh:test-rel-lemma function
$terms: A set of regular expressions, also passed from deh:test-rel-lemma, which the lemma needs to match at least one of


:)
declare %public function deh:lemma-match($lemma as xs:string, $terms as item()*) as xs:integer
{
  if (fn:count($terms) = 0 or $terms = "") then (0)
  else (
  let $bools := (:This returns true for every match; if it matches even one, we want to return true below, hence the way it works 4 lines down:)
    for $term in $terms
    where fn:matches(fn:lower-case($lemma), $term) (:8/13/2023: Updated so the lemma is made lower case too:)
    return true()
  return if ($bools[1]) then (1)
  else (-1)
)

};

(:
deh:relation-match
7/23/2023

This function helps the deh:test-rel-lemma function, in that it makes sure to return a positive match, or just return true() if the search string is empty. Same as deh:lemma-match, it returns 0 if there is no search term, 1 for a positive result, and -1 for a negative result

$relation: the string of the @relation attr. pulled directly from the word/token, 
$terms: A sequence of strings, each of which is a search term which needs to partially match the subject $relation
:)
declare %public function deh:relation-match($relation as xs:string, $terms as item()*) as xs:integer
{
  if (fn:count($terms) = 0 or $terms = "") then (0)
  else if (functx:contains-any-of(fn:lower-case($relation), $terms)) then (
    1
  )
  else (-1)
};

(:
deh:tokens-from-unk()
7/12/2023:

Deals with the issue of functions where I can pass either a document or the individual word-nodes; this function returns the full set of nodes, whether PROIEL or LDT, but cannot deal with any other format.

$tokens: either a document or series of nodes

Depends on:
:)
declare function deh:tokens-from-unk($tokens) as element()*
{
  if ($tokens[1]/name() = "token" or $tokens[1]/name() = "word") then ($tokens)
  else ($tokens//word, $tokens//token)
};

(:
deh:align-relation
7/23/2023

This function takes the set of relation parameters, and throws out any parameter not related to the chosen treebank. A private function, used in deh:search()

Depends on:
deh:get-rels()
:)
declare %public function deh:align-relation($relation as item()*, $tok as element()?) as item()*
{
  let $prop-rels := deh:get-rels($tok) (:The set of possible @relation 's for the given treebank':)
  for $term in $relation
  where functx:contains-any-of($term, $prop-rels)
  return $term
};

(:
deh:get-rels()
7/23/2023:

This function gets the list of @relation tags (as they appear in the document's attributes), based on an example treebank node.

$tok: A <word/> or <token/> passed from the deh:align-relation function, usually

Depends on:
:)
declare %private function deh:get-rels($tok as element()?)
{
  if ($tok/name() = 'word') then (
    let $tagset := doc("TAGSET.xml")
    return $tagset//relation//short/text()
  )
  else if ($tok/name() = 'token') then (
    $tok/ancestor::proiel//relations/value/fn:string(@tag)
  )
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
ONE LAST NOTE ON $a: You can leave out items you don't need, don't put a key for an empty slot; that is why deh:check-a-map() exists

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

$comment: Just a string with any commentary you want to add; it will go at the top of the results so, if you save it, you can leave a note for yourself later.
Notes:
Don't need a function yet for 

Depends on:
deh:results-to-csv
deh:check-rel-options() (private)
deh:check-a-map()
:)
declare %public function deh:query($a as map(*), $b as element()*, $a-to-b-rel as map(*), $options as map(*), $comment as xs:string)
{
  (:Have the default return options ready if no options are submitted:)
  let $def-options := map{
    "export":"xml"
  }
  let $xml-str := "xml" (:So we can change the strings in one place, here are the export modes:)
  let $csv-str := "csv"
  let $node-str := "node"
  let $bare-str := "bare"
  
  
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
  let $a := deh:check-a-map($a)
  let $search :=  deh:search($a("postag"), $a("relation"), $a("lemma"), $b-rels)
  return if (fn:count($search) gt 0) then (
    if ($options-final("export") eq $xml-str or $options-final("export") eq $node-str) then ( 
      <tree-search comment="{$comment}">
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
    else if ($options("export") eq $bare-str) then ( 
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
deh:check-a-map
7/23/2023:

This is a helper function to deh:query, which fills in empty fields in the $a map{}, to make the function easier to use (I want to be able to leave out empty fields)

$map: The parameters of $a from deh:query. Needs to have keys titled "postag", "relation", and "lemma"

Depends on:
:)
declare %public function deh:check-a-map($map as map(*)) as map(*)
{
  let $def := map{
    "postag":(),
    "relation":(),
    "lemma":()
  }
  return map:merge(($map, $def), map{"duplicates":"use-first"})
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
  
  (:7/23/2023: BIG UPDATE, realized I could do this with one function; just merge the $map argument with a default map, and use the merge option "use-first" to prefer the $map on any given item:)
  let $def := map{
    "width":0,
    "depth":0
  }
  return map:merge(($map, $def), map{"duplicates":"use-first"})
};

(:-------------------------END deh:query AND DEPENDENCIES------------------------------------------:)

(:---------------------------END deh:postag-andSearch AND DEPENDENCIES/OTHER SEARCH TOOLS------------------------------:)

(:---------------------------START QUOTE PROCESSING FUNCTIONS------------------------------:)
(:
Section Catalog:
deh:pr-extract-quotes: will be obsolete, but it looks for spans of tokens starting after a token whose @presentation-after attribute has a quote in it and ending with a token which has a @presentation-after quote. This came before I even noticed @presentation-before, but since the annotation is inconsistent anyway, this will likely never help.
deh:extract-quotes: this function will take every punctuation node with a quote OR whose @presentation-before/@presentation-after has a quote, making this a cross-treebank compatible function.
:)
(:
SECTION DECLARATION:
This section is where the set of quote processing functions live. Any function prefixed with 'pr' is for PROIEL, and 'ldt' is the Latin Dependency Treebank. PROIEL is a little less trivial, since punctuation is inconsistent and kept in the @presentation-after.
:)

(:
deh:pr-extract-quotes()
8/20/2023

This function accepts any full treebank or a portion and extracts the nodes in sets; a set of nodes between quotes will be kept together in a sequence, and packed into an array.

$elements: Either a treebank document or portion of a treebank document. 
:)
declare function deh:pr-extract-quotes($elements) as array(*)
{
  let $tokens := deh:tokens-from-unk($elements)
  let $quotes :=  ("'", "&quot;", "”", "“")
  return array {for tumbling window $w in $tokens
    start $s at $n-start when $tokens[$n-start - 1][functx:contains-any-of(fn:string(@presentation-after), $quotes)]
    end $e at $n-end when $e[functx:contains-any-of(fn:string(@presentation-after),$quotes)]
  return array{$w}}
};

(:
deh:extract-quotes()
8/30/2023

 this function will take every punctuation node with a quote OR whose @presentation-before/@presentation-after has a quote, making this a cross-treebank compatible function.
 
$doc-or-tok: A treebank document or documents or <word/>/<token/> elements, from LDT or PROIEL respectively

:)
declare function deh:extract-quotes($doc-or-tok) as item()*
{
  let $tokens := deh:tokens-from-unk($doc-or-tok)
  let $quotes := ("'", "&quot;", "”", "“")
  let $ldt-lemmas := ("QUOTE1", "double", "quote1", "QUOTE'", "'", "quote", "punc1", "unknown", "punc", "question", " ") (:Based on blue notebook notes:)
  let $ldt := $tokens[functx:contains-any-of(fn:string(@form), $quotes) and functx:contains-any-of(fn:string(@lemma), $ldt-lemmas)]
  let $pr := $tokens[name() = "token"]
  let $pr-results := $pr[functx:contains-any-of(fn:string(@presentation-before), $quotes) or functx:contains-any-of(fn:string(@presentation-after), $quotes)]
  return ($ldt, $pr-results)
};




(:---------------------------END QUOTE PROCESSING FUNCTIONS--------------------------------:)



(: Winter Break 2022-23 Phase :)
(: Adds attributes to the node with the path of the document, s Only do this at the end of the process (when spitting out results) and (6/25/2023) IGNORE THE FOLLOWING: (this function is private because it does not check for the type of node) INSTEAD, I made this public because it can be used optionally that way. Instead, it simply ignores nodes which are not "words"

7/3/2023: because of deh:ldt2.1-workinfo, this currently is incompatible with any other format

Depends on:
deh:ldt2.1-workinfo
:)
declare function deh:mark-node($nodes as element(*)*) as element()*
{  
  let $source-docs := fn:distinct-values(for $node in $nodes return fn:base-uri($node))
  let $work-info := map:merge(for $uri in $source-docs return map{$uri : deh:work-info(doc($uri))})
  for $node in $nodes
  let $subdoc := deh:subdoc($node)
  let $node := functx:add-attributes(functx:add-attributes(functx:add-attributes(functx:add-attributes($node, xs:QName("base-uri"), fn:base-uri($node)), xs:QName("deh-title"), $work-info(fn:base-uri($node))(1)), xs:QName("deh-author"), $work-info(fn:base-uri($node))(2)), xs:QName("deh-sen-id"), $node/../@id/fn:string())
  return functx:add-or-update-attributes($node, xs:QName("citation-part"), $subdoc)
};

(:
deh:subdoc()
8/2/2023:

This function takes an element (token) from either LDT or PROIEL and get the @subdoc (usually kept on the <sentence/> element in LDT) or @citation-part (kept on each <token/> in PROIEL)

$token: A single node
:)
declare function deh:subdoc($token as element()) as xs:string
{
   if ($token/name() = 'word') then ($token/../fn:string(@subdoc)) else if ($token/name() = 'token') then ($token/fn:string(@citation-part))
};

(:
deh:cite-range()
8/1/2023:

A function I am workshopping to return a whole range of citations from a citation with a dash. LDT luckily puts the full citation on each side of the dash (i.e. 13.463-13.465), so there is not guesswork involved, although I did not check every single example; since PROIEL gives a citation on every word, there are no dashes, so this function is not necessary there. THIS FUNCTION WILL ALSO SPIT OUT STRINGS WITH NO HYPHENS, so this can be used on any string.
:)
declare function deh:cite-range($range as xs:string) as item()*
{
  let $dash-index := functx:index-of-string($range, '-') (:Place in the string of the dash:)
    return if (fn:count($dash-index) != 0) then (
    let $str1 := fn:substring($range, 1, $dash-index - 1) (:Get the citation to the left of the dash:)
    let $str2 := fn:substring($range, $dash-index + 1) (:And get the citation to the right:)
    let $str1-dot := functx:index-of-string($str1, '.')(:Get the location of the '.' in the left citation:)
    let $str2-dot := functx:index-of-string($str2, '.')(:Get the location of the '.' in the right citation:)
    let $str1-val := fn:substring($str1, $str1-dot[fn:count($str1-dot)] + 1) (:Get the info in the left citation from after the last dot:)
    let $str1-prefix := fn:substring($str1, 1, $str1-dot[fn:count($str1-dot)] - 1) (:Get the info in the right citation from after the last dot:)
    let $str2-val := fn:substring($str2, $str2-dot[fn:count($str2-dot)] + 1) (:See just above:)
    let $str2-prefix := fn:substring($str2, 1, $str2-dot[fn:count($str2-dot)] - 1)
    for $val in xs:integer($str1-val) to xs:integer($str2-val)
    return fn:concat($str1-prefix, ".", $val)
  )
  else ($range)
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
Now has a second argument $width. This allows you to return all the siblings of the parent.
7/21/2023: Added PROIEL compatibility

Depends on:
deh:check-head
 :)
declare %public function deh:return-parent($nodes as element()*, $width as xs:integer) as element()*
{
  for $node in $nodes
  return if ($width eq 0) then
  $node/../*[@id eq deh:check-head($node)]
  else (
    deh:return-siblings($node/../word[@id eq deh:check-head($node)], true())
  )
};

(:
deh:check-head
7/21/2023:
Returns the head id, whether it is an LDT or PROIEL tree
:)
declare %private function deh:check-head($word as element())
{
  if ($word/name() = 'word') then ($word/@head)
  else if ($word/name() = 'token') then ($word/@head-id)
  else ()
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) children
7/21/2023: Updated to be compatible with PROIEL

Depends on:
deh:check-head
:)
declare %public function deh:return-children($nodes as element()*) as element()*
{
  for $node in $nodes
  return $node/../*[deh:check-head(.) eq $node/@id]
};

(: Winter Break 2022-23 Phase :)
(: Returns all the WORD (AGLDT) ancestors from bottom-up, in order
7/4/2023: Added these args:
$depth: A number; if 0, just gets each parent by each parent one at a time; if not, it is the number of times we travel back up the tree
$width: whether or not we apply the deh:return-siblings function to the results

7/21/2023: Added PROIEL compatibility to its dependent functions

Depends on:
deh:return-parent
deh:return-siblings
:)
declare function deh:return-ancestors($nodes as element()*, $depth as xs:integer, $width as xs:integer) as element()*
{
  if ($depth eq 0) then ( (:If depth is 0, just do the default thing:) 
  for $node in $nodes
    let $parent := deh:return-parent($node, 0)
    return if ($width eq 0) then ($parent, deh:return-ancestors($parent, $depth, $width)) (:Still must account for width: if 0, don't give siblings:)
    else if ($width eq 1) then (deh:return-siblings(($parent, deh:return-ancestors($parent, $depth, $width)), true())) (: If 1, return the siblings of each result:)
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

7/21/2023: Added PROIEL compatibility

Depends on:
deh:check-head
 :)
declare function deh:return-siblings($nodes as element()*, $include as xs:boolean) as element()*
{
  for $node in $nodes
    let $final := $node/../*[deh:check-head(.) eq deh:check-head($node)]
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

7/21/2023: Added PROIEL compatibility with deh:check-head

Depends on:
deh:proc-highest (private, made for this function to handle looping through each level of the sentence)
deh:postag-andSearch
deh:check-head
:)
declare function deh:find-highest($postag-search as item()*, $doc as node()*, $postags)
{
  for $sent in $doc//sentence
    let $head := $sent/*[fn:number(deh:check-head(.)) eq 0]
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

(:--------------------------------START random--------------------------------------------:)

(:
deh:pick-random($seq as item()*)
9/3/2023

This function picks one or more random values from a sequence; specify the number you want with $iter. It will return distinct values, or in other words it makes sure to retrieve no duplicates from the given sequence.

$seq: A $seq of any length and any item
$iter: Number of random items to retrieve (can't be 0, of course)

Depends on:
deh:proc-random
:)
declare function deh:pick-random($seq as item()*, $iter as xs:integer) 
{
  for $i in deh:proc-random((), fn:count($seq), $iter, 0)
  return $seq[$i]
};

(:

$rand: At first iteration, must be an empty sequence
$leng-total: length of the sequence we are drawing random values from
$start: must be 0
:)
declare %private function deh:proc-random($rand as item()*, $leng-total as xs:integer, $iter as xs:integer, $start as xs:integer)
{
  let $rand-val := (random:integer($leng-total) + 1)
  return if ($start = $iter) then ($rand)
  else if (fn:index-of($rand, $rand-val) > 0) then (deh:proc-random($rand, $leng-total, $iter, $start))
  else (deh:proc-random(($rand, $rand-val), $leng-total, $iter, ($start + 1)))
};

(:--------------------------------END random--------------------------------------------:)
