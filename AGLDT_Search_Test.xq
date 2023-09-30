xquery version "3.1";

(:NOTE THAT, FOR THE BASEX IMPLEMENTATION, SET WRITEBACK true IS NECESSARY FOR THIS TO WORK:)

import module namespace functx = "http://www.functx.com" at "http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq";
(:In case it is being weird, get functx from:
C:/Program Files (x86)/BaseX/src/functx_lib.xqm
Website is:
http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

(: This module MUST be stored in the same folder; both should be in my GitHub repository:)
import module namespace deh = "https://www.youtube.com/channel/UCjpnvbQy_togZemPnQ_Gg9A" at "./agldt_search.xqm";
(:

ADD A REFERENCE TO THE GNU LGPL 3.0 LICENSE HERE, SINCE THE FUNCTX LIBRARY IS COVERED UNDER THAT LICENSE? However, it is available in free and proprietary software, so I would not be worried about coverage

AGLDT Search Tool 0.1

Specs:

Unique address of any word in any file can be found by filename, sentence id and word id, so that is the important information to save.

I copy the following info from the PerseusDL/treebank_data space on GitHub:

1: 	part of speech: n	noun, v	verb, t	participle, a	adjective, d	adverb, c	conjunction, r	preposition, p	pronoun, m	numeral, i	interjection, e	exclamation, u	punctuation

			2: 	person, 1	first person, 2	second person, 3	third person

			3: 	number, s	singular, p	plural

			4: 	tense, p	present, i	imperfect, r	perfect, l	pluperfect, t	future perfect, f	future

			5: 	mood, i	indicative, s	subjunctive, n	infinitive, m	imperative, p	participle, d	gerund, g	gerundive, u	supine

			6: 	voice, a	active, p	passive

			7:	gender, m	masculine, f	feminine, n	neuter

			8: 	case, n	nominative, g	genitive, d	dative, a	accusative, b	ablative, v	vocative, l	locative

			9: 	degree, c	comparative, s	superlative

List of "relation" types: 
PRED, SBJ, OBJ, ATR (adj., rel. clause, non-argument member of noun-phrase (but also not ATV)), ADV (used of many satellites, including ablatives and prep. phrases), AuxP(prepositions), AuxC (subordinating conjunction), AuxY(sentence adverbial, "disjunct"), AuxZ (emphasizing particles, adverbs, quantity pronounts), AuxV (auxiliary verbs), AuxR (reflexive passive), AuxX (comma), AuxG (brackets, parentheses, etc.), AuxK (terminal punctuation), COORD (coordinating conjunction), ATV (basically any apposition, except as defined in APOS below, MOSTLY used on apposition with a subj. (even an acc. one or if that appos. is in a sub. clause) or an abl abs's noun), AtvV (a praedicativum), APOS (apposition, either involving a comma OR describing a verb in a subjunctive quod clause), PNOM (subject complement), OCOMP (object complement, like nova omnia facere), ExD (ellipsis).

ANY of these can be suffixed with _AP (the comma/punctuation gets the "APOS", the nouns in apposition get this suffix), _CO (coordinated), or _AP_CO
:)



(:5/18/2023: This is finally obsolete.
YOU NEED TO UPDATE THIS SO IT DRAWS ITS SPECIFICATION FROM THE TAGSET.XML FILE IN THE FILES YOU DOWNLOADED FROM GITHUB:)
(:Each entry in this array is a map whose keys are all the possible single-letter postags for that given pos (i.e. 4 in the array accesses all the tense information)
declare variable $postags := [map{"n":"noun", "v":"verb", "t":"participle", "a":"adjective", "d":"adverb", "c":"conjunction", "r":"preposition","p":"pronoun", "m":"numberal", "i":"interjection", "e":"exclamation", "u":"punctuation"}, map{"1":"first person", "2":"second person", "3":"third person"}, map{"s":"singular", "p":"plural"}, map{"-":"none", "p":"present", "i":"imperfect", "r":"perfect", "l":"pluperfect", "t":"future perfect", "f":"future"}, map{"-":"none", "i":"indicative", "s":"subjunctive", "n":"infinitive", "m":"imperative", "p":"participle", "d":"gerund", "g":"gerundive", "u":"supine"}, map{"a":"active", "p":"passive"}, map{"m":"masculine", "f":"feminine", "n":"neuter"}, map{"n":"nominative", "g":"genitive", "d":"dative", "a":"accusative", "b":"ablative", "v":"vocative", "l":"locative"}, map{"c":"comparative", "s":"superlative"}];
:)

declare variable $ldt2.1-treebanks := fn:collection("./treebank_data/v2.1/Latin/texts");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := ($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));

declare variable $harrington := fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");

declare variable $proiel := (fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

declare variable $ola := fn:collection("./../latinnlp/texts/ola");

(:
DEPRECATED, better to use the local collection and to reference the whole folder
declare variable $treebanks := (doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Caes Gall.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Petr.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Phaedrus.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Sal Cat.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Suet Aug.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Verg A.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/vulgate.xml"));
:)
(:

file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml

"C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml
:)
(:

let $trees :=
for $tree in $harrington
let $sentence := $tree//sentence[1]
let $words := $sentence/word/fn:string(@form)
return fn:string-join($words, " ")

let $docs :=
for $tree at $n in $trees
where functx:contains-any-of($tree, $trees[fn:position() != $n])
return array{fn:base-uri($harrington[$n]), fn:base-uri($harrington[(fn:index-of($trees, $tree)[. != $n])[1]])}

:)

(:$sents: All the sentence nodes from ONE treebank:)
declare function local:summation($sents as element()*)
{
  if (fn:contains($sents[1]/fn:string(@subdoc), " ") != true() and fn:string-length($sents[1]/fn:string(@subdoc)) > 0) then (
   let $subdocs := for $sent in $sents return deh:cite-range($sent/fn:string(@subdoc))
   let $final-vals := for $sub in $subdocs where fn:string-length($sub) > 0 let $index := functx:index-of-string($sub, ".") return if ($index = ()) then ($sub) else (fn:substring($sub, $index[fn:count($index)]))
   return $final-vals
 )
 else ()
};

(:title, then author 
urn:cts:latinLit:phi0690.phi003.perseus-lat1 
6.295
:)

(:@form s to look up: "Ulixes dixit", :)

(:Removing 67% of the Vulgate, so keep 37,485; total sentences: 11851:)
let $vulg := $proiel/*[fn:contains(fn:base-uri(.), "latin-nt")]
let $num-sent := fn:count($vulg/source/div/sentence)
let $num-tok := fn:count($vulg/source/div/sentence/token)
let $sentences := deh:pick-random(1 to 11851, 10000)
return hof:until(function($count) {$count > 37485}, function($count) {})


(: This gets the doc where all the words of all the treebanks were annotated 8/6/2023: let $results := doc("./Data-output/mark-node_8.6.23_all_trees.xml") :)
(:
let $quotes := ("&quot;", "'", "”", "“")
let $pres-quotes := $proiel//token[functx:contains-any-of(fn:string(@presentation-after), $quotes)]
return fn:distinct-values($pres-quotes/fn:string(@presentation-after))
:)

(:
for $doc in $all-ldt
let $work-info := deh:work-info($doc)
let $tokens := ($doc//word)

let $expanded := 
  for $token in $tokens
  
  let $subdoc := deh:subdoc($token)
  return if (fn:contains($subdoc, '-')) then (
    for $cite in deh:cite-range($token)
    return (functx:add-attributes(functx:add-attributes(functx:add-attributes($token, xs:QName("cite"), $cite), xs:QName("title"), $work-info[1]), xs:QName("author"), $work-info(2))
  )
  else (functx:add-attributes(functx:add-attributes(functx:add-attributes($token, xs:QName("cite"), $subdoc), xs:QName("title"), $work-info[1]), xs:QName("author"), $work-info(2))


for $token in $expanded
return ($token/fn:string(@cite), $token/fn:string(@author), $token/fn:string(@title))
:)
(:
let $ldt-sents := 
for $sentence in $ldt2.1-treebanks//sentence
return fn:string-join($sentence//word/fn:string(@form), " ")

let $harrington-sents :=
for $sentence in $harrington//sentence
return fn:string-join($sentence//word/fn:string(@form), " ")

let $doubles :=
let $sents-full := $harrington//sentence
for $sent in $ldt-sents
where functx:contains-any-of($sent, $harrington-sents)
let $indexes := fn:index-of($harrington-sents, $sent)
for $index in $indexes
return array{$sent, $sents-full[$index]}

return $doubles
:)

(:
let $sixthreesevenoh := fn:base-uri($harrington/treebank[fn:contains(fn:base-uri(.), "6370")])
let $sixfivesixone := fn:base-uri($harrington/treebank[fn:contains(fn:base-uri(.), "6561")])

let $tree-one := doc($sixthreesevenoh)//word
let $tree-two := doc($sixfivesixone)//word

let $matches :=
for $word at $n in $tree-one
where (($word/@id = $tree-two[$n]/@id) and ($word/@form = $tree-two[$n]/@form) and ($word/@lemma = $tree-two[$n]/@lemma) and ($word/@relation = $tree-two[$n]/@relation) and ($word/@postag = $tree-two[$n]/@postag) and ($word/@head = $tree-two[$n]/@head)) ne true()
return array{$word, $tree-two[$n]}
return $matches
:)



(:
let $preds := deh:search((), "pred", (), $all-trees)
let $children := deh:return-children($preds)
let $proi-child := $children[name() = 'token']
let $ldt-child := $children[name() = 'word']
let $parts-of-speech := (for $item in $proi-child/fn:string(@part-of-speech) return deh:get-proiel-pos-map()($item), deh:get-postags($ldt-child, deh:postags("ldt")))
return $parts-of-speech
:)



(:
Comparatives:
1 magis plus, 
Phases:
Nouns with quantifiers with ex
Nouns with quantifiers with de

Bare quantifiers with ex
Bare quantifiers with de


:)



(:3,639 sum, 5 illecebra1, 

:)

(:
Saved 6/30/2023:
let $auxiliaries :=
  let $postags := deh:postags()
  for $treebank in $treebanks
  let $nom-participles := (deh:search(("verb", "gerundive"), "", "", $treebank, $postags), deh:search(("verb", "gerund"), "", "", $treebank, $postags))
  let $dependents := deh:return-children($nom-participles)
  let $search_2 := deh:search((), "AuxV", "", $dependents, $postags)
  return $search_2
for $treebank in $treebanks
return $treebank/fn:document-uri(.)
:)
(:
EXAMPLE: uSE OF THE DEH:FIND-HIGHEST FUNC
let $doc := $treebanks[2]
let $search := deh:find-highest("verb", $doc, deh:postags())
let $search := deh:mark-node($search)
for $word in $search
where fn:contains($word/fn:string(@relation), "PRED") ne true()
return $word
FIRST FEW RESULTS:
<word deh-sen-id="38" deh-docpath="file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml" id="7" form="crede" lemma="credo1" postag="v2spma---" relation="ExD" head="8"/>
<word deh-sen-id="127" deh-docpath="file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml" id="6" form="opprimar" lemma="opprimo1" postag="v1spsp---" relation="ADV_CO" head="5"/>
<word deh-sen-id="127" deh-docpath="file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml" id="15" form="desinam" lemma="desino1" postag="v1spsa---" relation="ADV_CO" head="11"/>
<word deh-sen-id="147" deh-docpath="file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml" id="5" form="frangat" lemma="frango1" postag="v3spsa---" relation="ADV_CO" head="2"/>
<word deh-sen-id="147" deh-docpath="file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml" id="11" form="corrigas" lemma="corrigo1" postag="v2spsa---" relation="ADV_CO" head="8"/>
:)


(: EXAMPLE OF LOOKING FOR COMPARATIVE ADVERBS (6/25/2023, more recent than anything below)
for $treebank in $treebanks
return deh:search(("comparative"), "ADV", "", $treebank, deh:postags())
:)
(:
HOW TO SEARCH FOR PERFECT PASSIVE FORMS:
for $treebank in $treebanks
let $auxiliaries := $treebank//word[(fn:string(@lemma) eq "sum1") and (fn:string(@relation) eq "AuxV")]
let $participles := deh:postag-andSearch(("participle", "passive", "nominative"), $treebank, $postags)
let $results := deh:parent-return-pairs($auxiliaries, $participles)
for $item in $results
return fn:concat($item/*[1]/fn:string(@form), ", ", $item/word[2]/fn:string(@form))

How to get the length of the longest sentence in a text
let $treebank := $treebanks[2]
let $seq := deh:sentence-lengths($treebank)/fn:number(text())
return functx:sort($seq)
:)