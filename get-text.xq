xquery version "4.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $path := "C:/Users/T470s/Documents/2024-Spring/Thesis/Unannotated-Works/"
let $lucr := doc($path || "Lucretius/phi0550.phi001.perseus-lat1.xml")
let $lucan := doc($path || "Lucan/phi0917.phi001.perseus-lat2.xml")
return $lucr