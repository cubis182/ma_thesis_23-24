xquery version "4.0";

module namespace stats = "ma-thesis-23-24";

import module namespace functx = "http://www.functx.com" at "functx_lib.xqm";
(:Backup for functx when the internet is crap: C:/Program Files (x86)/BaseX/src/functx_lib.xqm 
  http://www.xqueryfunctions.com/xq/functx-1.0.1-doc.xq
:)

declare function stats:stdev($seq as xs:double*) as xs:double
{
  let $mean := stats:mean($seq)
  let $deviations := for $num in $seq return math:pow(($num - $mean), 2)
  
  return math:sqrt(stats:mean($deviations))
};

declare function stats:mean($seq as xs:double*) as xs:double
{
  if (fn:count($seq) > 0) then (
  fn:fold-left($seq, 0, function($a, $b){$a + $b}) div fn:count($seq))
  else (0)
};