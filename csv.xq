xquery version "4.0";

let $csv := csv:doc('./Data-output/var-info/parataxis-12.6.23.txt', map{'header':'yes'})