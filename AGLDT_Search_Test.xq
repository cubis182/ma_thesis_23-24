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

(:('work-id,main,sub,obj,purp,caus,temp,condition'),:)

(:So, corpus, lemma, count, type, total work count, para/hypotaxis value:)
(:
let $works := deh:short-names()
let $poetry := ('Met', 'Elegie', 'Elegia', 'Aen', 'Fab', 'Sati', 'Carm', 'Amor')
let $prose := ("In Cat", "Cael", "Att", "off", "agri", "Res", "Gall", "Vul", "Aug", "Ann", "Hist", "Pere", "Petr")

let $prose-trees := for $work in $prose return $all-trees[fn:matches(deh:work-info(.)(1), $work)]
let $poetry-trees := for $work in $poetry return $all-trees[fn:matches(deh:work-info(.)(1), $work)]

let $map := map{'poetry':$poetry-trees, 'prose':$prose-trees}
let $work-name := '(Petr|Saty)'
for $work in $works
let $tree := $all-trees[fn:matches(deh:work-info(.)(1), $work)]

let $work-length := fn:count($tree//sentence/*[deh:is-punc(.) = false() and deh:is-empty(.) = false()])

let $causal-adv := (deh:causal-adverb($tree) => deh:count-by-form()) ! array:append(., ('causal', 'para', $work-length))

let $sp-temp-adv := deh:spatio-temporal-adverb($tree)
let $mixed-adv := ((for $item in $sp-temp-adv[.(2) = 'mixed-spatial-temporal'] return $item(1)) => deh:count-by-form()) ! array:append(., ('mixed', 'para', $work-length))
let $spatial-adv := ((for $item in $sp-temp-adv[.(2) = 'spatial'] return $item(1)) => deh:count-by-form()) ! array:append(., ('spatial', 'para', $work-length))
let $temporal-adv := ((for $item in $sp-temp-adv[.(2) = 'temporal'] return $item(1)) => deh:count-by-lemma()) ! array:append(., ('temporal', 'para', $work-length))

let $clause-pairs := deh:get-clause-pairs($tree) 
let $causal-clause := ($clause-pairs => deh:causal-clause() => deh:count-clause-pairs()) ! array:append(., ('causal', 'hypo', $work-length))
let $spatial-clause := (($clause-pairs => deh:spatial-clause()) => deh:count-clause-pairs()) ! array:append(., ('spatial', 'hypo', $work-length))
let $temporal-clause :=  ($clause-pairs => deh:temporal-clause() => deh:count-clause-pairs()) ! array:append(., ('temporal', 'hypo', $work-length))


let $results-para := ($mixed-adv, $temporal-adv, $spatial-adv, $causal-adv)
let $results-hypo := ($causal-clause, $spatial-clause, $temporal-clause)

for $item in ($results-para, $results-hypo)

return fn:string-join(($work, $item?*), ",")
:)
(:capuam, romam, HANC, HAEC, :)

(:
let $singles := ($all-trees => deh:get-clause-pairs())[array:size(.) < 2]
for $item in $singles
return deh:get-tok-address($item(1))
:)

deh:read-sent-address("Elegie,/ldt2.1-treebanks/phi0620.phi001.perseus-lat1.tb.xml|1", $all-trees)







(:
let $work-length := fn:count($tree//sentence/*[deh:is-punc(.) = false() and deh:is-empty(.) = false()])

let $types := ('mixed', 'spatial', 'temporal', 'causal')

let $organized-para :=
for $type in $types
return array{$results-para[.(3) = $type]}

let $organized-hypo :=
for $type in $types
return array{$results-hypo[.(3) = $type]}


let $mixed-para := $organized-para[1] => deh:process-count-results($work-length)
let $spatial-para := $organized-para[2] => deh:process-count-results($work-length)
let $temp-para := $organized-para[3] => deh:process-count-results($work-length)
let $causal-para := $organized-para[4] => deh:process-count-results($work-length)

let $spatial-hypo := $organized-hypo[2] => deh:process-count-results($work-length)
let $temp-hypo := $organized-hypo[3] => deh:process-count-results($work-length)
let $causal-hypo := $organized-hypo[4] => deh:process-count-results($work-length)




work,mixed-para, mixed-num, spatial-para, spatial-num, temp-para, temp-num, causal-para, causal-num, work-length
return string-join(($work, $mixed-para?*, $spatial-para?*, $temp-para?*, $causal-para?*, $spatial-hypo?*, $temp-hypo?*, $causal-hypo?*, $work-length), ","):)
  


