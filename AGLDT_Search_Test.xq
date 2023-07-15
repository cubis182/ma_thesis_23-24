xquery version "3.1";

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

declare variable $ldt2.1-treebanks := fn:collection("./treebank_data/v2.1/Latin/texts");

declare variable $all-ldt := ($ldt2.1-treebanks, fn:collection("./harrington_trees/CITE_TREEBANK_XML/perseus/lattb"));

declare variable $proiel := (fn:collection("./PROIEL-DATA/syntacticus-treebank-data/proiel"));

(:
DEPRECATED, better to use the local collection and to reference the whole folder
declare variable $treebanks := (doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Caes Gall.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Cic Catil.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Petr.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Phaedrus.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Sal Cat.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Suet Aug.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Verg A.xml"), doc("C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/vulgate.xml"));
:)
(:

file:///C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml

"C:/Users/T470s/Documents/2023 Spring Semester/Latin Dependency Treebank (AGLDT)/Ov Met.xml
:)

let $postags := deh:postags()
return deh:return-descendants(deh:search((), "", "sum", $all-ldt[1]//word, $postags), 0)



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