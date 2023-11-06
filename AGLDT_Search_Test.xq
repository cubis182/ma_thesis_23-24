xquery version "3.1";

(:NOTE THAT, FOR THE BASEX IMPLEMENTATION, SET WRITEBACK true IS NECESSARY FOR THIS TO WORK:)

import module namespace functx = "http://www.functx.com" at "C:/Program Files (x86)/BaseX/src/functx_lib.xqm";
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

declare variable $ldt2.1-treebanks := db:get("ldt2.1-treebanks");

declare variable $ldt2.1-with-caes-jerome := fn:collection("./treebank_data/v2.1/Latin");

declare variable $all-ldt := (db:get("ldt2.1-treebanks"), db:get("harrington")); (:10/4/2023, obsolete with new databases($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));:)

declare variable $harrington := db:get("harrington");(:10/4/2023, see above fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb");:)

declare variable $proiel := db:get("proiel");(:10/4/2023(fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));:)

declare variable $all-trees := ($all-ldt, $proiel); (:This is all the LDT, Harrington, and PROIEL trees, with the Caesar and Vulgate in LDT taken out:)

declare variable $ola := db:get('ola');(:fn:collection("./../latinnlp/texts/ola");:)

declare variable $full-proiel := db:get("Full-PROIEL"); (:This is PROIEL with the full Vulgate back, not absolutely every PROIEL treebank:)

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
(:[(fn:contains(fn:string(@relation), "PRED") or (functx:contains-any-of(fn:string(@relation), ("OBJ", "DIRSTAT")) and ((fn:count(deh:return-children((., deh:return-parent(., 0)))[fn:contains(fn:string(@relation), "AuxG")]) > 0) or (functx:contains-any-of(deh:return-parent-nocoord(.)/fn:string(@lemma), $complementizers))))) and (fn:matches(fn:string(@postag), "v[1-3].......") or (fn:count(deh:return-children(.)[fn:contains(fn:string(@relation), "AuxV")]) > 0) or fn:string(@artificial) = "elliptic")]:)

let $doc := document {
  <sentence id="30182" status="reviewed" presentation-after=" ">
        <token id="452893" form="sicut" citation-part="COL 2.6" lemma="sicut" part-of-speech="Df" morphology="---------n" head-id="452895" relation="adv" presentation-after=" "/>
        <token id="452894" form="ergo" citation-part="COL 2.6" lemma="ergo" part-of-speech="Df" morphology="---------n" head-id="452901" relation="aux" presentation-after=" " alignment-id="451223"/>
        <token id="452895" form="accepistis" citation-part="COL 2.6" lemma="accipio" part-of-speech="V-" morphology="2pria----i" head-id="452901" relation="adv" presentation-after=" " alignment-id="451224"/>
        <token id="452896" form="Christum" citation-part="COL 2.6" lemma="Christus" part-of-speech="Ne" morphology="-s---ma--i" head-id="452895" relation="obj" presentation-after=" " alignment-id="451226"/>
        <token id="452897" form="Iesum" citation-part="COL 2.6" lemma="Iesus" part-of-speech="Ne" morphology="-s---ma--i" head-id="452896" relation="apos" presentation-after=" " alignment-id="451227"/>
        <token id="452898" form="Dominum" citation-part="COL 2.6" lemma="dominus" part-of-speech="Nb" morphology="-s---ma--i" head-id="452897" relation="apos" presentation-after=" " alignment-id="451229"/>
        <token id="452899" form="in" citation-part="COL 2.6" lemma="in" part-of-speech="R-" morphology="---------n" head-id="452901" relation="adv" presentation-after=" " alignment-id="451231"/>
        <token id="452900" form="ipso" citation-part="COL 2.6" lemma="ipse" part-of-speech="Pp" morphology="3s---mb--i" head-id="452899" relation="obl" presentation-after=" " alignment-id="451232"/>
        <token id="452901" form="ambulate" citation-part="COL 2.6" lemma="ambulo" part-of-speech="V-" morphology="2ppma----i" relation="pred" presentation-after=" " alignment-id="451233"/>
        <token id="452902" form="radicati" citation-part="COL 2.7" lemma="radico" part-of-speech="V-" morphology="-prppmn--i" head-id="452903" relation="xadv" presentation-after=" " alignment-id="451235"/>
        <token id="452903" form="et" citation-part="COL 2.7" lemma="et" part-of-speech="C-" morphology="---------n" head-id="452901" relation="xadv" presentation-after=" " alignment-id="451236">
          <slash target-id="452901" relation="xsub"/>
        </token>
        <token id="452904" form="superaedificati" citation-part="COL 2.7" lemma="superaedifico" part-of-speech="V-" morphology="-prppmn--i" head-id="452903" relation="xadv" presentation-after=" " alignment-id="451237"/>
        <token id="452905" form="in" citation-part="COL 2.7" lemma="in" part-of-speech="R-" morphology="---------n" head-id="452903" relation="adv" presentation-after=" " alignment-id="451238"/>
        <token id="452906" form="ipso" citation-part="COL 2.7" lemma="ipse" part-of-speech="Pp" morphology="3s---mb--i" head-id="452905" relation="obl" presentation-after=" " alignment-id="451239"/>
        <token id="452907" form="et" citation-part="COL 2.7" lemma="et" part-of-speech="C-" morphology="---------n" head-id="452903" relation="aux" presentation-after=" " alignment-id="451240"/>
        <token id="452908" form="confirmati" citation-part="COL 2.7" lemma="confirmo" part-of-speech="V-" morphology="-prppmn--i" head-id="452903" relation="xadv" presentation-after=" " alignment-id="451241"/>
        <token id="452909" form="fide" citation-part="COL 2.7" lemma="fides" part-of-speech="Nb" morphology="-s---fb--i" head-id="452908" relation="adv" presentation-after=" " alignment-id="451243"/>
        <token id="452910" form="sicut" citation-part="COL 2.7" lemma="sicut" part-of-speech="Dq" morphology="---------n" head-id="452912" relation="adv" presentation-after=" " alignment-id="451244"/>
        <token id="452911" form="et" citation-part="COL 2.7" lemma="et" part-of-speech="Df" morphology="---------n" head-id="452912" relation="aux" presentation-after=" "/>
        <token id="452912" form="didicistis" citation-part="COL 2.7" lemma="disco" part-of-speech="V-" morphology="2pria----i" head-id="452901" relation="adv" presentation-after=" " alignment-id="451245"/>
        <token id="452913" form="abundantes" citation-part="COL 2.7" lemma="abundans" part-of-speech="A-" morphology="-p---mnp-i" head-id="452912" relation="xadv" presentation-after=" " alignment-id="451247">
          <slash target-id="452912" relation="xsub"/>
        </token>
        <token id="452914" form="in" citation-part="COL 2.7" lemma="in" part-of-speech="R-" morphology="---------n" head-id="452913" relation="obl" presentation-after=" " alignment-id="451248"/>
        <token id="452915" form="gratiarum" citation-part="COL 2.7" lemma="gratia" part-of-speech="Nb" morphology="-p---fg--i" head-id="452916" relation="narg" presentation-after=" "/>
        <token id="452916" form="actione" citation-part="COL 2.7" lemma="actio" part-of-speech="Nb" morphology="-s---fb--i" head-id="452914" relation="obl" alignment-id="451249"/>
      </sentence>
}
let $tok := $doc//token[@id='452895'] 
let $sib := if (deh:return-parent($tok, 0)/deh:is-coordinating(.)) then (deh:return-siblings($tok, false())) else () 
  
  (:We combine all the possibilities together: the relative must be in either the descendants or the siblings' descendants, and if there is no relative in there, we return nothing:)
  return deh:verb-headed-clause-sub($tok)


(:
qua re  velim ut  scribis... because ut was not considered a subordinator directly
in primis que versutum et callidum factum Solonis... is quo later in the sentence a 'G-'?
omnis autem et animadversio et castigatio contumelia... is castigat really subordinate?
itaque ut eandem nos modestiam... Is a result clause considered relative? maybe so
magis quid se dignum foret  quam quid in illos iure fieri posset... why is only the foret and not the posset considered subordinate? Because of the quam?




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