proc usage {args} {
}

#
# error management
#
proc MESSAGE {message type} {
    # .text insert end "$message \n" $type
    # .text see end
    # update
    puts "$type: $message"
    flush stdout
}

proc INFO {message} {
    MESSAGE $message INFO
}

proc WARNING {message} {
    MESSAGE $message WARNING
}

proc BINFO {message} {
    MESSAGE $message BINFO
}


proc DEBUG {message} {
    MESSAGE $message DEBUG
}



proc ERROR {message} {
    MESSAGE $message ERROR
}

proc ERRORHMI {string} {
    # tk_messageBox -message $string -type ok -icon error
    set error "$string"
    if {[info exists errorInfo]} {
	append error "\nCall stack:\n $errorInfo"
    }
    
    error $error
}

#
# COM management
#
proc TRUE {}  {return [expr {1 == 1}]}
proc FALSE {} {return [expr {0 == 1}]}

proc int {value} {
    return [expr {int($value)}]
}
proc double {value} {
    return [expr {double($value)}]
}

proc fstring {value} {
    return [format %s $value]
}


proc INFOCOM {object} {
    puts [join [[tcom::info interface $object] methods] \n]
}

proc lfront {list} {
    return [lindex $list 0]
}

proc lback {list} {
    return [lindex $list end]
}

proc lend {list} {
    return [lindex $list end]
}

proc lpop {list} {
    return [lrange $list 1 end]
}

proc lpop! {list} {
    upvar 1 $list $list
    set result [lfront [set $list]]
    set $list [lpop [set $list]]
    return $result
}

proc lconcat {list args} {
    set result $list
    foreach list $args {
	eval lappend result $list
    }
    return $result
}

proc lconcat! {list args} {
    upvar 1 $list $list
    set $list [lconcat [set $list] {*}$args]
}

proc lunion {list1 list2} {
    set result $list1
    foreach item $list2 {
	if {![lcontain $result $item]} {
	    lappend result $item
	}
    }
    return $result
}

# assign and remove values from list
proc lfront! {vars list} {
    upvar 1 $list $list
    set index 0
    foreach vname $vars {
	upvar 1 $vname $vname
	set $vname [lindex [set $list] $index]
	incr index
    }
    set $list [lrange [set $list] [llength $vars] end]
}

proc lback! {vars list} {
    upvar 1 $list $list
    set index 0
    set varlist [lrange [set $list] "end-[expr {[llength $vars] - 1}]" end]
    foreach vname $vars {
	upvar 1 $vname $vname
	set $vname [lindex $varlist $index]
	incr index
    }
    set $list [lrange [set $list] 0 "end-[llength $vars]"]
}

proc lgrab! {vars list sindex} {
    upvar 1 $list $list
    set index 0
    set varvalues [lrange [set $list] $sindex [expr {$sindex + [llength $vars] -1}]]
    foreach vname $vars {
	upvar 1 $vname $vname
	set $vname [lindex $varvalues $index]
	incr index
    }
    set $list [lconcat [lrange [set $list] 0 [expr {$sindex-1}]] [lrange [set $list] [expr {$sindex + [llength $vars]}] end]]
}

proc lmax {list} {
    if {![llength $list]} {
	return ""
    }
    set max  [lindex $list 0]
    set list [lpop $list]
    foreach v $list {
	if {$v > $max} {
	    set max $v
	}
    }
    return $max
}

proc lmin {list} {
    if {![llength $list]} {
	return ""
    }
    set min  [lindex $list 0]
    set list [lpop $list]
    foreach v $list {
	if {$v < $min} {
	    set min $v
	}
    }
    return $min
}

# list math range
proc lminmax {list} {
    if {![llength $list]} {
	return [list]
    }
    set min  [lindex $list 0]
    set max  [lindex $list 0]
    set list [lpop $list]
    foreach v $list {
	if {$v < $min} {
	    set min $v
	} elseif {$v > $max} {
	    set max $v
	}
    }
    return [list $min $max]
}


proc range {list} {
    if {![llength $list]} {
	return {}
    }
    set min [lindex $list 0]
    set max [lindex $list 0]
    foreach v [lrange $list 1 end] {
	if {$v < $min} {
	    set min $v
	} elseif {$v > $max} {
	    set max $v
	}
    }
    return [list $min $max]
}

proc abscissa {range value} {
    if {![llength $range]} {
	return {}
    }
    lassign $range min max
    if {$min == $max} {
	return $min
    }
    return [expr {double($value - $min)/double($max - $min)}]
}

proc l+ {list} {
    set result 0.0
    foreach item $list {
	set result [+ $result $item]
    }
    return $result
}


proc lcircular {list index} {
    if {![llength $list]} {
	return {}
    }
    set index [expr {$index % [llength $list]}]
    return [lindex $list $index]
}

proc lenum {min max {incr 1}} {
    set result {}
    for {set i $min} {$i < $max} {incr i $incr} {
	lappend result $i
    }
    return $result
}

proc lzip {args} {
    set result [list]
    set minlength [llength [lindex $args 0]]
    foreach olist $args {
	if {$minlength > [llength $olist]} {
	    set minlength [llength $olist]
	}
    }
        
    for {set i 0} {$i < $minlength} {incr i} {
	foreach list $args {
	    lappend result [lindex $list $i]
	}
    }
    return $result
}


proc lflatten {list} {
    set result [list]
    foreach sublist $list {
	set result [lconcat $result $sublist]
    }
    return $result
}

# see lzip
proc lmerge {args} {
    set result [list]
    for {set i 0} {$i < [llength [lindex $args 0]]} {incr i} {
	foreach list $args {
	    lappend result [lindex $list $i]
	}
    }
    return $result
}

proc xmlformat {value} {
    set value [string map [list \" "&quot;" < "&lt;"  > "&gt;"] $value]
    # remove timestamp in event recorder
    if {0} {
	if {[string first : $value] != -1} {
	    set new_value ""
	    foreach val $value {
		if {[string first : $val] == -1} {
		    append new_value "$val "
		}
	    }
	    set value $new_value
	}
    }
    return $value
}

if {1} {
    proc get_xml_value {value} {
	set value [string map [list \" "&quot;" < "&lt;"  > "&gt;"] $value]
	# remove timestamp in event recorder
	if {0} {
	if {[string first : $value] != -1} {
	    set new_value ""
	    foreach val $value {
		if {[string first : $val] == -1} {
		    append new_value "$val "
		}
	    }
	    set value $new_value
	}
	}
	return $value
    }
}

proc lsum {var list script} {
    set result 0
    foreach $var $list {
	incr result [eval $script]
    }
    return $result
}

proc l+ {list} {
    set result 0.0
    foreach item $list {
	set result [+ $result $item]
    }
    return $result
}

proc lmean {list} {
    set sum [l+ $list]
    return [/ $sum [double [llength $list]]]
}

proc lsumacc {var list script} {
    set result [list 0.0]
    set sum    0.0
    foreach $var $list {
	set sum [expr {$sum + [eval $script]}]
	lappend result $sum
    }
    return $result
}

proc lindexcheck {list index} {
    if {$index >= [llength $list]} {
	set index end
    }

    return [lindex $list $index]
}

proc sum {var list script} {
    set result 0
    foreach $var $list {
	set result [expr {$result + [eval $script]}]
    }
    return $result
}

proc checkargs {args} {
    upvar 1 tobechecked local
    set local $args 
    uplevel 1 {
	foreach arg $tobechecked {
	    if {[llength $args] == 1} {
	    if {![info exists $arg]} {
		error "arg $arg not present"
	    }
	    } else {
		foreach {param dvalue} $arg break
		if {![info exists $arg]} {
		    set $param $dvalue
		}
	    }
	}
    }
}

proc setargs {} {
    uplevel 1 {
	foreach {key_ value_} $args {
	    set key_ [string trim $key_ -]
	    set $key_ $value_
	}
    }
}

proc instargs {args} {
    upvar 1 uargs largs
    set largs $args
    uplevel 1 {
	# setargs: here args is args of uplevel method, not args of here !!!
	foreach {key_ value_} $args {
	    set key_ [string trim $key_ -]
	    set $key_ $value_
	}

	foreach arg $uargs {
	    if {[llength $arg] == 1} {
		if {![info exists $arg]} {
		    error "arg $arg not present"
		}
	    } else {
		foreach {attr dvalue} $arg break
		if {![info exists $attr]} {
		    set $attr $dvalue
		}
	    }
	}
    }
}

proc forzip {args} {
    foreach {vname list} $args {
	upvar 1 $vname $vname
    }

    set varlists [lrange $args 0 end-1]
    set script   [lindex $args end]

    set lminindex -1
    foreach {dum list} $varlists {
	if {[llength $list] < $lminindex || $lminindex == -1} {
	    set lminindex [llength $list]
	}
    }
    
    for {set i 0} {$i < $lminindex} {incr i} {
	foreach {var list} $varlists {
	    set $var [lindex $list $i]
	}
	uplevel 1 $script
    }
}

proc fortimes {vname ntimes script} {
    upvar 1 $vname v

    for {set v 0} {$v<$ntimes} {incr v} {
	uplevel 1 $script
    }
}

proc foruplet {varlist list script} {
    foreach vname $varlist {
	upvar 1 $vname $vname
    }

    set maxindex [expr {[llength $list] - [llength $varlist] + 1}]
	for {set i 0} {$i < $maxindex} {incr i} {
	    set vari $i
	foreach vname $varlist {
	    set $vname [lindex $list $vari]
		incr vari
	    }
	uplevel 1 $script
    }
}

proc forpair {var1 var2 list script} {
    upvar 1 varlist vlist
    set vlist [list $var1 $var2]
    upvar 1 list vlist
    upvar 1 script vscript
    set vlist $list
    set vscript $script

    uplevel 1 {foruplet $varlist $list $script}
}

proc stringconvert {conversions input} {
    array set keys $conversions
    if {![info exists keys($input)]} {
	error "input $input unknown with conversions $conversions"
    }
    return $keys($input)
}

proc isinrange {range value} {
    lassign $range min max
    if {$min <= $value && $value <= $max} {
	return 1
    }
    return 0
}

proc map {args} {
    set argc [llength $args]
    # Check arity
    if {$argc < 3 || ($argc % 2) != 1} {
 	error {wrong number args: should be "map varList list ?varList list? script"}
    }
    set listNum [expr {($argc-1)/2}]
    set numIter -1
    # Check if number of vars matches the length of the lists
    # and if the number of iterations is the same for all the lists.
    for {set i 0} {$i < $listNum} {incr i} {
 	set varList [lindex $args [expr {$i*2}]]
 	set curList [lindex $args [expr {$i*2+1}]]
 	if {[llength $curList] % [llength $varList]} {
 	    error "list length doesn't match varList in arg # [expr {$i*2+1}]"
 	}
 	set curNumIter [expr {[llength $curList]/[llength $varList]}]
 	if {$numIter == -1} {
 	    set numIter $curNumIter
 	} elseif {$numIter != $curNumIter} {
 	    error "different number of iterations for varList/list pairs"
 	}
    }
     # Performs the actual mapping.
    set script [lindex $args end]
     set res {}
    for {set iter 0} {$iter < $numIter} {incr iter} {
 	for {set i 0} {$i < $listNum} {incr i} {
 	    set varList [lindex $args [expr {$i*2}]]
 	    set curList [lindex $args [expr {$i*2+1}]]
 	    set numVars [llength $varList]
 	    set listSlice [lrange $curList [expr {$numVars*$iter}] \
			       [expr {$numVars*$iter+$numVars-1}]]
 	    uplevel 1 [list foreach $varList $listSlice break]
 	}
 	lappend res [uplevel 1 $script]
    }
     return $res
}

proc accumulator {var list script} {
    set result [list]
    foreach $var $list {
	lappend result [eval $script]
    }
    return $result
}

proc filter {list value} {
    set result [list]
    foreach item $list {
	if {![string equal $item $value]} {
	    lappend result $item
	}
    }
    return $result
}

proc flatten {list} {
    set result [list]
    foreach item $list {
	set result [concat $result $item]
    }
    return $result
}

proc keepmatch {list pattern} {
    set result [list]
    foreach item $list {
	if {![string match $pattern $item]} {
	    lappend result $item
	}
    }
    return $result    
}

proc times {niter} {
    set result [list]
    for {set i 0} {$i < $niter} {incr i} {
	lappend result $i
    }
    return $result
}

proc slength {string} {
    return [string length $string]
}

proc sempty {string} {
    set result 1
    if {[slength $string]} {
	set result 0
    }
    return $result
}

proc lempty {list} {
    if {[llength $list]} {
	return 0
    }
    return 1
}

proc lreverse {list} {
    set result [list]
    foreach item $list {
	set result [linsert $result 0 $item]
    }
    return $result
}

proc lremove {list itemref} {
    set result [list]
    foreach item $list {
	if {![string equal $item $itemref]} {
	    lappend result $item
	}
    }
    return $result
}

proc lfilter {list itemref} {
    return [lremove $list $itemref]
}

proc lfilterall {list1 list2} {
    set result [list]
    foreach item $list1 {
	if {[lsearch $list2 $item] != -1} {
	    lappend result $item
	}
    }
    return $result
}

proc lintersect {list1 list2} {
    if {[llength $list1] > [llength $list2]} {
	set runlist $list1
	set checklist $list2
    } else {
	set runlist $list2
	set checklist $list1
    }

    set result [list]
    foreach item $runlist {
	if {[lsearch $checklist $item] != -1} {
	    lappend result $item
	}
    }

    return $result
}

proc liter {list} {
    set result [list]
    set index 0
    foreach item $list {
	lappend result $index $item
	incr index
    }
    return $result
}


proc lsubstract {list substractlist} {
    set result [list]
    foreach item $list {
	if {![lcontain $substractlist $item]} {
	    lappend result $item
	}
    }
    return $result
}

proc lsublist {list start period} {
    set result [list]
    for {set i $start} {$i < [llength $list]} {incr i $period} {
	lappend result [lindex $list $i]
    }
    return $result
}

proc lrepeat {string ntimes} {
    set result [list]
    for {set i 0} {$i < $ntimes} {incr i} {
	lappend result $string
    }
    return $result
}

# get list content after item including item
proc lsublistafter {list item} {
    set index [lsearch $list $item]
    if {$index == -1} {
	return [list]
    }
    return [lrange $list $index end]
}

#
# string and file management
#
proc get_common_part {stringlist} {

    set pattern [lindex $stringlist 0]
    for {set i 1} {$i < [llength $stringlist]} {incr i} {
	set newstring [lindex $stringlist $i]
	if {[string match "${pattern}*" $newstring]} {
	    continue
	} else {
	    set new_pattern [list]
	    for {set j 0} {$j < [string length $pattern]} {incr j} {
		if {[string index $pattern $j] == [string index $newstring $j]} {
		    append new_pattern [string index $pattern $j]
		} else {
		    break
		}
	    }
	    set pattern $new_pattern
	    if {![string length $pattern]} {
		break
	    }
	}
    }
    return $pattern
}

proc file_read {filepath} {
    return [fread $filepath]
}

proc fread  {filepath} {
    # usage {set content [fread $filepath]}
    set file [open $filepath r]
    set content [read $file]
    close $file
    return $content
}

proc fcontent {filepath} {
    return [fread $filepath]
}

proc file_xml_read {filepath} {
    return [freadxml $filepath]
}

proc freadxml {filepath {xpath ""}} {
    package require tdom
    
    set xml [fread $filepath]
    set xml [string map [list "&lt;" - "&frac;" - "&gt;" - "&" -] $xml]
    if {![string length $xml]} {
	return ""
    }
    set doc  [dom parse $xml]
    set result [$doc documentElement]

    if {[string length $xpath]} {
	set result [$result selectNodes $xpath]
    }
    
    return $result
}

proc xmlcontent {filepath} {
    return [file_xml_read $filepath]
}

proc xmlattributes {node attributes} {
    set result [list]
    foreach attribute $attributes {
	lappend result [$node getAttribute $attribute]
    }
    return $result
}

proc instxmlattributes {node attributes} {
    upvar 1 uattributes lattributes
    upvar 1 uvalues     lvalues
    set lattributes $attributes
    set lvalues     [xmlattributes $node $attributes]
    uplevel 1 {
	forzip attribute $uattributes value $uvalues {
	    set $attribute $value
	}
    }
}

proc xmltext {node {xpath ""}} {
    if {![string length $node]} {
	return ""
    }
    if {[string length $xpath]} {
	set xpath ${xpath}/
    }
    set textnode [$node selectNodes ${xpath}text()]
    if {[sempty $textnode]} {return ""}
    return [$textnode data]
}

proc xmlhastext {node {xpath ""}} {
    if {[string length $xpath]} {
	set xpath ${xpath}/
    }
    return [llength [$node selectNodes ${xpath}text()]]
}


proc fput {filepath content} {
    set file [open $filepath w+]
    puts $file $content
    close $file
}

proc file_read_choose {extension} {
    usage {set content [file_read_choose $extension]}
    set types [list [list [list $extension $extension File] .$extension]]
    set filepath [tk_getOpenFile -filetypes $types]
    if {![string length $filename]} {
	return
    }

    
    return [file_read $filepath]
}

proc fget {pattern} {
    return [glob -directory "./" $pattern]
}

proc get_files_by_date {{pattern *} {directory ""}} {
    if {![string length $directory]} {
	set directory "./"
    }
    
    foreach file [glob -directory $directory $pattern] {
	lappend filelist [list $file [file mtime $file]]
    }
    set filelist [lsort -integer -index 1 $filelist]
    
    set result [list]
    foreach fileitem $filelist {
	lappend result [lindex $fileitem 0]
    }

    return $result
}
    
    

proc get_most_recent_file {{pattern *} {directory ""}} {
    return [lindex [get_files_by_date $pattern $directory] end]
}

proc irange {istart iend {iincr 1}} {
    set result [list]
    for {set i $istart} {$i < $iend} {+= i $iincr} {
	lappend result $i
    }
    return $result
}

proc trace {args} {
    set trace [join $args " "]
    puts $trace
}

proc sample {range value} {
    lassign $range min max
    return [expr {double($min) + double($max - $min) * double($value)}]
}

proc samples {begin end ntimes} {
    if {$ntimes == 1} {
	return $begin
    }
    set incr [expr {double($end-$begin)/double($ntimes-1)}]
    set result [list]
    set value $begin
    for {set i 0} {$i < $ntimes} {incr i} {
	lappend result $value
	set value [expr {$value+$incr}]
    }
    return $result
}


proc lgeo {start stop niter} {
    set factor [expr {pow(($stop/$start),1.0/double($niter-1))}]
    set result [list]
    set current $start
    fortimes i $niter  {
	lappend result $current
	set current [expr {$current * $factor}]
    }
    return $result
}

proc lgeo2 {start stop niter {ratio 0.1}} {
    # first model progression
    set result [list 1.0]
    fortimes i [- $niter 1] {
	lappend result [* [lback $result] $ratio] 
    }
    set range [range $result]
    # then map
    set result [map item $result {sample [list $start $stop] [abscissa $range $item]}]

    return $result
}


#
# math utilitaries
#

proc ++ {item} {
		return [expr {$item + 1}]
	    }

proc + {args} {
    set sum [lindex $args 0]
    foreach arg [lrange $args 1 end] {
	set sum [expr {$arg + $sum}]
    }
    return $sum
}

proc - {args} {
    set diff [lindex $args 0]
    foreach arg [lrange $args 1 end] {
	set diff [expr {$diff - $arg}]
    }
    return $diff
}


proc * {args} {
    set result [lindex $args 0]
    foreach arg [lrange $args 1 end] {
	set result [expr {$arg * $result}]
    }
    return $result
}


proc / {args} {
    set div [lindex $args 0]
    foreach arg [lrange $args 1 end] {
	set div [expr {$div / $arg}]
    }
    return $div
}



proc ? {a b c} {
    if {$a} {
	return $b
    }
    return $c
}

proc == {a b} {
    return [expr {$a == $b}]
}

proc != {a b} {
    return [expr {$a != $b}]
}

proc str== {a b} {
    return [string equal $a $b]
}

proc str!= {a b} {
    return [expr {![string equal $a $b]}]
}

proc s! {a b} {
    return [expr {![string equal $a $b]}]
}

proc s= {s1 args} {
    foreach arg $args {
	if {[string equal $s1 $arg]} {
	    return 1
	}
    }
    return 0
}

proc > {a b} {
	      return [expr {$a > $b}]
}

proc < { a b} {
	     return [expr {$a < $b}]
}


foreach op {+ - * /} {
    proc ${op}= {a_ b} [string map [list %OP% $op] {
	upvar $a_ a
	set a [%OP% $a $b]
	return $a
    }]
}

proc ?= {var_ a b c} {
    upvar $var_ var
    set var [? $a $b $c]
    return $var
}

proc half {a} {
    return [expr {$a / 2}]
}

proc max {list} {
    set result [lindex $list 0]
    foreach item [lrange $list 1 end] {
	if {$item > $result} {
	    set result $item
	}
    }
    return $result
}

proc drand {min max {niter 1}} {
    if {$niter == 1} {
	return [expr {$min + ($max - $min) * rand()}]
    } else {
	set result [list]
	fortimes i $niter {
	    lappend result [drand $min $max]
	}
	return $result
    }
}

proc lmap {list1 args} {
    set result [list]
    set index 0
    foreach factor $list1 {
	set list2 [lcircular $args $index]
	foreach item $list2 {
	    lappend result [expr {$factor * $item}]
	}
	incr index
    }
    return $result
}

proc lextract {list indices} {
    set result [list]
    foreach index $indices {
	lappend result [lindex $list $index]
    }
    return $result
}


proc ldivide {list nelements} {
    set result [list]
    set index 0
    while {$index < [llength $list]} {
	lappend result [lrange $list $index [expr {$index + $nelements - 1}]]
	incr index $nelements
    }
    return $result
}

proc lsplit {list times} {
    set nelements [expr {[llength $list]/$times}]
    return [ldivide $list $nelements]
}

proc lchunk {list maxitems} {
    set result [list]
    set index 0
    while {$index < [llength $list]} {
	lappend result [lrange $list $index [+ $index [- $maxitems 1]]]
	set index [+ $index $maxitems]
    }
    return $result
}

proc sequence {args} {
    setargs
    checkargs type

    set result [list]
    if {[s= $type geo]} {
	checkargs  niter init ratio
	if {![info exists recurseindex]} {
	    set recurseindex 0
	}
	eval lappend result $init
	foreach i [times $niter] {
	    set value [expr {[lindex $result end-$recurseindex] * $ratio}]
	    if {[info exists min]} {
		if {$value < $min} break
	    }
	    lappend result $value
	}
	set result [lrange $result [llength $init] end]
    } elseif {[s= $type add]} {
	checkargs start incr end
	set current $start
	while {1} {
	    lappend result $current
	    set current [expr {$current + $incr}]
	    if {$incr > 0.0} {
		if {$current > $end} {
		    break
		}
	    } elseif {$incr < 0.0} {
		if {$current < $end} {
		    break
		}
	    }
	}
    }
    return $result
}

proc lrandomindex {list} {
    return [expr {int(rand() * double([llength $list]))}]
}

proc lrandomindices {list times} {
    set result [list]
    fortimes i $times {
	lappend result [lrandomindex $list]
    }
    return $result
}

proc lrandom {args} {
    if {[llength $args] == 1} {
	set list     [lindex $args 0]
	return [lindex $list [lrandomindex $list]]
    } elseif {[llength $args] == 2} {
	set list [lindex $args 0]
	if {[llength [lindex $args 1]] == 1} {
	    set indices [lrandomindices $list [lindex $args 1]]
	} else {
	    set indices [lindex $args 1]
	}
	foreach index $indices {
	    lappend result [lindex $list $index]
	}
	return $result
    } 
}

proc lshuffle {list} {
    set result [list]
    while {[llength $list]} {
	set rindex [lrandomindex $list]
	lappend result [lindex $list $rindex]
	set newlist [lrange $list 0 [expr {$rindex - 1}]]
	eval lappend newlist [lrange $list [expr {$rindex+1}] end]
	set list $newlist
    }
    return $result
}

proc lshift {list times} {
    return [lconcat [lrange $list $times end] [lrange $list 0 [expr {$times-1}]]]
}

proc lpairs {list} {
    set result [list]
    forpair p1 p2 $list {
	lappend result [list $p1 $p2]
    }
    return $result
}

proc lallpairs {list} {
    set result [list]
    for {set i 0} {$i < [llength $list] } {incr i} {
	for {set j [+ $i 1]} {$j < [llength $list]} {incr j} {
	    lappend result [lindex $list $i] [lindex $list $j]
	}
    }
    return $result
}

proc lsetadd {list item} {
    set result $list
    if {![lcontain $result $item]} {
	lappend result $item
    }
    return $result
}

proc lcontain {list item} {
    set result 1
    if {[lsearch $list $item] == -1} {
	set result 0
    }
    return $result
}

proc rcontain {range value} {
    if {[lfront $range] <= $value && [lback $range] >= $value} {
	return 1
    }
    return 0
}

proc lrepeat {in times} {
    set result [list]
    fortimes i $times {
	set result [lconcat $result $in]
    }
    return $result
}

proc lduplicate {in times} {
    return [lrepeat $in $times]
}


proc lresize {in nsize} {
    set result [list]
    fortimes i $nsize {
	lappend result [lcircular $in $i]
    }
    return $result
}

proc lsamples {in indices} {
    foreach index $indices {
	lappend result [lindex $in $index]
    }
    return $result
}

proc liter {list} {
    set result [list]
    set index 0
    foreach item $list {
	lappend result $index $item
	incr index
    }
    return $result
}

proc literscale {in times} {
    set result $in
    set lastvalues [lrange $in 1 end]
    fortimes i [expr {$times-1}] {
	set lastvalue [lindex $result end]
	set newin [map x $lastvalues {expr {$x * $lastvalue}}]
	lconcat! result $newin
    }
    return $result
}

proc lambda {params body args} {
     set ns [uplevel 1 { namespace current }]
     list ::apply [list $params $body $ns] {*}$args
 }

proc columnlayout {datalines} {

    # compute column sizes
    set columnsizes [list]
    foreach dataline $datalines {
	set index 0
	foreach data $dataline {
	    if {$index >= [llength $columnsizes]} {
		lappend columnsizes [string length $data]
	    } else {
		if {[string length $data] > [lindex $columnsizes $index]} {
		    lset columnsizes $index [string length $data]
		}
	    }
	    incr index
	}
    }

    # return result
    set result ""
    foreach dataline $datalines {
	set index 0    
	foreach data $dataline {
	    append result $data [string repeat " " [expr {[lindex $columnsizes $index] - [string length $data]}]]
	    append result "\t"
	    incr index
	}
	append result "\n"
    }
    return $result
}

# algo: given a numeric list, redistribute randomly values so that it as the same sum and same size
proc lredistribute {sum {minsize 0.0} nitems} {
    set sum [- $sum [expr {$minsize *  double($nitems)}]]
    set serie [lsort -increasing -real [lconcat {0.0} [drand 0.0 $sum [- $nitems 1]] $sum]]
    set result [list]
    forpair v1 v2 $serie {
	lappend result [+ $minsize [- $v2 $v1]]
    }
    return $result
}


proc checkvar {varname defaultv} {
    set script "if {!\[info exists $varname\]} {set $varname $defaultv}" 
    # puts "script $script"
    uplevel 1 $script
}

proc int2bits {i {digits {} } } {
    #returns a bitslist, e.g. int2bits 10 => {1 0 1 0}
    # digits determines the length of the returned list (left truncated or added left 0 )
    # use of digits allows concatenation of bits sub-fields

    set res ""
    while {$i>0} {
	set res [expr {$i%2}]$res
	set i [expr {$i/2}]
    }
    if {$res==""} {set res 0}

    if {$digits != {} } {
	append d [string repeat 0 $digits ] $res
	set res [string range $d [string length $res ] end ]
    }
    split $res ""
}

proc bits2int {bits} {
    #returns integer equivalent of a bitlist
    set res 0
    foreach i $bits {
	set res [expr {$res*2+$i}]
    }
    set res
}

proc filepaths {pattern} {
    set subdirs [split $pattern /]
    set result  [list "[lfront $subdirs]/"]
    foreach subdir [lrange $subdirs 1 end-1] {
	# puts "subdir $subdir"
	set newresult [list]
	foreach prevdir $result {
	    eval lappend newresult [glob -nocomplain -directory ${prevdir}/ -type d $subdir]
	}
	set result $newresult
    }

    set newresult [list]
    foreach prevdir $result {
	eval lappend newresult [glob -nocomplain -directory ${prevdir}/ [lback $subdirs] ]
    }
    set result $newresult

    # puts "filepaths result $result"
    return $result
}

proc l+ {list} {
    set result [lfront $list]
    foreach i [lrange $list 1 end] {
	set result [+ $result $i]
    }
    return $result
}

proc mean {v1 v2} {
    return [/ [+ $v1 $v2] 2.0]
}

proc l&& {list} {
    set result 1
    foreach item $list {
	if {!$item} {
	    return 0
	}
    }
    return 1
}

proc l|| {list} {
    set result 0
    foreach item $list {
	if {$item} {
	    return 1
	}
    }
    return 0
}
proc ifset {varname2 varname1} {
    set script "if {\[info exists $varname1\]} {set $varname2 \[set $varname1\]}" 
    # puts "script $script"
    uplevel 1 $script
}

proc dotemplate {template args} {
    return [string map $args $template]
}

proc allfilepaths {sourcedir filepattern} {
    set result [list]
    foreach subdir [lconcat [glob -nocomplain -directory $sourcedir/ -types d *] [glob -nocomplain -directory $sourcedir/ -types {d hidden} *]] {
	eval lappend result [allfilepaths $subdir $filepattern]
    }
    eval lappend result [glob -nocomplain -directory $sourcedir/ $filepattern]
    eval lappend result [glob -nocomplain -directory $sourcedir/ -types hidden $filepattern]
    return $result
}
