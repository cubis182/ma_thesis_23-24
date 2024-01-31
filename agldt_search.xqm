xquery version "4.0";

(:NOTE THAT, FOR THE BASEX IMPLEMENTATION, SET WRITEBACK true IS NECESSARY FOR THIS TO WORK:)

module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A";

import module namespace stats = "ma-thesis-23-24" at "stats.xqm";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";
(:Backup for functx when the internet is crap: C:/Program Files (x86)/BaseX/src/functx_lib.xqm 
  http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

(:PRED:)
(:SBJ
$sbj := ("N-SUBJ", "A-SUBJ")
:)
(:OBJ
$obj := ("D-IO", "A-INTOBJ", "A-PRED", "D-INTER", "D-REFER", "AB-RESPECT", "D-AGENT", "AB-AGENT")
:)
(:ATR
$atr := ("G-POSS", "G-PART", "G-OBJEC", "G-DESC", "G-CHAR", "G-MATER", "D-REFER", "AB-ORIENT", "AB-SEPAR", "AB-CAUSE", "AB-LOCAT", "AB-RESPECT", "AB-ACCOMP", "AB-DESCRIP") (:Not sure what to do with G-VALUE or G-CHARGE, since those are more adverbial and not adnominal:)
:)
(:ADV
$adv := ("D-INTER", "D-POSS", "D-AGENT", "D-Purp", "A-ORIENT", "A-EXTENT", "A-RESPECT", "A-ADVERB", "D-PURP", "AB-ORIENT", "AB-SEPAR", "AB-CAUSE", "AB-ABSOL", "AB-COMPAR", "AB-LOCAT", "AB-ACCOMP", "AB-MEANS", "AB-MANN") (:10/15, STOPPED AT A-RESPECT! 11/1, WHICH I THINK IT ADVERBIAL, it is rare, but was never ATR; YES, note the sentence: hic primum nigrantis terga iuvencos constituit, the terga is an ADV; also note that things like Ablative or Orientation are likely with prepositions, although I haven't checked; 11/7/23, NOT SURE HOW PRICE WORKS! Same with AB-DEGDIF, don't really care about it:)
:)
(:ATV/AtvV:)
(:PNOM
let $pnom := ("N-PRED")
:)

(:OCOMP:)
(:COORD:)
(:APOS:)
(:AuxP:)
(:AuxC:)
(:AuxR:)
(:AuxV:)
(:AuxX:)
(:AuxG:)
(:AuxK:)
(:AuxY:)
(:AuxZ:)
(:ExD
let $exd := ("A-EXCLAM") (:This does not cover every case; in the Met. example, it is an OBJ for being in direct speech, and AuxY seems to be used for other exclamations...:)
:)
(:
HARRINGTON TREES:
The section below has some sequences of strings relevant for dealing with Harrington trees, with a focus on what is equivalent in the LDT, for use with future functions.
:)



(:-------------------------------------------------------------------------------------------------:)

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
deh:remove-punct()
9/4/2023

This function removes any period, comma or semicolon from a string; you can add any other punctuation you want, too, I was just lazy today.

$str: A SINGLE string which you want to remove punctuation from.

:)
declare function deh:remove-punct($str as xs:string) as xs:string
{
  fn:replace($str, "[.,;]", "")
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
deh:lem()
9/8/2023

This function takes a string or sequence of strings to be used as a search term for a lemma and automatically adds the proper reg ex syntax to make the search work.

$str: A string or sequence of strings, usually a bare lemma; only reason this is necessary is because of the LDT's tendency to number different lemmas
:)
declare function deh:lem($str as item()*) as item()*
{
   for $item in $str
   return ("^" || $str || "?$")
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
    deh:info-from-urn($urn)
)
else ()
};

declare %public function deh:info-from-urn($urn as xs:string) as array(*)
{
  let $html := html:parse(fetch:binary(fn:concat("https://catalog.perseus.org/catalog/", $urn))) (:Get the Perseus Catalog entry:)
  let $node := $html//h4[text() eq "Work Information"]/../dl (:Gets the bundle of work info:)
  let $work-info := $node/dd (:Get the nodes which contain the work info:)
  let $title := $work-info[2]
  let $author := $node//*[text() eq "Author:"]/following-sibling::dd[1]/a/text()
  return deh:return-info(fn:concat($title, ", "), $author) (:Updated 8/1/2023, now uses a function to ensure each array has two fields; whichever was empty is replaced with "UNK":)
};

(:
7/3/2023:
This function returns, for each of the supplied documents (whether one or more) one or more arrays with the TITLE (plus possibly other additional info) and then the AUTHOR. If either cannot be found, the array will have a size of one and will only have the base uri, so you can use array:size() to check this.

$doc: One or more treebank documents (not nodes)
:)
declare function deh:work-info($doc as node()*) as array(*)
{
  let $tok := (deh:tokens-from-unk($doc))[1]
  return if ($tok/name() eq "word") then (
    deh:ldt2.1-work-info($tok) 
  )  
  else if ($tok/name() = "token") then (
    deh:proiel-work-info($tok)
  )
  else (array{fn:base-uri($tok)}) (:Added 10/18, because we want to make sure this never returns an empty sequence, but an array data type, because that is what we expect. Therefore, one way to test whether the results were successful or not is with the size; if it failed, the array will have a size of one and will only have the base uri:)
};

(:
deh:token-info()
8/1/2023:

See deh:work-info desc for more details; this just works on individual words
:)
declare function deh:token-info($token as element()) as array(*)
{
  if ($token/name() eq "word") then ( (:Updated 9/14/2023: now there is one requirement for all Perseus treebanks, since the Harrington and LDT trees are now aligned in work-info:)
    deh:ldt2.1-work-info($token) 
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

(:
deh:print()
9/15/2023:

$sents: sentence elements from either the LDT or PROIEL

:)
declare function deh:print($sents as element(sentence)*) (:9/25/23, changed arg from item()* to element(sentence)*:)
{
  for $sent in $sents
  return fn:string-join($sent/*/fn:string(@form), " ")
};

(:deh:print-phrase
1/11/2024

Prints every 
:)
declare function deh:print-phrase($nodes as node()*) as xs:string*
{
  for $tok in deh:tokens-from-unk($nodes) (:I don't see a case where I would ever want to do this, but I can pass whole sentences and such...:)
  return fn:string-join(
    (
      for $desc in functx:distinct-nodes(($tok, deh:return-descendants($tok))) 
      order by $desc/fn:number(@id) 
      return $desc/fn:string(@form)
    ), " ") => fn:replace("[^a-zA-Z ]", "")
};

(:
deh:print-rel()
9/25/2023:

Like print(), but also puts the @relation in parentheses after each word.


:)
declare function deh:print-rel($sents as element(sentence)*)
{
  for $sent in $sents
  let $words := for $tok in $sent/* return ($tok/fn:string(@form) || "(" || $tok/fn:string(@relation) || ")")
  return fn:string-join($words, " ")
};

(:
deh:print-relation()
9/15/2023


:)
declare function deh:print-relation($sents as item()*)
{
  
};

(: KINDA OBSOLETE, THERE IS LIKELY A BETTER WAY TO DO THIS... Winter Break 2022-23 Phase :)
(:IF YOU WANT TO UPDATE PUNCTUATION, COME HERE
This function takes a string, and returns true if it matches punctuation. This is meant to take the 
form of a word and check if it is punctuation so it does not get counted when checking sentence length. HOWEVER, THIS ONLY CHECKS WHETHER PUNCTUATION IS PRESENT, NOT WHETHER IT IS ONLY PUNCTUATION:)
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

(:1/7/2024
This function assumes a homogenous set: in some cases it only tests the first item in the sequence
:)
declare function deh:sents-from-unk($nodes as node()*) as element(sentence)*
{
  if ($nodes[1]/.. instance of element(sentence)) then (functx:distinct-nodes($nodes/..))
  else if ($nodes[1] instance of element(sentence)) then ($nodes)
  else (
    $nodes//sentence
  )
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

Dieses Funktion darf so operiert werden; Beispiele:

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
  (deh:return-descendants($nodes))
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

declare function deh:is-quote($tok as element()) as xs:boolean
{
  let $quotes := ("'", "&quot;", "”", "“")
  let $ldt-lemmas := ("QUOTE1", "double", "quote1", "QUOTE'", "'", "quote", "punc1", "unknown", "punc", "question", " ") (:Based on blue notebook notes:)
  return functx:contains-any-of($tok/fn:string(@form), $quotes) and functx:contains-any-of($tok/fn:string(@lemma), $ldt-lemmas)
};

(:Returns an sequence of arrays where each array begins with a quote and ends just before the next quote. This means the first part before the first quote in the tree is left out.:)
declare function deh:div-by-quotes($tree as node()*) as array(*)*
{
  let $windows :=
  for tumbling window $w in $tree//word
  start $s at $n when $s/deh:is-quote(.)
  return array{$w}
  return $windows[position() mod 2 = 1]
};

(:
Gets sentences with quotes included or excluded, based on the boolean passed to $non-speech (false returns dialogue)
:)
declare function deh:return-sentences-petr($windows as array(*)*, $non-speech as xs:boolean)
{
  let $toks := $windows?* (:Get all the individual nodes in a single speech:)
  
  (:This iterates through the nodes and returns them as grouped by sentence, not quotes:)
  let $sents :=
  for tumbling window $w in $toks
  start $s previous $s-prev when $s/../@id != $s-prev/../@id
  return array{$w}
  
  (:Now, we will return the sentences without any nodes not already pulled from speech:)
  for $sent in $sents
  let $full-sent := $sent?1/..
  let $ids := $sent?*/@id (:Get the id's of the words we don't need to remove:)
  let $proc-sent := deh:remove($full-sent/*[(@id = $ids) = $non-speech]) (:Use the 'remove' function on all tokens without the targeted id's:)
  return if (boolean($proc-sent)) then (functx:copy-attributes($proc-sent, $full-sent))
   (:Do this one final step because 'deh:remove' returns a <sentence/> node with 0 attributes:)
  else ()
  
  
};

(:
12/26/2023
Returns a work by its short-name string

:)
declare function deh:retrieve-trees($sname as xs:string*) as node()*
{
  for $str in $sname
  return (db:get('ldt2.1-treebanks'), db:get('harrington'), db:get('proiel'))[fn:matches(deh:work-info(.)(1), $str)]
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

A function I am workshopping to return a whole range of citations from a citation with a dash. LDT luckily puts the full citation on each side of the dash (i.e. 13.463-13.465), so there is not guesswork involved, although I did not check every single example (YEP, there are some Harrington trees which don't match this, so that has to be accounted for (i.e. writing 13.463-465)); since PROIEL gives a citation on every word, there are no dashes, so this function is not necessary there. THIS FUNCTION WILL ALSO SPIT OUT STRINGS WITH NO HYPHENS, so this can be used on any string.
:)
declare function deh:cite-range($range as xs:string) as item()*
{
  let $dash-index := functx:index-of-string($range, '-') (:Place in the string of the dash:)
    return if (fn:count($dash-index) > 0) then (
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

(: Winter Break 2022-23 Phase (OBSOLETE: 9/20/2023):)
(: Change the confusing terms later: this works either way:)
(:
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
:)

(: Winter Break 2022-23 Phase (OBSOLETE: 9/20/2023):)
(: THIS WON'T WORK, COME UP WITH ANOTHER SOLUTION:)
(: Just note that the proc-results function should return a list which includes elements that overlap with the targets list, and that the proc-targets function should return a list which overlaps with the results list:)
(:
declare %public function deh:return-pairs($results as element()*, $targets as element()*, $proc-results, $proc-targets)
{
  let $proc-results := $proc-targets($targets)
  let $proc-heads := $proc-results($results)
  return deh:process-pairs($targets, $proc-targets, $results, $proc-results)
};
:)

(: Winter Break 2022-23 Phase (OBSOLETE: 9/20/2023):)
(: Should be private and used in the deh:return-pairs function later!!! :)
(:
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
:)

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
deh:is-punc()
10/19/2023
:)
declare function deh:is-punc($tok as element()) as xs:boolean
{
  ($tok/fn:string(@relation) = ("AuxX", "AuxG", "AuxK") or $tok/fn:matches(fn:string(@postag), "u........"))
};


(:
deh:return-parent-nocoord()
9/22/2023

This is a variant of deh:return-parent which skips coordinating constructions. This should include COORD, AuxX (comma), AuxG (bracketing punctuation), and AuxK (terminal punctuation)

Note from deh:get-auxc-verb:
Punctuation dependent on AuxC only seems to separate the verb from the AuxC once, in Harrington. Nonetheless, all the others will be cancelled out by the fact they are not verbs, so I will continue with the no punctuation rule for -nocoord

12/13/23 Notes: this is not technically strictly 'nocoord' anymore: it also checks to see if there is an AuxZ, because sometimes the prius intrudes between the subordinated verb and its quam
:)
declare function deh:return-parent-nocoord($nodes as element()*)
{
  let $parents := deh:return-parent($nodes, 0)
  for $parent in $parents
  return if (deh:is-coordinating($parent) or fn:contains($parent/fn:string(@relation), 'AuxZ')) then (deh:return-parent-nocoord($parent))
  else ($parent)
};

(:
deh:return-children-nocoord
10/2/2023

Same as deh:return-parent-nocoord above, but for children

Note from deh:get-auxc-verb:
Punctuation dependent on AuxC only seems to separate the verb from the AuxC once, in Harrington. Nonetheless, all the others will be cancelled out by the fact they are not verbs, so I will continue with the no punctuation rule for -nocoord

$nodes: either LDT or PROIEL tokens
:)
declare function deh:return-children-nocoord($nodes as element()*)
{
  (:Retrieve the children:)
  let $children := deh:return-children($nodes)
  
  (:Then return each which isn't a coordinating conjunction, and pass the others right back into the function (just in case we have a coordinating conjunction coordinating other coordinating conjunctions):)
  let $final :=
    for $child in $children
    return if (deh:is-coordinating($child) or fn:contains($child/fn:string(@relation), 'AuxZ')) then (deh:return-children-nocoord($child)) else ($child)
    
  return ($final)
};

(:
deh:check-head
7/21/2023:
Returns the head id, whether it is an LDT or PROIEL tree
:)
declare %public function deh:check-head($word as element())
{
  let $head :=
  if ($word/name() = 'word') then ($word/@head)
  else if ($word/name() = 'token') then ($word/@head-id)
  else ()
  
  return if (fn:number($head) = fn:number($word/@id)) then () else ($head) (:Added this line of code 11/9/2023, because there is one sentence (sentence 899 in phi0972.phi001) in which a coordinating node has its id and head as the same value! This causes a stack overflow, of course.:)
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

$node: 10/6/2023: this is now only accepting a single node, in an attempt to get this function under control//////OBSOLETEOne or many nodes, each of which is processed individually. Currently must be an LDT node

$depth: CURRENTLY VESTIGIAL, I'LL FIX IT LATERThe depth within the 'descendants' results which you want to return; if 0, this returns all descendants, but, for example, a depth of 2 would return all the grandchildren of each $node passed into the function

Depends on:
deh:return-children()
deh:return-depth()
deh:descendants-aux

:)
declare %public function deh:return-descendants($node as element()*)
{  
  deh:descendants-aux($node, 1)[fn:deep-equal(., $node) = false()]
};

declare %private function deh:descendants-aux($node as element()*,$count as xs:integer)
{
  if ($count < 50) then (deh:descendants-aux(functx:distinct-nodes(($node, deh:return-children($node))), ($count + 1)))
  else ($node)
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
declare function deh:return-depth($node as element(), $iter as xs:integer)
{
  if (fn:count(deh:return-parent-cheap($node)) eq 0) then
    ($iter)
  else (
    deh:return-depth(deh:return-parent-cheap($node), ($iter + 1))
  )
};

declare %public function deh:return-parent-cheap($node as element()) as element()*
{
  $node/../*[@id = deh:check-head($node)]
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
10/31/2023:
deh:return-siblings-nocoord()
:)
declare function deh:return-siblings-nocoord($nodes as element()*, $include as xs:boolean) as element()*
{
  let $siblings := deh:return-siblings($nodes, $include)
  for $sib in $siblings
  return if ($sib/deh:is-coordinating(.)) then (deh:return-children-nocoord($sib))
  else ($sib)
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

7/21/2023: Added PROIEL compatibility with deh:check-head

Depends on:
deh:proc-highest (private, made for this function to handle looping through each level of the sentence)
deh:postag-andSearch
deh:check-head
:)
declare function deh:find-highest($postag-search as item()*, $sents as element(sentence)*)
{
  for $sent in $sents
    let $head := $sent/*[(fn:data(deh:check-head(.)) > 0) ne true()]
    return deh:proc-highest($postag-search, $head, deh:postags(if ($head[1]/name() = 'token') then ('proiel') else ('ldt')))
};

(:9/22/2023: another version of the function where you find the highest, no matter the postag:)
declare function deh:find-highest($sents as element(sentence)*)
{
  for $sent in $sents
  return $sent/*[(fn:data(deh:check-head(.)) > 0) != true()]
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
deh:pick-random()
9/29/2023

$size: Size of the sequence you are drawing from
$n: Total number of random values you need

:)
(:
declare function deh:pick-random($size as xs:integer, $n as xs:integer)
:)(:
{
  let $predicate := function($seq) {fn:count($seq) >= $n} 
  let $action := function($seq) {
    let $final-rand := hof:until(function($rand) {functx:is-value-in-sequence($rand, $seq) = false()}, function($rand) {(random:integer($size) + 1)}, random:integer($size) + 1)
    return ($seq, $final-rand)
  }
  let $zero := random:integer($size) + 1
  return hof:until($predicate(), $action(), $zero)
};
:)

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

(:------------------------------------START of special use-case stuff------------------------------------------:)

(:Pass the $all-ldt var from AGLDT_Search_Test, get the duplicates based on BOTH urn and subdoc:)
declare function deh:get-duplicates($all-ldt)
{
  let $subdocs := 
  for $doc in $all-ldt
  let $sents := $doc//sentence
  return fn:distinct-values(
  for $sent in $sents
  return fn:concat(fn:string($sent/@document_id), " ", $sent/fn:string(@subdoc))
)

for $item in $subdocs
where fn:count(fn:index-of($subdocs, $item)) > 1
return $item
};

declare function deh:get-ldt-conj-relations($all-ldt)
{
  fn:distinct-values(deh:return-children(deh:search((), "AuxC", (), $all-ldt))/fn:string(@relation))
};
(:-------------------------------------END of special use-case stuff------------------------------------------:)

(:-------------------------------------START of utility functions---------------------------------------------:)
(:This section is for functions particularly related to the chosen thesis topic. I want to be able to:
  -extract main verbs (which is different between trees)
  -extract as many quotations as possible.
  -extract proper conjunctions (which will include relative adverbs)
  -extract AND remove (two separate things) non-finite clauses
  -remove clause by subordinator/list of subordinators function
  -implement an extract AND remove all satellite/adjuncts
  -also remove all non-adjunct, finite subordinators as a third category? That would be complement clauses, various kinds of indirect question/command in that category too, relative clauses

:)

(:
12/3/2023
deh:get-tok-address

Returns a string with the concatenated filename, sentence and word id, in that order, separated by |
:)
declare function deh:get-tok-address($tok as element())
{
  ($tok/fn:base-uri(.) || "|" || $tok/../fn:string(@id) || "|" || $tok/fn:string(@id))
};

declare function deh:read-tok-address($address as xs:string, $corpus as node()*)
{
   let $seq := fn:tokenize($address, '\|')
   return $corpus[fn:base-uri(.) = $seq[1]]//sentence[fn:string(@id)=$seq[2]]/*[fn:string(@id) = $seq[3]]
};

declare function deh:get-sent-address($sent as element(sentence))
{
  ($sent/fn:base-uri(.) || '|' || $sent/fn:string(@id))
};

declare function deh:read-sent-address($address as xs:string, $corpus as node()*)
{
  let $seq := fn:tokenize($address, '\|')
  return $corpus[fn:contains(fn:base-uri(.), $seq[1])]//sentence[fn:string(@id) = $seq[2]]
};

(:
deh:count-clause-pairs
11/30/2023

I am getting tired of redoing this every time, so if I want to count, in a sequence of tokens, how many of each lemma in the corpus there is, this function will do it. If we return from clause-pairs, if it is necessary, a third item in the sequence will be included if necessary (i.e., antequam or quam with ante as its head will receive a third tag to keep them together), which will be included as one category
:)
declare function deh:count-clause-pairs($toks as array(*)*) as item()*
{
    (:Get only the appropriate string: if there is a third item in an array, that means we selected it as the lemma which should represent the whole phrase, so we must check for that:)
    deh:format-clause-pairs($toks) => deh:count-each()
};

declare function deh:format-clause-pairs($toks as array(*)*) as xs:string*
{
  (:This function outputs the clause pairs in a friendly format:)
  ($toks[array:size(.) > 2]?(3), $toks[array:size(.) < 3]?(1)/fn:lower-case(fn:string(@form)))
};

(:
deh:count-by-lemma()
11/30/2023
:)
declare function deh:count-by-lemma($toks as element()*) as array(*)*
{
  deh:count-each($toks/deh:process-lemma(./fn:string(@lemma)))
};

(:
deh:count-by-form()
11/30/2023
:)
declare function deh:count-by-form($toks as element()*) as array(*)*
{
  deh:count-each($toks/fn:lower-case(fn:string(@form)))
};

declare function deh:count-each($strings as xs:string*)
{
  for $string in fn:distinct-values($strings)
  where $string != ""
  order by fn:count($strings[. = $string])
  return array{$string, fn:count($strings[. = $string])}
};


(:
deh:extract-nonfinite()
9/20/2023

This will eventually have a corresponding function deh:remove-nonfinite, where the results of this function can be used to get the parts of the sentence NOT removed. This means whole constituents need to be removed, not just the verb, although we'll get there.

$

Depends on:
deh:get-preds() (indirectly, I am currently testing it to put it in a higher function)
:)

(:
deh:lowest-numbers()
9/20/2023

Out of a sequence, returns only the lowest values
:)
declare function deh:lowest-numbers($seq as xs:integer*)
{
  $seq[. = fn:min($seq)]
};

(:
deh:search-text()
9/20/2023

Should take a string, and, stripping punctuation, return matches in the treebanks. Make sure to put spaces between everything that is tokenized, including que's and turning 'nec' into 'ne c' for proiel!


:)
declare function deh:search-text($str as xs:string, $trees as element(sentence)*)
{
  
  for $sentence in $trees
  let $print := fn:lower-case(deh:print($sentence)) (:Get the sentence as a string:)
  let $print-no-punc := fn:replace($print, "[^a-zA-Z ]", "") (:Remove anything that is not a letter, or a space (note the extra space after 'a-z':)
  return if (fn:contains($print-no-punc, $str)) then (($sentence)) (:If what we are searching is contained within the sentence, return it:)
  else ()
};

(:
deh:is-finite()
9/20/2023

Returns whether any single token (ldt or proiel) is a finite verb
:)
declare function deh:is-finite($tok as element()) 
{
  (:First, check if something is even a verb and therefore eligible in the first place; otherwise, return false:)
  if (deh:is-verb($tok)) then (
  
  (:I just want to account for every scenario here: if it is a periphrastic:)
  let $final := if (deh:is-periphrastic-p($tok)) then (deh:return-children($tok)[deh:is-auxiliary(.)]) else ($tok)(:10/3/2023, added this to account for participles in periphrastics; if a verb is dependent on an AuxV be-verb, it must be in a periphrastic in the LDT; if it is a predicate but is also a participle, in PROIEL it must be in a periphrastic; 10/31/2023, modified the spooky is-periphrastic-p function, now it should be usable here:)
  let $str := if ($final/name() = 'word') then ($final/@postag) else ($final/@morphology)
 return (fn:matches(fn:string($str), ".*[0-3].*")) (:If it has a number in the @postag (LDT) or @morphology (PROIEL), it must be finite, for digits are only used for that element; even elliptical nodes often have number marked, so it should even catch periphrastics with consistency:)
 (:DOESN'T MATTER, I'm tired; it will catch either the auxiliary or main verb no matter what. let $bool-b := (deh:return-parent($tok, 0)/fn:contains(fn:string(@relation), "AuxV") or $tok/fn:string(@relation) = "pred") (:10/3/2023, added this to account for participles in periphrastics:) :)
)
else (false())
};

declare function deh:is-auxiliary($tok as element())
{
  $tok/deh:lemma(., ('sum', 'foro', 'edo', 'habeo')) and fn:contains(fn:lower-case($tok/fn:string(@relation)), "aux")
};



(:
deh:has-personal-agreement()
10/4/2023:

This is like the old deh:is-finite, which only tests for person
:)
declare function deh:has-personal-agreement($tok as element()) as xs:boolean
{
  if (deh:is-verb($tok)) then (
   let $str := ($tok/@postag, $tok/@morphology) 
   return (fn:matches(fn:string($str), "[0-3]"))
 )
 else (false())
};

(:
deh:remove()
9/21/2023

This removes a series of nodes from their respective sentences.

$toks: A series of word/token elements

Depends on:
deh:remove-from-sent()
:)
declare function deh:remove($toks as element()*) as element(sentence)*
{
  let $sents := functx:distinct-nodes($toks/..) (:retrieve the sentences from the provided token/word elements:)
  for $sent in $sents
  let $final-toks := $toks[./.. = $sent] (:Get all the the tokens which are in this sentence:)
  return if (fn:count($final-toks) = 0) then ($sent) (:Put a condition here because, if there is nothing to remove from the sentence, we should, logically, return the whole sentence and not nothing:)
  else  (deh:remove-from-sent($final-toks)) (:For each sentence, submit only the tokens which have an equivalent parent; technically, I think this may allow duplicates, but that should be impossible :)
};

(:
deh:remove-from-sent()
9/21/2023

This function takes a sequence of tokens FROM A SINGLE SENTENCE and returns their original sentences with said tokens removed. It will NOT work with tokens from multiple sentences ALSO KEEP IN MIND THIS FUNCTION RETURNS A SENTENCE NODE WHETHER IT IS EMPTY OR NOT

$toks := a sequence of token/word elements
:)
declare %private function deh:remove-from-sent($toks as element()*) as element(sentence)*
{
  (:Use group by?:)
  let $ids := $toks/@id
  return <sentence> {
  $toks[1]/../* except $toks[1]/../*[@id = $ids] (:$token refers to the ones retrieved from sentences, not the ones passed to the function as an argument:)}
  </sentence>
};

(:9/21/2023: This takes tokens, retrieves only the UNIQUE sentences:)
declare %private function deh:get-sents($tok as element()*) as element(sentence)*
{
  functx:distinct-nodes($tok/..)
};

(:
deh:main-verbs()
9/21/2023

Returns only the main verbs from a set of documents/sentences/tokens/etc. Note that, for this reason, in much of the LDT, this won't get most main verbs in direct speech; however, if it goes on for multiple sentences, it might include that. ANOTHER CHARACTERISTIC OF THIS is the fact that it retrieves auxiliaries in the LDT, and the participles within a periphrastic in PROIEL; for now, that does not matter, just keep it in mind.

$nodes: A doc, sentence, token, or a sequence of any of those

Depends on:
deh:pr-main-verbs()
:)
declare function deh:main-verbs($nodes as node()*) as element()*
{
  
  let $toks := deh:tokens-from-unk($nodes)
  (:First, separate the two types of tokens:)
  let $ldt := $toks[name() = "word"]
  let $proiel := $toks[name() = "token"]
  
   let $complementizers := ("aio", "inquam") (:This is the list of words that mainly introduce direct speech; since no other words contain the same sequence of strings within, it is fine the just use functx:contains-any-of as below, you don't have to use regex syntax:)
  
  (:Second, extract out the main verbs for LDT in stages:)
  
  (:Get all verbs which are in scope:)
  let $l-verbs := $ldt[deh:is-finite(.)] (:We only want finite verbs, generally; WE'LL DEAL WITH HISTORICAL INFINITIVES LATER (10/8/2023, removed "or deh:is-periphrastic-p(.)" from the parameters, because it will still get the auxiliary:)
  (:narrow it down to predicates, return this:)
  let $preds := $ldt[((deh:is-verb(.) and fn:contains(fn:string(@relation), "PRED")) or (deh:is-finite(.) and functx:contains-any-of(fn:string(@relation), ("PRED", "ExD", "PARENTH")))) and functx:contains-any-of(fn:string(@relation), ("ADV", "N-PRED", "A-PRED")) = false()](:Return all the PRED's, this should be directly returned at the end; 10/26/23, added "ExD" because it is used of parentheticals, although I had to exclude ExD phrases which contain "ADV". 10/31, spookily added N-PRED and A-PRED because, in HArrington, these are used of predicate nominals and predicate accusatives, not verbs:)
  
  (:Now deal with direct speech:)
  let $directsp := $l-verbs[deh:is-directsp(.)]
  let $proiel-main := deh:pr-main-verbs($proiel)
  
  return (functx:distinct-nodes(($preds, $directsp)), $proiel-main)
};


declare function deh:is-directsp($tok as element()) as xs:boolean
{
  let $complementizers := ("aio", "inquam")
  
  (:First condition: whether LDT or PROIEL, we should know if I added a manual annotation for direct speech:)
  return if ($tok/fn:name() = "word") then (($tok/fn:string(@directsp) = "false" or $tok/../fn:string(@directsp) = "false") = false() and  (functx:contains-any-of($tok/fn:string(@relation), ("DIRSTAT", "-DS-")) or (fn:contains($tok/fn:string(@relation), "OBJ")(: or (fn:count(deh:return-siblings($tok, false())[fn:contains(fn:string(@relation), "AuxG")]) > 0) or fn:count(deh:return-children($tok)[fn:contains(fn:string(@relation), "AuxG")]) > 0:) and ((functx:contains-any-of(deh:return-parent-nocoord($tok)/fn:string(@lemma), $complementizers))))))
  else (
    let $complementizers := ($complementizers, "dico")
    return ($tok/fn:string(@directsp) = "false" or $tok/../fn:string(@directsp) = "false") = false() and (functx:contains-any-of(deh:return-parent-nocoord($tok)/fn:string(@lemma), $complementizers)) and fn:contains($tok/fn:string(@relation), "pred") (:using 'fn:contains' because I want pred AND parpred:) and deh:is-finite($tok)
  )
  
  (:Added this third one checking the parent because, if the whole sentence is in direct speech, and the head of the sentence is an OBJ, then is must be a "main" verb:)
  (:let $ldt-main := $ldt[(fn:contains(fn:string(@relation), "PRED") or (functx:contains-any-of(fn:string(@relation), ("OBJ", "DIRSTAT")) and ((fn:count(deh:return-children((., deh:return-parent(., 0)))[fn:contains(fn:string(@relation), "AuxG")]) > 0) or (functx:contains-any-of(deh:return-parent-nocoord(.)/fn:string(@lemma), $complementizers))))) and (fn:matches(fn:string(@postag), "v[1-3].......") or (fn:count(deh:return-children(.)[fn:contains(fn:string(@relation), "AuxV")]) > 0) or fn:string(@artificial) = "elliptic")] :)(:This gets complicated. FIRST, every verb must be finite, so that is the last condition, although participles in periphrastic constructions lead the phrase, so we need to make sure, if it is non-finite, that it has an auxiliary, or it is elliptical, in which case it will have no relation. SECOND, it must either be a PRED, which is the case 99% of the time, or it is in direct speech, which means it has the OBJ tag and, if a Harrington tree, the DIRSTAT tag; because a verb can be an OBJ in a variety of circumstances, we have to check that there is bracketing punctuation involved, hence testing for 'AuxG' (and we check both the self and parent, because there could be a coordinating conjunction involved, but this should still work even if there isn't), or, just in case, we also check for whether it is governed by "inquam" or "aio", and use deh:return-parent-nocoord to get past an coordinating punctuation. Also note it is necessary to determine whether it is a finite verb, because harrington trees have A-PRED and N-PRED (predicate accusative and predicate nominal) as possible relations, which go on nouns and are beyond scope here. THIS CODE IS COPIED BELOW IN DEH:DIRECT-SPEECH-LDT...SORRY:)
  
};

(:The same as deh:main-verbs, but returns a sequence of three arrays. the FIRST is proper main verbs, the SECOND parentheticals, and the THIRD reported speech:)
declare function deh:split-main-verbs($nodes as node()*)
{
  for $node in $nodes
  let $verbs := deh:main-verbs($node)
  let $main := $verbs[fn:contains(fn:lower-case(fn:string(@relation)), "pred") and fn:string(@relation) != 'parpred']
  let $parenth := $verbs[deh:is-parenthetical(., false())]
  let $reported := $verbs[functx:is-node-in-sequence(., ($main, $parenth)) = false()]
  
  return if (fn:matches(deh:work-info($node)(1), "Petr")) then ([($main, $reported), $parenth, ()])
  else ([$main, $parenth, $reported])
};

(:
1/5/2024
deh:is-parenthetical

Used as a helper to deh:split-main-verbs and for retrieving parentheticals which do not contain or are not verbs. Checks relation tags and lemma. @param $excl-voc is used when vocative 
:)
declare function deh:is-parenthetical($tok as element(), $is-voc as xs:boolean) as xs:boolean
{
  (:If I put a "parenth" tag on it, that should override it:)
  if ($tok/fn:string(@parenth) = "true") then (true()) else (
  ($tok/fn:string(@parenth)="false") = false() (:this is so that, if I have added an @parenth, :) and ((if ($is-voc = false()) then (deh:case($tok) != 'v') else (true())) (:added the previous so I have a way of toggling the inclusion of vocatives on and off:) and functx:contains-any-of($tok/fn:string(@relation), ("ExD", "PARENTH", "parpred", "voc")) and (functx:contains-any-of($tok/fn:string(@relation), ("ADV", "OBJ", "SBJ", "PRED", "AuxC", "PNOM", "_ExD", "ExD_AP")) = false()) (:PNOM added because sentence 561 in Petr Narr in main ldt; I did it for AuxC beecause, although it is rare, it is used more when a clause it tokenized separately than being used parenthetically:) and (deh:lemma($tok, ("aio", "inquam", "o"))) = false() (:added 'o' as a disallowed lemma because it will always appear next to another parenthetical anyway, and be included in its scope; in short, it will be retrieved either way, but will be duplicated if it is identified separately:) and deh:is-punc($tok) = false() and (if (deh:is-verb($tok)) then (deh:is-directsp($tok) = false()) else (true())))
)
};

declare function deh:retrieve-parentheticals($nodes as node()*) as element()*
{
  for $sent in deh:sents-from-unk($nodes) (:Go sentence by sentence retrieving parentheticals so you can avoid dealing with embedded instances in every case:)
  where boolean($sent/*[deh:is-parenthetical(., false())])
  let $parenths := $sent/*[deh:is-parenthetical(., false())]
  return if (fn:count($parenths) = 1) then ($parenths)
  else (
    for $parenth in $parenths
    (:If a parenthetical is among the descendants of another, we want just the higher one. To do this, we make sure:)
    where fn:count($parenth intersect deh:return-descendants($parenths except $parenth)) = 0
    return $parenth
  )
};

(:
deh:pr-main-verbs()
9/21/2023

This is a helper function to deh:main-verbs, which handles extracting PROIEL main verbs. The process is different, since @relation="pred" is allowed in more contexts than the LDT. THERE IS A QUESTION I NEED TO ANSWER EVENTUALLY: do I include parpreds in this? Since they can be "main" verbs, I should probably say yes, especially since they mark out parentheticals, which are a symptom of parataxis.
:)
declare %public function deh:pr-main-verbs($toks as element()*) as element(token)*
{
  let $preds := $toks[fn:string(@relation) = ("pred", "parpred", "voc") and fn:string(@part-of-speech) = 'V-'] (:Switched to 'fn:contains' for finding 'pred' because we want both 'pred' (main verbs) and 'parpred' (parenthetical verbs, and also verbs governing speech). This, however, means that we need to get speech-verbs in LDT as well.:)
  return $preds[(deh:return-parent-nocoord(.)/fn:string(@part-of-speech) = "G-") = false()]  (:10/3/2023, made it deh:return-parent-nocoord, it may break it, but I'm trying it:)
};

(:Used for both LDT and PROIEL:)
declare function deh:is-periphrastic-p($tok as element()) as xs:boolean
{
  (:12/6/2023: if it is not a participle, we don't deal with it, so we check; it is 'p' in both treebanks:)
  if (deh:mood($tok) = 'p') then (
  let $children := deh:return-children($tok)
  (:12/13/2023: added 'foro' because 'foret' was mistagged as foro so often in Sallust that this should account for it; same with edo for est. Sometimes in Egeria the perfect passive with habeo is used, so we also need to account for that:)
  return (fn:count($children[fn:contains(fn:lower-case(fn:string(@relation)), "aux") and deh:lemma(., ('sum', 'foro', 'edo', 'habeo'))]) > 0) or (fn:lower-case(fn:string($tok/@relation)) = 'pred') (:12/6/23: added the 'pred' test because it cannot be a participle, have the pred tag and not be a periphrastic participle:)
)
  else (false())
};



(:
deh:direct-speech-ldt()
9/29/2023

This function should get every word governing direct speech in the LDT. It does this by looking for subordinate AuxG, 

:)
declare function deh:direct-speech-ldt($nodes as node()*) as element(word)*
{
  let $toks := deh:tokens-from-unk($nodes)
  let $ds := deh:main-verbs($toks)[fn:contains(fn:string(@relation), "PRED") = false()]/deh:return-parent(., 0) (:This takes all the "main verbs," which, as defined in that function, returns also verbs in direct speech. This takes those which are not PRED (and therefore should only be direct speech), and returns their parents to get the words which govern it:)
  return $ds
  
};

declare function deh:direct-speech-pr($nodes as node()*) as element(token)*
{
  let $toks := deh:tokens-from-unk($nodes)
  let $lemmas := ("aio", "inquam") (:Get the lemmas for Direct Speech; this can be expanded:)
  let $ds := $toks[(fn:string(@lemma) = $lemmas)]
  let $final-ds := $ds[fn:count(deh:return-children-nocoord(.)) > 0]
  return $final-ds
};



(:
deh:is-conjunction()
9/21/2023:

This function tests whether a token is a conjunction in the LDT (will add PROIEL support)
:)
declare function deh:is-conjunction($tok as element()) as xs:boolean
{
  fn:contains($tok/fn:string(@relation), "COORD") or fn:string($tok/@part-of-speech) = "C-"
};


(:
deh:clause-noclause()
9/30/2023

This function should only return verbs which are in a clause (whether finite or non-finite). What is not a verb at the head of a clause is easier to determine, and the following are the tentative criteria:
-a main verb (for that matter, no imperative can be either! Are there any imperatives which the "main verbs" algorithm does not get? You need to check (9/30))
-a supine (unless used with venio? but that's rare; however, that is more of an complementary construction, especially since the subject is controlled; so, all supines can be excluded)
-On that same token, infinitives of purpose and complementary infinitives are not clauses. This will be difficult to determine in the LDT; for PROIEL, we know that XOBJ is used for these infinitives where the subject is controlled for. These are discussed in the "open predications" section of the annotation guide. However, XOBJ is also used for AcP, where the noun and participle are not connected directly, but both made objects
-a gerund/noun with embedded predication  (unless said gerund takes a direct object?) Note that, in noun phrases, Pinkster refers to elements of the embedded predication as ATTRIBUTES, not as arguments, adjuncts, etc. Therefore, anything with an ATR is fine (in LDT); in PROIEL, gerunds take on a lot of properties of verbs, but I'm sticking to my guns: parataxis and complex noun phrases seem like different things, and the idea of subordination specifying relations seems separate to me. However, preposition plus gerund should be a non-finite clause to me: there is a governing construction which 
-a prolative infinitive (see PInkster 126ff.), like admoneo te venire, will not be considered a clause; 
-participles, when used just as attributes, without arguments, will not be under consideration. However, this means we must remove participles which are not 1) in abl abs, 2) praedicative, 3) have arguments, 

Also keep in mind related parts of speech: only nouns can have Pd, Px, 
:)

(:
deh:particip-clauses

We'll need this for the finite/non-finite stuff, and for deh:clause-noclause. This will automatically extract participles, so no need to be careful with the input. See within the body of the function for notes on how this will work

$nodes: Any node from a treebank, LDT or PROIEL
:)
declare function deh:particip-clauses($nodes as node()*) as element()*
{
  let $toks := deh:tokens-from-unk($nodes)
  
  let $parts := "(d|g|p)"(:In the 5th position in the LDT, mood, we need one of these values (d gerund, g gerundive, p participle); the values are the same for PROIEL, but are in the 4th position:)
  
  let $proiel := $toks[name() = 'token' and fn:matches(fn:string(@morphology), ("..." || $parts || "......"))]
  let $ldt := $toks[name() = 'word' and fn:matches(fn:string(@postag), ("...." || $parts || "...."))]
  
  
  (: Praedicativa (xadv in PROIEL, Atv/AtvV :)
  let $pr-praetags := "XADV"
  let $ldt-praetags := ("atv", "atvv") (:Made these variables in case I change them later:)
  let $praedicativa := ($proiel[fn:string(@relation) = $pr-praetags], $ldt[fn:string(@relation) = $ldt-praetags])
  
  (: NIXING THIS FOR NOW, IT SEEMS LIKE I SHOULD JUST AcP constructions (XOBJ in proiel, LDT gives no specification in guidelines or Harrington, which is worrying, but I have worked out the algorithm below; it seems to be the case that it is often an attributive NOT subordinated to its noun, but being in scope with the noun.) :)
  
  (:Gerunds/Gerundives after prepositions, NOT in periphrastics:)
  
  return ($proiel, $ldt)
};


(:The following may not be necessary, but I started making them anyway; I think the is-conjunction thing should be enough:)
(:
deh:check-postag-coord()
:)
(:
deh:check-lemma-coord
:)
(:
deh:check-form-coord
:)
(:
deh:check-rel-coord()
10/2/2023

This function comes about because, sometimes, you are looking for something in a parent or child but coordination screws things up. This will check if there is coordination, and instead look at the children.

$str := A string with the desired relation; this function uses fn:contains to check
$tok := an element or series of elements, which are somehow related to your target word (usually either parents or children). I restrict it to the LDT, because PROIEL makes the coordinating conjunction take on the relation of its child, giving us a method of dealing with the issue

:)
declare function deh:check-rel-coord($str as xs:string, $tok as element(word)*)
{
  let $rel := deh:return-parent($tok, 0)/fn:string(@relation)
  return ()
};

(:
deh:finite-clause()
10/3/2023

This returns every finite clause in the LDT and PROIEL, from whatever you submit as the argument. The deh:main-verbs() function can help, because it is essentially every finite verb which is not one of those. Specifically, it is every non-PRED finite verb in the LDT and every "pred" not dependent on a "G-" (subordinating conjunction). Again, note the mismatch between LDT and PROIEL for auxiliaries, and which is the head (participle is the head in in both). Also, keep in mind that questions do not count as subordinate clauses.

Errors:
Also note that this sentence, <sentence id="261" document_id="urn:cts:latinLit:phi0474.phi013.perseus-lat1" subdoc="2.5">, shows that "nescioquod" is considered finite, because it is a finite non-main-verb
How can this deal with situations where there is a conjunction within the clause? 
:)
declare function deh:finite-clause($nodes as node()*, $verb-only as xs:boolean := false()) as element()*
{
  
  let $toks := deh:tokens-from-unk($nodes)
  let $remove := function($a as element(), $seq as element()*) {if (functx:is-node-in-sequence($a, $seq)) then () else ($a)} (:This function removes any element not in the @param $seq, we'll use a map on the finite verbs with the main verbs as the $seq:)
  
  (:First, we need to get only the finite verbs:)
  let $finite-verbs := $toks[deh:is-finite(.) and deh:is-subjunction(.) = false()] (:Added the subjunction stipulation because of LICET:)
  (:However, we have an issue: this list includes auxiliaries, which the deh:main-verbs function will never return, so they will not be removed, even if they are from main clauses. Therefore, we will replace them with their participle heads (well, heads in PROIEL, not LDT, but, either way, the participle holds the relation info) :)
  let $finite-verbs := for $tok in $finite-verbs return if (deh:is-auxiliary($tok)) then (deh:return-parent($tok, 0)) 
  else ($tok)
    
  let $main-verbs := (deh:main-verbs($toks)) (:10/9/2023:)
  let $nescioquid := (deh:nescioquid($toks)) (:10/13/2023, see comment on $sub-verbs below:)
  
  let $sub-verbs := $finite-verbs ! $remove(., ($main-verbs, $nescioquid)) (:10/13/2023, added this function and the variable $nescioquid above to make sure the grammaticalized phrase 'nescioquid' is not considered a subordinate clause:)
  let $final := (:Decided to pass the final filter between verbs in proper "subordinate" clauses and those where the verb acts as the head to a variable, because, if one conjunction has two verbs, it may get returned twice:)
    for $verb in $sub-verbs
    let $parent := deh:return-parent-nocoord($verb) (:If it has a conjunction as its head (or quam as a comparative), we want the conjunction, not the verb, so we need to test it:)
    return if ((($parent/deh:is-subjunction(.)) or $parent/deh:lemma(., ("quod"))) and $verb-only = false()) then ($parent) (:Added a lemma check here because of inconsistent tagging, and because this particular algorithm has no place in the deh:is-subjunction function. 'Quod', when it is the head of a verb in a finite clause, is always a subordinator, I checked, even when tagged as something other than AuxC. However, in main clauses it can be the head of a verb in the collocation 'quod si', which means that we need to check for this here, where we already know every verb is subordinate:)
     else ($verb) (:10/13/2023: added more conditions to the PROIEL string check, because it turns out that non-"subjunctions" can also head clauses. However, I also removed some that I added after testing: 'Pr' only appears as a head in certain circumstances, but never as a subordinator; removed "Du" because it never seems to actually head a phrase; I'm not sure why I included Px (indefinite pronoun), but it's gone; 'Dq' is also never used at the head of its clause; finally, removed "Df", ultimately because it was silly to think such a broad category could be helpful. My main issue was that compounds with "quam" are sometimes marked this way, but, ultimately, the verb is still annotated with the relation info, so it remains that case that we have the info we need with just 'G-' as the exception. :)
  return functx:distinct-nodes($final)
};

declare function deh:is-periphrastic-aux($tok as element()) as xs:boolean
{
  $tok/fn:matches(fn:string(@lemma), "^sum([^a-z]*|)$") and $tok/fn:contains(fn:lower-case(fn:string(@relation)), "aux")
};

(:
deh:nescioquid()
10/13/2023

This serves to select "nescioquid" from the results, because it is considered a "clause," but I feel it is much too grammaticalized for that. The good news is that, in PROIEL, this seems to be annotated differently from a normal relative clause, where the verb is the head; in this case, the pronoun remains the head of the phrase. This appears to be the case in LDT as well. Although AuxZ seems to be the favored way for marking the 'nescio' in LDT, that does not seem to be carried out consistently
:)
declare function deh:nescioquid($nodes as node()*)
{
  let $nescio := deh:tokens-from-unk($nodes)[fn:string(@form) = 'nescio'] (:It must only be the first person, so just get the form directly:)
  return $nescio[deh:return-parent(., 0)/fn:contains(fn:string(@lemma), "qui")] (:Then, if the parent lemma contains 'qui' (which includes 'quis' as well), it must be nescioquid or nescioquod or something:)
};



(:
deh:is-
:)

(:
deh:local-remove()
10/4/2023

Deal with this later, make it pretty
:)
declare function deh:local-remove($a as element(), $seq as element()*) {if (functx:is-node-in-sequence($a, $seq)) then () else ($a)}; 

(:
deh:non-finite-clause()
10/3/2023

Pretty much any verbal which is not finite, but if it has a parent that has @relation="AuxC" or @part-of-speech="G-", return that. There are also some exceptions to keep in mind: the historical infinitive is weird
:)
declare function deh:non-finite-clause($nodes as node()*) as element()*
{
  let $toks := (deh:tokens-from-unk($nodes))[deh:is-verb(.) and (deh:is-finite(.) = false())] 
  let $final := for $tok in $toks where fn:count(deh:main-verbs($tok)) = 0 return $tok
  return $final
};



(:
deh:is-verb()
10/3/2023

:)
declare %public function deh:is-verb($tok as element()) as xs:boolean
{
  (:let $by-rel := ($tok/fn:string(@relation) = ("pred", "parpred") and fn:string-length($tok/fn:string(@empty-token-sort)) > 0):)(:Created this 'check by relation' thing because empty tokens have no morph in PROIEL:)
  (($tok/fn:string(@part-of-speech) = 'V-') or (fn:matches($tok/fn:string(@postag), "v........")))
};

(:
deh:finite-clause-verb-head()
10/10/2023

This function returns all verbs in subordinate clauses which do not have a subordinator as their head. It pretty heavily relies on the deh:finite-clause function.

@param $nodes := Any node, document level or below, from LDT or PROIEL
:)
declare function deh:finite-clause-verb-head($nodes as node()*) as element()*
{
  (:Remember there is no need to process the nodes into tokens, deh:finite-clause already does that:)
  deh:finite-clause($nodes, false())[deh:is-verb(.)]
};

(:
deh:adjunct-clauses()
10/12/2023

For retrieving adjunct clauses WHICH ARE FINITE; A few notes:
-Relative clauses of purpose and quo + comp. need to considered

:)

(:
deh:get-tree-data()
10/18/2023

This returns, in .csv format (yes, COMMA separated) the information about every tree document; unrecognized formats will give just one field, the base uri. All the others will give the work title, author, and token count, in that order.

$docs: 
:)
declare function deh:get-tree-data() as item()*
{
  for $tree in (db:get('ldt2.1-treebanks'), db:get('harrington'), db:get('proiel'))
  let $info := deh:work-info($tree)
  return if (array:size($info) > 1) then (fn:concat(deh:remove-punct($info(1)), ",", deh:remove-punct($info(2)), ",", fn:count($tree//sentence/*)))
  else (fn:base-uri($tree))
};

(:
deh:remove-nodes-from-seq()
10/18/2023


:)
declare function deh:remove-nodes-from-seq($tok as element(), $seq as element()*) 
{
  if (functx:is-node-in-sequence($tok, $seq)) then () else ($tok)
};

(:
deh:is-subjunction
10/19/2023

Determiners if the given is a subordinating conjunction (called subjunction for brevity, and because conjunction is already taken), in LDT, PROIEL or Harrington.
:)
declare function deh:is-subjunction($tok as element()) as xs:boolean
{
  (fn:contains($tok/fn:string(@relation), "AuxC") or deh:is-subjunction-pr($tok)) or deh:lemma($tok, ('quam', 'si', 'seu', 'sive', 'siue')) and boolean(deh:return-children-nocoord($tok)[deh:is-finite(.)]) 
};

(:
(See above)
:)
declare function deh:is-subjunction-pr($tok as element()) as xs:boolean
{
  fn:contains($tok/fn:string(@part-of-speech), "G-")
};

(:
(See deh:is-subjunction; this works on LDT or Harrington)
:)
declare function deh:is-subjunction-ldt($tok as element()) as xs:boolean
{
  fn:contains($tok/fn:string(@relation), "AuxC") 
};

(:
deh:get-auxc-verb()
10/19/2023

For situations where you want the verb in an auxc-headed clause in the LDT or Harrington, use this.

Notes:
Punctuation dependent on AuxC only seems to separate the verb from the AuxC once, in Harrington. Nonetheless, all the others will be cancelled out by the fact they are not verbs, so I will continue with the no punctuation rule for -nocoord

Only instances of non-finite verbs was with quam! A few other odd instances, but one was a mistag with quoniam, and there were others where "et" was mistagged as AuxC. However, this does open my eyes that finiteness is only so good a criterion. 
:)
declare function deh:get-auxc-verb($toks as element()*) as element()*
{
  for $tok in $toks
  where deh:is-subjunction($tok) (:Updated to be able to work with either tree:)
  let $children := deh:return-children-nocoord($tok)
  return $children[deh:is-verb(.)]
};

(:
deh:var-info()
10/26/2023:

Returns the info we need for statistical processing. It goes sentence by sentence, since, otherwise, there is hardly a way to determine main verbs. 

Notes as I'm constructing this:
It should take any words which return no value for the 
:)
declare function deh:var-info($sents as element(sentence)*)
{
  for $sent in $sents
  let $main := for $verb in deh:main-verbs($sent) return $verb (:Retrieve all main verbs in the sentence:)
  let $finite := for $verb in deh:finite-clause($sent, false()) return $verb (:return all finite clauses:)
  
  (:Now, to deal with those:)
  (:let $leftovers := $finite[deh:is-verb(.) and fn:count(deh:verb-headed-clause-sub(.)) = 0]:)
  let $main := functx:distinct-nodes(($main))
  
  (:Turn them into arrays:)
  let $main := for $verb in $main return array{$verb, "main"}
  let $finite := for $verb in $finite return array{$verb, "sub"}
  
  for $pair in ($main, $finite) (:Go through every pair in the array; remember, a finite verb will be "main" or "sub":)
  let $tok := $pair(1)
  
  let $subordinator := if (deh:is-verb($tok) and $pair(2) = "sub") then (deh:verb-headed-clause-sub($tok)) else ($tok)
  
  
  
  (:Lemma:)
  let $lemma := let $final := fn:string-join($subordinator/fn:string(@lemma), ", ") return if (boolean($final)) then ($final) else (" ")
  
  let $lemma := fn:replace($lemma, "1", "") (:Added because sometimes 1 is used in ldt, sometimes not to differentiate lemmas; we really only need it if there is more than one, so get rid of it, it makes the data messy:)
  
  (:POS:)
  let $head-pos := fn:string-join($subordinator/deh:part-of-speech(.), ", ")
  
  (:subordinator form:)
  let $sub-form := let $final := fn:string-join($subordinator/fn:string(@form), ", ") return if (fn:string-length($final) > 0) then ($final) else (" ")
  
  
  (:Verb:)
  let $verb := (if ($tok/deh:is-verb(.)) then ($tok) else if (deh:is-subjunction($tok)) then (deh:return-children-nocoord($tok)[deh:is-finite(.)]) else ())
  
  let $verb-form := fn:string-join($verb/fn:string(@form), "")
  
  (:Verb mood:)
  let $verb-mood := fn:string-join($verb/deh:mood(.), "")
  
  (:Rel:)
  let $rel := (if (deh:is-subjunction-ldt($tok)) then (deh:get-auxc-verb($tok)/fn:string(@relation)) else ($tok/fn:string(@relation))) => fn:string-join(", ")
  
  (:Make sure it is lower case:)
  let $rel := fn:lower-case($rel)
  
  (:Parent pos nocoord:)
  (:We have to check if there even is a parent or result, so we can return an empty string if not:)
  let $par-pos := let $pos := deh:return-parent-nocoord($tok)/deh:part-of-speech(.) return if (fn:string-length($pos) > 0) then ($pos) else (" ")
  
  (:parent lemma:)
  let $par-lemma := let $parent := deh:return-parent-nocoord($tok)/fn:string(@lemma) return if (fn:string-length($parent) > 0) then ($parent) else (" ")
  
  let $par-lemma := fn:replace($par-lemma, "1", "")
  
  (:subordinated tokens:)
  let $sub-tokens := fn:count(deh:return-descendants($tok))
  
  (:sub. clauses:)
  let $sub-clauses := fn:count(deh:finite-clause(deh:return-descendants($tok), false()))
  
  (:Val: clause, or non-clause?:)
  
  (:Main, or subordinate?:)
  
  (:ID:)
  let $id := $tok/fn:string(@id)
  
  (:Sentence ID:)
  let $sen-id := $tok/../fn:string(@id)
  
  (:Work info:)
  let $work-info := deh:get-short-name(deh:token-info($tok)(1))
  
  (:URI:)
  let $uri := fn:base-uri($tok)
  
  (:Register:)
  let $register := $tok/preceding::register-phase1/reg
  
  (:Full sentence:)
  let $full-sent := deh:print($tok/..)
  
  (:subordinator lemma, subordinator pos, subordinator form, verb in the clause, mood of said verb, type (main, sub,), clause relation (whether from the head or within the clause if subordinate), POS of the parent node (nocoord), lemma of the parent node, number of descendant nodes, number of clauses among the descendants, the id of the HEAD node, the sentence ID, register (all three values which you added to the treebank data), and the full sentence:)
  let $final-seq :=($lemma, $head-pos, $sub-form, $verb-form, $verb-mood, $pair(2), $rel, $par-pos, $par-lemma, $sub-tokens, $sub-clauses, $id, $sen-id, $work-info, $uri, $register[1]/text(), $register[2]/text(), $register[3]/text(), $full-sent) 
  return fn:string-join($final-seq, " | ")
  
};

(:
deh:relation-head()
11/17/2023

Takes the results from deh:get-clause-pairs and returns the word which actually has the relation tag.

Some notes:

:)
declare function deh:relation-head($toks as array(*)*) as element()*
{
  for $tok in $toks
  where array:size($tok) > 1 
  return if (deh:is-subjunction-ldt($tok(1))) then ($tok(2)[1]) (:12/13/23 This may be temporary, but added the index for cases where multiple are posited:)
  else if (deh:is-subjunction-pr($tok(1))) then ($tok(1)[1])
  else ($tok(2)[1])
};

(:
deh:verb-headed-clause-sub()
10/26/2023

This function returns the subordinators in clauses where the verb is the head. If no head is found, usually nothing is returned, unless the clause is identified as having a missing ut; in that case, we still return the verb; this function can therefore be used to identify those.

If you want this function to consistently retrieve the subordinator, it will have to account for the fact that, in the LDT, if two verbs are coordinated within a clause, the verbs are siblings of the relative
The argument MUST be a verb which we already know is the head of a clause
:)
declare function deh:vhcs-main($tok as element())
{
  (:We don't want to get lost navigating the siblings and other parts of the tree if we don't have to: since the only reason the target subordinator would be among siblings is if coordination is involved, we :)
  let $sib := if (deh:return-parent($tok, 0)/deh:is-coordinating(.) and functx:contains-any-of($tok/fn:string(@relation), ("comp")) = false()) then (deh:return-siblings($tok, false())) else () 
  
  (:We combine all the possibilities together: the relative must be in either the descendants or the siblings' descendants, and if there is no relative in there, we return nothing:)
  let $sib-desc := (deh:return-descendants($sib), $sib) (:This is so we can check the descendants of the siblings in the condition below:)
  let $desc := (deh:return-descendants(($tok)), $sib-desc)
  
  (:If there are no relatives at all in the tree, then we need another explanation: either the ut had been deleted, which is tested for here, in which case we still return the verb as the head, or the function was not able to identify it:)
  return if ((fn:count(($desc)[deh:is-relative-no-ne(.)]) = 0)) then (
       if (deh:is-comp-clause($tok)) then ($tok) else ()
  ) (:If it has none of those parts of speech, just get rid of it before it ruins our loop:)
 
  
  else (  
   
  let $final-subs := deh:vhcs-recursion(($tok, $sib))
  
  (:let $final-subs := ($final-subs, deh:vhcs-coord-helper($tok)):) (:finally, add any potential siblings:)
  return if (fn:count($final-subs) = 0) then (
     if (deh:is-comp-clause($tok)) then ($tok) else ()
  )
  else ($final-subs)
)
};

(:
deh:vhcs-recursion()
11/5/2023

Deals with all the recursive functions
:)
declare %public function deh:vhcs-recursion($tok as element()*)
{
  let $nodes := deh:return-descendants($tok) (:We loop until we identify terms with the right lemma, and return the portion of the tree between the verb and those pronouns/subordinators;:)
  
  
  let $subs := ($nodes[deh:is-relative-no-ne(.)]) (:Since there can be more than one at the same level, we retrieve all of them:)

  (:For each, we identify the "thread" or all nodes between the subordinator and its head verb; if there is another finite verb between, we know it is not the right one, so we discard it as separate. We return all others:)
    for $sub in $subs
    let $thread := deh:vhcs-helper-b($sub, $tok[1] => deh:return-depth(1)) (:Loops deh:return-parent from the $sub until it reaches the $tok, and returns that sequence; I pass the siblings in as well. Since return-depth only works on one node, I pick the first in the sequence arbitrarily: all are siblings and will therefore be the same depth.:)
  
  (:This is the last point of failure: if a finite verb comes in the tree between our target verb and the head, then it must not be the head of the clause. This is the reason we return the results of the previous loop as 'final-subs'; we need to know that there are ZERO possible subordinators before testing for the clause missing an 'ut'; if we did this at each point in the loop, we wouldn't be able to know this. :)
  return if (fn:count($thread[deh:is-finite(.)]) > 1) then (
  )
  else ($sub)
};

(:
A recursive function which takes a target (a verb which is in a 'relative' clause) and finds the earliest relative in the tree. The second condition is, if it has reached the end of the tree, we don't want to get stuck in a loop, so we return nothing. Technically, this should be impossible, since the very first process in verb-headed-clause-sub() eliminates ones which do not have one of these. The final part, if we have still not reached a relative but are not terminal, simply walks down the tree one more step, adds those results to the previous results, and passes it all back through.
:)
declare function deh:vhcs-helper($tok as element()*)
{
  (:10/30/2023, $pos refers to lemmas now:)
  (:If there are any tokens:)
  if (fn:count($tok[deh:is-relative-no-ne(.)]) > 0) then (
    $tok
  )
  else if (fn:count($tok) = fn:count(functx:distinct-nodes(($tok, deh:return-children($tok))))) then () (:If there is no subordinator, and the loop has reached the terminal nodes, for now, let's return nothing:)
  else (functx:distinct-nodes(($tok, deh:return-children($tok))) => deh:vhcs-helper())
};

declare function deh:vhcs-helper-b($pronoun as element()*, $target-depth as xs:integer) as element()*
{
  (:A few conditions: either we have already reached the target depth and it is a sibling, we have yet to reach the target depth, or a depth of one has been reached and we need to exit:)
  if (boolean($pronoun[deh:return-depth(., 1) = $target-depth])) then ($pronoun) (:return to the results once we get back to the depth of the targeted verb:)
  else if (fn:count($pronoun[deh:return-depth(., 1) = 1]) > 0) then () (:if we get back to base, depth is 1; we cannot go any further back, so just return nothing here, because it clearly didn't work:)
  else (functx:distinct-nodes((deh:return-parent($pronoun, 0), $pronoun)) => deh:vhcs-helper-b($target-depth)) (:11/20/23: mostly unchanged here, just loops through:)
};


(:
deh:coord-helper()
11/5/2023
:)
declare function deh:vhcs-coord-helper($tok as element()) as item()*
{
   let $sib := if (deh:return-parent($tok, 0)/deh:is-coordinating(.)) then (deh:return-siblings($tok, false())) else () 
  
  (:We combine all the possibilities together: the relative must be in either the descendants or the siblings' descendants, and if there is no relative in there, we return nothing:)
  let $sib-desc := functx:distinct-nodes((deh:return-descendants($sib), $sib)) (:This is so we can check the descendants of the siblings in the condition below:)
  
  let $sib-rels := $sib-desc[deh:is-relative-no-ne(.)] (:the siblings (or children of siblings) which are relatives:)
  return if (fn:count($sib-rels) > 0) then (
    let $threads := $sib ! deh:vhcs-helper-b(deh:return-descendants($sib)[deh:is-relative-no-ne(.)], ./deh:return-depth(., 1)) (:Go through each sibling:)
    let $subs := for $thread in $threads where fn:count($thread[deh:is-finite(.)]) = 0 return $thread[deh:is-relative-no-ne(.)]
    return $subs
  )
  else ()  
};

(:
deh:is-comp-clause()
11/5/2023

This function is used in the verb-headed-clause-sub() function; it tests whether a verb is subjunctive and has the following tags: "SBJ", "OBJ", "NOM-SUBST", or "comp", which can include indirect questions and such, but that is why we test for this after ensuring the other possibilities don't match
:)
declare %public function deh:is-comp-clause($tok as element()?) as xs:boolean
{
  deh:is-subjunctive($tok) and functx:contains-any-of(fn:string($tok/@relation), ("SBJ", "OBJ", "NOM-SUBST", "comp"))
};

(:
deh:is-subjunctive()
11/3/2023
:)
declare function deh:is-subjunctive($tok as element()?) as xs:boolean
{
  fn:matches(fn:string($tok/@postag), "v[1-3]..s....") or fn:matches(fn:string($tok/@morphology), "...s......")
};



declare function deh:is-relative($tok as element()) as xs:boolean
{
   let $lemma := ('prout', 'quod', 'quantopere', 'quorsum', 'quacumque', 'quantuluscumque', 'quotiensque', 'quocumque', 'quotienscumque', 'ubinam', 'ecquid', 'qualiter', 'ecquis', 'quamdiu', 'prout', 'uter', 'quamobrem', 'quotquot', 'quotiens', 'quot', 'quanto', 'ubicumque', 'quisnam', 'cur', 'num', 'quoad', 'quisquis', 'qua', 'qualis', 'numquid', 'unde', 'quantum', 'tamquam', 'quando', 'quemadmodum', 'an', 'quare', 'quomodo', 'quantus', 'quo', 'quicumque', 'quam', 'sicut', 'ubi', 'quis', 'ne', 'cum', 'ut', 'qui', 'si', 'seu', 'sive', 'siue', 'qualiscumque', 'quonam') (:potential lemmas of subordinators 11/1/2023: instead of doing it manually, I put this in the deh:lem function; the reason is that tokens like loqui were getting flagged; 11/5/23, added prout and quod, since very rarely quod as a relative is lemmatized as quod, and prout had not already been included; 11/12/2023: added si, seu, sive siue because, when they are used to coordinate, they are usually not heads of the phrase; also added qualiscumque because it is rare and did not show up in PROIEL:)
   
   return fn:replace(fn:string($tok/@lemma), "[^a-z^A-Z]", "") = $lemma and functx:contains-any-of(deh:part-of-speech($tok), ("a", "d", "p", "n", "Pi", "Du", "Dq", "Pr", "Df")) and (deh:is-subjunction($tok) = false()) (:11/3/2023, this may break this, but I added "a" as a POS because of qualis; 11/5/23, temporarily (maybe) added "n" because sometimes pronouns are mistagged as nouns...; same day, added "Df" to account for 'sicut' sometimes being tagged as such:)
};


(:This function removes 'ne's' attached to neques and such; I only do this here because 'ne' still appears in main clauses, and I want to use deh:is-relative for that:)
declare function deh:is-relative-no-ne($tok as element()) as xs:boolean
{
  deh:is-relative($tok) and (($tok/fn:string(@form) = 'ne' and $tok/fn:string(@part-of-speech) = 'Df') = false())
};

(:
Another issue is that we need to make sure no verb comes between the target and pronoun: to do this, though, we first need to retrieve the nodes between the two. We walk the tree back up from the pronoun, and stop once we have the target, the verb.
:)



(:
10/26/2023
:)
declare function deh:part-of-speech($tok as element()) as xs:string
{
  if ($tok[boolean(@postag)]) then ($tok/fn:substring(fn:string(@postag), 1, 1))
  else if ($tok[boolean(@part-of-speech)]) then ($tok/fn:string(@part-of-speech))
  else ("")
};

(:
11/12/2023
:)
declare function deh:mood($tok as element()) as xs:string
{
  if ($tok/name() = 'word') then (fn:substring(fn:string($tok/@postag), 5, 1))
  else (fn:substring(fn:string($tok/@morphology), 4, 1))
};

(:
11/30/2023
deh:case()
:)
declare function deh:case($tok as element()) as xs:string
{
  if ($tok/name() = 'word') then (fn:substring(fn:string($tok/@postag), 8, 1))
  else (fn:substring(fn:string($tok/@morphology), 7, 1))
};

(:
10/31/2023 (spooky)
deh:is-subordinate()
:)

(:
11/1/2023:
deh:is-coordinating()

This function combines deh:is-punc and deh:is-conjunction and tests for both at the same time
:)
declare function deh:is-coordinating($tok as element()) as xs:boolean
{
  (:This first condition excludes ones containing AuxC, because 'ne' or 'neu' are also marked as COORD, but, when AuxC, do have the properties of 'ne' + the subjunctive:)
  if (fn:contains($tok/fn:string(@relation), "AuxC")) then (false())
  else (
    if (deh:lemma($tok, "ne")) then (fn:count(deh:return-children($tok)[deh:is-conjunction(.)]) > 0)
    (:seu/sive is a tricky situation: it can coordinate ordinary constituents, or whole conditional clauses. It is also commonly tagged as a :)
    else if (boolean(deh:return-children($tok)[deh:is-verb(.)]) and deh:lemma($tok, ("si", "seu", "sive", "siue"))) then (false())
     else (
    $tok/deh:is-conjunction(.) or $tok/deh:is-punc(.)) or ($tok/deh:is-empty(.) and $tok/fn:contains(fn:lower-case(fn:string(@relation)), 'apos')) (:11/5/23: testing this out, this recognizes the empty APOS token :)
 )
};

declare function deh:verb-headed-clause-sub($tok as element())
{
  let $subs := deh:vhcs-main($tok)
  return if (fn:count($subs) = 1) then ($subs)
    else (
      if (fn:count(fn:distinct-values($subs/deh:return-depth(., 1))) = fn:count($subs)) then (
        (:If the depths of each are different, we will pick the one with the lowest depth:)
        let $depths := $subs/deh:return-depth(., 1)
        for $depth at $n in $depths
        where $depth = fn:min($depths) (:pick the sub with the minimum depth in the tree, which must be closest to the verb:)
        return $subs[$n]
      )
      else (
        let $left-subs := $subs[functx:is-node-in-sequence(., $tok/preceding-sibling::*)]
       return $left-subs[fn:number(@id) = fn:max($left-subs/fn:number(@id))]
     )
   )
      
     (:First, we go through the process of finding the options highest in the tree:)
     (:Nixing this for now; linear order should be a better method!
    let $target-depth := deh:return-depth($tok, 1)
    let $depths :=
    for $sub in $subs
    return array{$sub, deh:return-depth($sub, 1)}
    let $min := $depths?2 => fn:min()
    
    let $highest-subs :=
    for $depth in $depths
    where $depth(2) = $min
    return $depth(1)
    :)
    (:If there are still several options, we pick the one furthest to the right be still to the left of the target:)
};

(:
deh:is-empty
11/5/2023

Used to test for an empty node; does this by seeing if there is an empty-token-sort attribute (for PROIEL) or an insertion_id (for the LDT)
:)
declare function deh:is-empty($tok as element()) as xs:boolean
{
  boolean($tok/@empty-token-sort) or boolean($tok/@insertion_id)
};

(:
deh:db-get-from-path()
11/8/2023

@param: $string: the path retrieved when using fn:base-uri() on a databse; this function is used to parse the base-uri retrieved in the var-info function
:)
declare function deh:db-get-from-path($string as xs:string)
{
  let $first := fn:substring-after($string, "/") => fn:substring-before("/")
  return db:get($first, functx:substring-after-last($string, "/"))
};

(:
11/12/2023
deh:return-semfield()

Returns all lemmas in a semfield who has less than $limit total semfields associated with it

$semfield: string which is the number of the targeted semfield
$limit: the greatest number of possible different semfields the lemma can have
:)
declare function deh:return-semfield($semfield as xs:string, $limit as xs:integer) as item()*
{
  let $json:= json:doc(fn:concat("https://latinwordnet.exeter.ac.uk/api/semfields/", $semfield, "/lemmas/"))
  let $lemmas := $json//lemma/text()
  for $lemma in $lemmas
  let $semfields-doc := json:doc(fn:concat("https://latinwordnet.exeter.ac.uk/api/lemmas/", $lemma, "/synsets/"))
  let $semfields := fn:distinct-values($semfields-doc//semfield//code/text())
  return if (fn:count($semfields) <= $limit) then ($lemma) else ()
};

(:
11/12/2023

Got fed up looking up lemmas the hard way: this one takes care of accounting for numbers and such. It checks to see if any numeric characters are present to determine whether to search the lemma as it is in the tree or to remove all the non-alphabetic characters. Remember that this removes spaces too! You don't have to account for ante quam vs. antequam
:)
declare %public function deh:single-lemma($tok as element(), $search as xs:string) as xs:boolean
{
  let $lemma := 
  if (fn:matches($search, "[0-9]")) then ($tok/fn:string(@lemma))
  else (deh:process-lemma($tok/fn:string(@lemma)))
  
  return fn:matches($lemma, fn:concat("^", $search, "$"))
};

declare function deh:process-lemma($lemmas as xs:string*)
{
  for $lemma in $lemmas
  return fn:lower-case(fn:replace($lemma, "[#0-9,]", ""))
};

(:
deh:lemma()
11/20/2023

Got fed up looking up lemmas the hard way: this one takes care of accounting for numbers and such. It checks to see if any numeric characters are present to determine whether to search the lemma as it is in the tree or to remove all the non-alphabetic characters. (11/20 note: this description is copied over from deh:single-lemma, which was the original deh:lemma function) This function will now return true if the lemma matches any of the provided strings.

Depends on:
deh:single-lemma()
:)
declare function deh:lemma($tok as element(), $search-seq as item()*) as xs:boolean
{
  (:Get whether each is :)
  fn:count(for $string in $search-seq where deh:single-lemma($tok, $string) return $string) > 0
};

declare function deh:lemma-or-form($tok as element(), $search-seq as item()*) as xs:boolean
{
  deh:lemma($tok, $search-seq) or fn:count(for $search in $search-seq where fn:matches(fn:lower-case($tok/fn:string(@form)), fn:concat('^', $search, '$')) return $search) > 0
};

(:
deh:word-count()
11/30/2023

Gives the word count for a work, which excludes empty tokens and punctuation
:)
declare function deh:word-count($node as node()*) as xs:integer
{
  deh:tokens-from-unk($node)[deh:is-punc(.) = false() and deh:is-empty(.) = false()] => fn:count()  
};

(:
1/27/24:
deh:position()

Gets the number of tokens in a sentence before the given token, excluding punctuation or empty nodes
:)
declare function deh:position($toks as element()*) as xs:integer*
{
   for $node in $toks
   return deh:word-count($node/preceding-sibling::*)
};

(:
1/27/2024:
deh:normed-position()
Returns the number of words before another word in a sentence divided by the total words in the sentence. Excludes punctuation and empty nodes
:)
declare function deh:normed-position($toks as element()*) as xs:double*
{
  for $tok in $toks
  return deh:position($tok) div deh:word-count($tok/..)
};
(:-------------------------------------END of utility functions-----------------------------------------------:)

(:-------------------------------------START of corpus division functions--------------------------------------------:)

declare function deh:get-short-name($title as xs:string) as xs:string*
{
  let $shorts := deh:short-names()
  for $short in $shorts
  where fn:matches($title, $short)
  return if (fn:string-length($short) > 1) then ($short)
  else ("UNK")
};

(:
Note these short names are set up to work in a regex, which means the fn:matches function is most called for
:)
declare function deh:short-names() as xs:string*
{
  ("Elegie", "Elegia", "Sati", "Att", "Pere", "Carm", "Amor","Res", "Cael", "(In Cat|Against C)", "off", "Petr Speech", "Petr Narr","Fab", "Gall", "Vul", "Aen", "Met", "Aug", "Ann", "agri", "Hist")
};

(:In this section, each function returns a part of the corpus we want to study. The naming scheme has a prefix with the general type (pers for persona, aud for audience and gen for genre), and the suffix is the subtype:)

(:This function just returns all the trees together as databases, so that we can use them here without relying on the variables like in the agldt_search:)

declare %public function deh:get-trees()
{
  (db:get('ldt2.1-treebanks'), db:get('harrington'), db:get('proiel'))
};

declare function deh:pers-ind()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Elegi", "Sati", "Att", "Pere", "Carm", "Amor"))]
};

declare function deh:pers-pub()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Res", "Cael", "In Cat", "off", "Petr"))]
};

declare function deh:pers-dist()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Fab", "Gall", "Vul", "Aen", "Met", "Aug", "Ann", "agri", "Hist"))]
};

declare function deh:aud-priv()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Pere", "Att"))]
};

declare function deh:aud-elite()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("off", "In Cat", "Cael", "Sati", "Elegi", "Gall", "Aen", "Met", "Petr", "Aug", "Ann", "Carm", "Amor", "Hist"))]
};

declare function deh:aud-large()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Res", "Fab", "agri", "Vul"))]
};

declare function deh:gen-poet()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("Fab", "Elegi", "Sati", "Aen", "Met", "Carm", "Amor"))]
};

declare function deh:gen-prose()
{
  let $all-trees := deh:get-trees()
  return $all-trees[functx:contains-any-of(deh:work-info(.)(1), ("In Cat", "Cael", "Att", "off", "agri", "Res", "Gall", "Vul", "Aug", "Ann", "Hist", "Pere", "Petr"))]
};

declare function deh:get-genre($corpus as node()) as xs:string
{
  let $work-info := deh:work-info($corpus)(1)
  return if (functx:contains-any-of($work-info, ("Fab", "Elegi", "Sati", "Aen", "Met", "Carm", "Amor"))) then ('poetry')
  else ('prose')
};

(:

11/13/2023
:)
declare function deh:is-adverbial($tok as element()) as xs:boolean
{
  (:ADV
$adv := ("D-INTER", "D-POSS", "D-AGENT", "D-Purp", "A-ORIENT", "A-EXTENT", "A-RESPECT", "A-ADVERB", "D-PURP", "AB-ORIENT", "AB-SEPAR", "AB-CAUSE", "AB-ABSOL", "AB-COMPAR", "AB-LOCAT", "AB-ACCOMP", "AB-MEANS", "AB-MANN") 10/15, STOPPED AT A-RESPECT! 11/1, WHICH I THINK IT ADVERBIAL, it is rare, but was never ATR; YES, note the sentence: hic primum nigrantis terga iuvencos constituit, the terga is an ADV; also note that things like Ablative or Orientation are likely with prepositions, although I haven't checked; 11/7/23, NOT SURE HOW PRICE WORKS! Same with AB-DEGDIF, don't really care about it; also note that an aux from PROIEL or AuxZ/AuxY:)
 
    (deh:part-of-speech($tok) = ('d', 'Df', 'Du', 'Dq') or functx:contains-any-of($tok/fn:string(@relation), ("D-INTER", "D-POSS", "D-AGENT", "D-Purp", "A-ORIENT", "A-EXTENT", "A-RESPECT", "A-ADVERB", "D-PURP", "AB-ORIENT", "AB-SEPAR", "AB-CAUSE", "AB-ABSOL", "AB-COMPAR", "AB-LOCAT", "AB-ACCOMP", "AB-MEANS", "AB-MANN", 'adv', 'ADV', 'aux', 'AuxY', 'AuxZ'))) and deh:is-verb($tok) = false() and deh:is-subjunction($tok) = false() and deh:is-coordinating($tok) = false()

};

(:
deh:is-particle
12/13/23:

Retrieves all "aux"'s which are not sum. Also remember that 'non' is included as well
:)
declare function deh:is-particle($tok as element()) as xs:boolean
{
  $tok/fn:string(@relation) = ('aux', 'AuxY', 'AuxZ') and deh:lemma($tok, 'sum') = false()
};

(:
Tells whether an adverb is actually a subordinating conjunction
:)
declare function deh:is-subordinating-relative($tok as element()) as xs:boolean
{
  let $finite-heads := deh:finite-clause-verb-head($tok/..)
  (:We need to double check it is an adverb and not a subordinator. If there are no verb-headed clauses, do nothing; if so, see if the target matches any verb-headed clause subordinators:)
  return if (fn:count($finite-heads) > 0) then (let $vhcs := $finite-heads/deh:verb-headed-clause-sub(.)  return functx:is-node-in-sequence($tok, $vhcs))
  else (false())
};



(:-------------------------------------END of corpus division functions--------------------------------------------:)

(:------------------------------------START of specific construction functions----------------------------------------:)
(:
deh:quamobrem()
11/12/2023

A function which identifies a relative as actually being in "quam ob rem"
:)
declare function deh:quamobrem($tok as element()) 
{
  let $form := fn:lower-case($tok/fn:string(@form))
  (:"quamobrem" does not seem to be tokenized as one word in LDT or Harrington, but in PROIEL it is as "quamobrem", both in main clauses and as a subordinator. The "quam" is always considered a relative for lemmatization. Otherwise, the parent being 'rem' and grandparent being 'ob' should be consistent across all (PROIEL does have an example like this):)
  return if (fn:contains($form, 'quam') = false()) then (false())
  else if (fn:contains(fn:lower-case($tok/fn:string(@lemma)), 'quamobrem')) then (true())
  else (
    if ($form = 'quam') then (
      let $parent := deh:return-parent($tok, 0)
      let $g-parent := deh:return-parent($parent, 0)
      let $string := fn:string-join(($tok/fn:string(@form), $parent/fn:string(@form), $g-parent/fn:string(@form)), "")
      return if (fn:lower-case($string) = "quamremob") then (true())
      else (false())
    )
    else (false())
  )
};

(:
deh:quemadmodum()
11/12/2023

Identifies quemadmodum in the trees
:)
declare function deh:quemadmodum($tok as element()) as xs:boolean
{
  (:In PROIEL, quemadmodum as a lemma is in use (see quamobrem above). :)
};

(:
deh:get-subordinators()
11/21/2023

Retrieves the results from deh:finite-clause and returns the subordinators for the verb-headed clauses together with the subordinator-headed clauses
:)
declare function deh:get-subordinators($nodes as node()*) as element()*
{
  (:Get all the finite clauses:)
  let $clauses := deh:finite-clause($nodes, false())
  
  (:Separate into the ones with a subordinator as a head and those without, which we need to pass to verb-headed-clause-sub to retrieve the subordinator:)
  let $sub-head := $clauses[deh:is-subjunction(.)]
  let $verb-head := $clauses[deh:is-subjunction(.) = false()] => deh:verb-headed-clause-sub()
  
  return ($sub-head, $verb-head)
};

(:
deh:causal-clause()
11/17/2023

Retrieve all the causal clauses under consideration, based on get-clause-pairs. The easy ones:

quod, quia, quoniam causal 
:)
declare function deh:causal-clause($nodes as array(*)*)
{
  (:Notes:
  REDO THE BELOW. You need to use the functions you designed to get the clause's role: otherwise, quod/quia as complement clauses will also be included. 
  :)
  
  (:Get all the causal clauses; just quoniam, quod or quia. Luckily, the lemma quod is restricted to the causal construction (in PROIEL, quod#1 is only in 'quod si', quod#2 I don't totally understand but only occurs 5 times, and that is it. Neither of the other two subordinators have alternatives. Also note Pinkster's OLS v.1 p. 912: 'cum' can be causal with some of the particples like propterea, but only in Later Latin, and a search of the corpus revealed no instances here:)
  let $clauses := $nodes[deh:lemma-or-form(.(1), ("quoniam", "quod", "quia"))]
  
  for $clause in $clauses
  let $rel-head := deh:relation-head($clause)[1]/fn:lower-case(fn:string(@relation))
  (:We need to make sure they are causal, because both quod and quia can govern complement clauses. :)
  return if ($rel-head => fn:contains("adv")) (:Added a '[1]' to deh:relation-head because it could potentially return multiple:) then ($clause)
  (: It should only be apos after ideo, propterea, idcirco, ob eam causam (and quas ob causas) (you have to just check for a grandfather of "ob", because it may use an empty APOS token. That is the end of the list, because I checked:)
  else if ($rel-head => functx:contains-any-of(("apos", "-ap"))) (:It is APOS in both trees, but there can also be the -AP suffix in Harrington, which I think sometimes occurs in the main LDT:) then (
     let $parent := deh:return-parent(deh:phrase-head($clause), 0)
     (:Possibility one: the parent is ideo, propterea, hoc (hic), also added id (although I did not test it), or idcirco:)
     return if (deh:lemma($parent, ('ideo', 'propterea', 'idcirco', 'is'))) (:Removed 'hic' here, 1/20/24:)
       then ($clause)
     (:possibility two: the grandparent is the preposition 'ob'; I cannot imagine this would ever not work:)
     else if (($parent => deh:return-parent-nocoord())/deh:lemma(., 'ob')) then ($clause)
     else ()
  )
  else ()
  
};

(:
works with deh:get-clause-pairs results
:)
declare function deh:phrase-head($pairs as array(*)*)
{
  for $pair in $pairs
  return if (deh:is-subjunction($pair(1))) then ($pair(1))
  else ($pair(2))
};

(:
deh:test-vectors-11-23()
11/21/2023

This is a function to test some of the statistical manipulation I would like to do.
@param $nodes: a set of treebank documents
:)
declare function deh:test-vectors-11-23($nodes as node()*) as item()*
{
  for $doc in $nodes
  (:Work info:)
  let $work-info := deh:get-short-name(deh:work-info($doc)(1))
  
  (:URI:)
  let $uri := fn:base-uri($doc)
  
  (:Main clauses:)
  (:Subordinate clauses:)
  return()
  
};

(:
deh:get-clause-pairs()
11/22/2023

Takes a series of nodes (could be sentence or document level as well) and returns uses deh:finite-clause on it, returning each result as a series of arrays where the first item is the subordinator and the second the verb. KEEP IN MIND THAT THIS CAN RETURN EMPTY SEQUENCES IN THE SECOND SLOT, so array:size is not enough to process the results
:)
declare function deh:get-clause-pairs($nodes as node()*) as item()*
{
  let $clauses := deh:finite-clause($nodes, false())
  
  (:Get the verb-subordinator pairs; first item in each array is the subordinator, the second the verb:)
  let $pairs :=
  for $clause in $clauses
  return if (deh:is-subjunction($clause)) then ([$clause, (deh:get-auxc-verb($clause))]) (:Used the square array constructor, since this allows whole sequences to be members:)
  else (array{deh:verb-headed-clause-sub($clause)[1], $clause}) (:Added the '[1]' to make sure there are not multiple results:)
  
  (:Now, let us remove duplicates:)
  for $pair in $pairs
  where fn:count(functx:index-of-node($pairs?1, $pair(1)[1])) = 1
  return $pair
  
};

(:
1/13/24
deh:headless-clause()

Relies on vhcs: if both nodes in the clause pair are the same, it must be a headless ut clause
:)
declare function deh:headless-clause($pairs as array(*)*) as array(*)*
{
  for $pair in $pairs
  where array:size($pair) > 1 (:Test this so we don't get an 'index out of range' error:)
  return if (fn:deep-equal($pair?1[1], $pair?2[1])) (:Added the selectors because sometimes something gets screwed up and there are multiple subordinators or verbs:)
  then (
    array{<token lemma="(ut)" form="(ut)"></token>, $pair?2[1]} (:Return the array so that the subordinator is now marked as a headless 'ut' with the parentheses:)
  )
  else ()
};

(:
deh:clause-pair-rel()
11/22/2023

Takes results from deh:get-clause-pairs 
:)
declare function deh:clause-pair-rel($clause-pair as array(*)) as xs:string
{
  if ($clause-pair(1)[1]/deh:is-subjunction-pr(.)) then ($clause-pair(1)[1]/fn:string(@relation))
  else ($clause-pair(2)[1]/fn:string(@relation))
};

(:The following three functions separate suborindate clauses:)
(:
deh:adverbial-clause()

See the note on deh:adjectival clause on the sequence
:)
declare function deh:adverbial-clause($pairs as array(*)*) as array(*)*
{
  for $pair in $pairs
  where (functx:contains-any-of(deh:relation-head($pair)/fn:lower-case(fn:string(@relation)), ("adv"))) and fn:count(deh:complement-clause($pair)) = 0
  return $pair
};

(:
12/13/2023
deh:complement-clause()

Really includes any argument clause/clause used as a noun, so it can also include relative clauses with no antecedent

:)
declare function deh:complement-clause($pairs as array(*)*) as array(*)*
{
  for $pair in $pairs
  where functx:contains-any-of(deh:relation-head($pair)/fn:lower-case(fn:string(@relation)), ("comp", 'obj', 'sbj', 'sub', 'subj', 'pnom', 'xobj', 'n-pred', 'a-pred', 'narg')) (:voc must stand in for a noun, narg is rare but actl:)
  return $pair
};

(:
12/13/2023
deh:adjectival-clause()

There is also a level of precedence, where, if a clause is idenfitied as a complement clause, it will not be identified as another, and if an adverbial clause is identified, it cannot be identified as an adjectival clause
:)
declare function deh:adjectival-clause($pairs as array(*)*) as array(*)*
{
   for $pair in $pairs
  where (functx:contains-any-of(deh:relation-head($pair)/fn:lower-case(fn:string(@relation)), ('atr', 'apos', 'adj', 'rel'))) and fn:count((deh:complement-clause($pair), deh:adverbial-clause($pair))) = 0 (:exclude ut clauses:)
  return $pair
};

declare function deh:unique-pairs($pairs as array(*)*) as array(*)*
{
  for $tok at $n in $pairs
  where (functx:is-node-in-sequence($tok?1, $pairs[position() < $n]?1) = false()) and (functx:is-node-in-sequence($tok?2[1], $pairs[position() < $n]?2) = false()) 
  return $pairs[$n]
};

(:
deh:temporal-clause()
11/21/2023

Retrieves all the temporal clauses in the corpus

:)
declare function deh:temporal-clause($clause-pairs as array(*)*)
{
  (:let $clause-pairs := deh:get-clause-pairs($nodes)eliminated 11/29 because this now only accepts an array:)
  
  let $w-indicative-temp := ("cum", "cumque", "ut(i|)")
  let $temporal := ("ubi(que|)(nam|)", "ubicumque", "quando", "dum", "donec", "dummodo", "modo", "antequam", "posteaquam", "postmodum quam", "postquam", "priusquam", "quotiens", "quotiens(cum|)que")
  (:also check the parent-lemma column with 'quam' for "ante" or "prius" or "post" or "postea":)	
  let $separable := ('ante', 'prius', 'postea', 'postmodum', 'post')
  
 
  let $temporal-ind-final :=
  for $target in $w-indicative-temp
  let $temp-pairs := $clause-pairs[.(1) => deh:lemma($target)]
  for $item in $temp-pairs
  return if (fn:matches($item(1)/deh:work-info(.)(1), "Pere") and $item(1)/deh:lemma(., ("cum", "cumque"))) then ($item)
  else if ($item(2)/deh:mood(.) = 'i') then ($item)
  
  
  
  let $temporal-final :=
  for $target in $temporal
  let $pairs := $clause-pairs[.(1) => deh:lemma($target)]
  for $pair in $pairs
  return array:append($pair, $pair(1)/fn:string(@lemma)) (:This was added so the lemma for the combined ones (antequam, etc.) is included; I'm just doing it to all of them for simplicity:)
  
  
  let $separable-temporal :=
  for $target in $separable
  return $clause-pairs[.(1) => deh:lemma('quam') and (.(1) => deh:return-parent-nocoord())/fn:string(@form) = $target or deh:return-children(.(1))[fn:contains(fn:string(@relation), "AuxZ")]/fn:string(@form) = $target] ! array:append(., ($target || 'quam')) (:Added this little thing at the end so there is a way of :)
  
  let $temporal-results := deh:unique-pairs(($temporal-final, $separable-temporal, $temporal-ind-final))
  
  return $temporal-results
};

(:
deh:spatio-temporal-adverb()
11/27/2023

@param $use-voc: If true, locatives will be included in spatial adverbs
:)
declare function deh:spatio-temporal-adverb($nodes as node()*, $use-loc as xs:boolean) as array(*)*
{
  (:12/3/2023: removed the "clause" ones:)
  let $toks := deh:tokens-from-unk($nodes)
  (:Explanation of the below: there are temporal, spatial and mixed, the mixed being those which have both a spatial and temporal meaning. That is not to say all the $temporal and $spatial are totally unambiguous, but if they are, it is not between space and time. The -unamb are those who can be distinguished unambiguously simply by their lemma; for any others, we will need to look to the relation tags for disambiguation:)
  let $temporal-unamb :=('nunc', 'tunc', 'mox', 'iam', 'diu', 'dudum', 'pridem', 'primum', 'primo', 'deinde', 'postea', 'postremo', 'umquam', 'numquam', 'semper', 'aliquando', 'hodie', 'heri', 'cras', 'pridie', 'postridie', 'nondum', 'necdum', 'vixdum', 'temperi', 'vesperi', 'noctu', 'antea', 'statim', 'nuper', 'abhinc', 'breviter', 'usqui', 'mani', 'semel', 'saepius', 'aliquotiens', 'iterum', 'denuo', 'rursus', 'adhuc')
  let $temporal-amb := ('perpetuo', 'perpetuum', 'aeternum', 'postremo', 'postremum')
  let $mixed := ('hinc', 'ibi', 'eo2','eo#2', 'inde', 'usque', 'ultra', 'porro', 'retrorsum', 'ibidem', 'prope', 'ilico')
  
  (:Removing for now, causing too much trouble let $mixed-clause := ('ubi', 'unde'):)
  let $spatial-unamb := ('hic2', 'huc','istic', 'istuc', 'istinc', 'illic', 'illuc', 'illinc', 'illac', 'alicubi', 'aliquo', 'alicunde', 'eodem', 'indidem', 'alibi', 'aliunde', 'usquam', 'nusquam', 'citro', 'horsum', 'prorsum', 'introrsum', 'sursum', 'deorsum', 'seorsum', 'aliorsum', 'contra', 'procul', 'intus', 'longe', 'utrimque', 'foras', 'extra', 'peregre', 'intra', 'dehinc', 'exinde', 'extrinsecus')
  let $spatial-clause := ('ubiubi', 'quoquo', 'undecumque', 'quaqua') (:provided on Allen & Greenough p. 123:)
  let $spatial-amb := ('hac', 'ea', 'ista', 'aliqua', 'eadem', 'alio', 'alia', 'recta',  'intro', 'foris') (:1/20/24, removed hic:)
  
  (:Both the unambiguous ones, and the ambiguous, where we check if it may have the right tags:)
  let $temporal := (
    $toks[deh:lemma(., $temporal-unamb)], 
    $toks[deh:is-adverbial(.) and deh:lemma-or-form(., $temporal-amb)]
  )
  
  
  let $mixed := (
    $toks[deh:lemma(., $mixed) and deh:is-adverbial(.)]
    (:for $tok in $toks where deh:lemma($tok, $mixed-clause) return $tok[deh:is-subordinating-relative(.) = false() and deh:is-question-sentence(./..) = false() and functx:is-node-in-sequence(., deh:finite-clause(./.., false())) = false()] make sure the potentially subordinating ones are not actually subordinating; this means eliminating whether it is the head of a clause as an AuxC/G- or as a relative adverb, and eliminating it if it is a question. Is-subordinating-relative covers the first of those potentials, and the last boolean covers whether it is an AuxC/G-:)
  )
  
  let $spatial := (
    $toks[deh:lemma(., $spatial-unamb)], 
    for $tok in $toks 
    where deh:lemma($tok, $spatial-clause) 
    return $tok[deh:is-subordinating-relative(.) = false() and deh:is-question-sentence(./..) = false() and functx:is-node-in-sequence(., deh:finite-clause(./.., false())) = false()],
    $toks[deh:is-adverbial(.) and deh:lemma-or-form(., $spatial-amb)],
    if ($use-loc) then ($toks[deh:case(.) = 'l'] (:Accounts for the locative:))
  )
  
  (:Make sure each is properly labeled:)
  let $temporal-final := for $item in $temporal return array{$item, 'temporal'}
  let $spatial-final := for $item in $spatial return array{$item, 'spatial'}
  let $mixed-final := for $item in $mixed return array{$item, 'mixed-spatial-temporal'}
  
  
  return ($temporal-final, $spatial-final, $mixed-final)
    
  
  (:Prepositions: 'adversum', 'ante', 'circiter', 'cis', 'citra', 'infra', 'contra', 'intra', 'pone', 'prope', 'tenus', 'ultra', 'post':)
};

declare function deh:spatial-clause($clause-pairs as array(*)*)
{
  let $lemmas := ('quatenus', 'quo', 'quorsum', 'utroque', 'ubiubi', 'quoquo', 'undecumque', 'quaqua', 'sicubi', 'siquo', 'sicunde', 'siqua')
  
   
    return $clause-pairs[.(1) => deh:lemma($lemmas)]
};


(:
deh:causal-adverb()
11/20/2023

:)
declare function deh:causal-adverb($nodes as node()*) as item()*
{
  let $adverbs := ('enim', 'ergo', 'ideo', 'igitur', 'idcirco', 'propterea') (:I'm avoiding autem here for its varied uses:)
  let $inter-adverbs := ('quare',  'quamobrem', 'unde', 'quapropter') (:all but unde and quapropter can be separate tokens in this corpus:)
  (:then account for ob eam rem or quamobrem:)
  
  let $toks := deh:tokens-from-unk($nodes)
  
  let $non-subordinators := $toks[deh:lemma-or-form(., ($adverbs))]
  let $subordinators := $toks[deh:lemma-or-form(., $inter-adverbs)] => deh:is-not-interrogative()
  
  return ($non-subordinators, $subordinators)
};

(:
This function accepts a token which we suspect could be interrogative or just an adverb (like quare), and returns it only if it is not an interrogative. This removes ones which are the heads of subordinate clauses or in questions
:)
declare function deh:is-not-interrogative($toks as element()*)
{
  for $adv in $toks
  where deh:is-question-sentence($adv/..) = false()
  let $clause-pairs := deh:get-clause-pairs($adv/..)
  return if (fn:count($clause-pairs) > 0) then ($adv[functx:is-node-in-sequence($adv, $clause-pairs?(1)) = false]/..)
  else ($adv)
};

(:
deh:purpose-clause()
11/22/2023
:)
declare function deh:purpose-clause($clause-pairs as array(*)*)
{
  
  let $w-subj := ("ne", "neu", "neve", "necubi", "nequando", "ut(i|)")
  
  for $target in $w-subj
  return $clause-pairs[.(1) => deh:lemma($target) and .(2)[1] => deh:mood() = 's' and fn:contains(deh:clause-pair-rel(.), 'adv')]
};

(:
deh:object-clause()
11/22/2023


:)
declare function deh:object-clause($clause-pairs as array(*)*)
{
  
  let $w-subj := ("ne", "neu", "neve", "necubi", "nequando", "ut(i|)")
  
  for $target in $w-subj
  return $clause-pairs[.(1) => deh:lemma($target) and .(2)[1] => deh:mood() = 's' and functx:contains-any-of(deh:clause-pair-rel(.), ("comp", "obj", "sbj"))]
};

declare function deh:conditional-clause($clause-pairs as array(*)*)
{
  
  let $conditional := ("(ni|)si(n|)(ve|)", "ni", "si non", 'siqua')
  
  for $target in $conditional
  return $clause-pairs[.(1) => deh:lemma($target)]
};

(:
deh:is-in-question()
11/20/2023

Says if the targeted word has a question mark among its descendants
:)
declare function deh:is-in-question($tok as element()) as xs:boolean
{
  let $desc := deh:return-descendants($tok)
  return fn:count($desc[deh:has-question-mark(.)]) > 0
};

(:
deh:is-question-sentence()
11/20/2023

Looks for a question mark at the end of a sentence: in PROIEL, the last tag without @empty-token-sort's @presentation-after. We want to see if the WHOLE sentence ends in a question mark, and since PROIEL has a tendency to pile empty tokens at the end, we have to look to the last non-empty token in the sentence in that case; in the LDT, we have to look for the last without @insertion_id
:)
declare function deh:is-question-sentence($sent as element(sentence)) as xs:boolean
{
  (:Separate if LDT:)
  let $tokens :=
  if (boolean($sent/word)) then ($sent/word[boolean(./@insertion_id) = false() and (fn:contains(./fn:string(@relation), 'AuxG')) = false()])  (:Like PROIEL, I forgot the LDT likes to case empty tokens to the end, so let us do this. Let us also exclude punctuation: if the question mark makes it to the end of the sentence, then it is likely not just inset:)
  
  (:Separate if PROIEL:)
  else if (boolean($sent/token)) then ($sent/token[boolean(./@empty-token-sort) = false()]) (:First, tokens are only non-empty ones, so we can find the true last word in the sentence.  :)
  
  return $tokens[fn:count($tokens)] => deh:has-question-mark() (:Finally, see if the last token is or has a question mark:)
};


(:
deh:has-question-mark()
11/20/2023

Checks if a token is/has a question mark individually. So, if LDT, the form has a question mark, or if PROIEL, @presentation-after does
:)
declare function deh:has-question-mark($tok as element()?) as xs:boolean
{
  (:If LDT, we just see if there is a question-mark in the @form field, and if PROIEL, if there is a ? in @presentation after:)
  fn:contains($tok/fn:string(@form), "?") or fn:contains($tok/fn:string(@presentation-after), "?")
};

declare function deh:process-count-results($arrays as array(*)*, $work-length as xs:double)  
{
  let $distinct := fn:count($arrays)
  let $occurences := for $array in $arrays?* return ($array(2) div $work-length) * 10000
  let $parataxis-val := $distinct div stats:stdev($occurences)
  let $total-occurence := fn:fold-left($arrays?*?2, 0, function($a, $b){$a + $b})
  return array{$parataxis-val, $total-occurence}
};

(:
12/20/2023

Retrieves coordinating conjunctions which coordinate clauses
:)
declare function deh:clause-coordination($sents as element(sentence)*) as element()*
{
  for $sent in $sents
  let $toks := $sent/*[deh:lemma(., ("que", "-que", "ac", "atque", "et", "nec", "neque", "sed", "at"))]
  (:Checks if finite (or periphrastic participle) or a subordinating conjunctions; otherwise, if that is not enough, it is probably a sentence adverbial and therefore labeled 'aux' (although we need to exclude instances of 'neque,' because that will be aux no matter what). Sometimes, it may coordinate a part of the sentence with no verb with the main verb, so I added the last condition to check for a parent.:)
  return $toks[fn:count(deh:return-children-nocoord(.)[deh:is-finite(.) or deh:is-periphrastic-p(.) or deh:is-subjunction(.)]) > 1 or (fn:contains(fn:lower-case(fn:string(@relation)), "aux") and deh:return-parent(., 0)/deh:lemma(., 'ne') = false()) or boolean(deh:return-parent(., 0)) = false()]
};

(:
deh:ablative-absolute()
1/31/2024

Returns the number of ablative absolutes

:)
declare function deh:ablative-absolute($nodes as node()*) as xs:integer
{
  let $toks := deh:tokens-from-unk($nodes)
  return fn:count($toks[deh:is-ablabs(.)])
  (:Harrington: ABL-ABSOL, :)
};

declare function deh:is-ablabs($tok as element()) as xs:boolean
{
  (:Harrington: must have the tag "ABL-ABSOL" but not have a parent with that tag too:)
  
  
  (:LDT, there is an ablative participle with 'adv' tag or some other ablative with 'adv' tag and 'atv' dependent on it:)
  if ($tok/name() = 'word') then (
    ($tok/fn:string(@relation) = 'ABL-ABSOL' and deh:return-parent-nocoord($tok)/fn:string(@relation) != 'ABL-ABSOL') (:We don't want to count the subject and participle as two ablative absolutes:) or ($tok/fn:contains(fn:string(@relation), 'ADV') and deh:case($tok) = 'b' and (deh:mood($tok) = 'p' or fn:count(deh:return-children-nocoord($tok)[fn:contains(fn:string(@relation), 'ATV')]) > 0))
)
  (:PROIEL: easy, any ablative with the 'sub' tag is in an ablative absolute:)
  else (deh:case($tok) = 'b' and $tok/fn:string(@relation) = 'sub')
  
};
