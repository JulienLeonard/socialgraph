package require XOTcl; namespace import -force ::xotcl::*
source utils.tcl

# just module to deal with dataline
# dataline = [list [time value]]
Class DATALINE

DATALINE proc translatex {dataline vx} {
    set newdataline [list]
    foreach item $dataline {
	set newx [+ [lfront $item] $vx]
	lappend newdataline [list $newx [lback $item]]
    }
    return $newdataline
}

DATALINE proc 0fillitem {item} {
    set item [string map [list \" "" " " ""] $item]
    if {![string length $item]} {
	set item 0
    }
    return $item
}

DATALINE proc datarange {dataline} {
    return [lminmax [map item $dataline {lindex $item 1}]]
}

DATALINE proc timerange {dataline} {
    if {![llength $dataline]} {
	return [list]
    }
    return [list [lfront [lfront $dataline]] [lfront [lback $dataline]]]
}

DATALINE proc normdatalinewithranges {timerange datarange dataline} {
    puts "timerange $timerange datarange $datarange"
    set newdataline [list]
    foreach item $dataline {
	lappend newdataline [list [abscissa $timerange [lfront $item]] [abscissa $datarange [lback $item]]]
    }
    return [list $timerange $datarange $newdataline]    
}

DATALINE proc normdatalineonly {dataline} {
    set datarange   [DATALINE::datarange $dataline]
    puts " datarange $datarange"
    set newdataline [map item $dataline {list [lfront $item] [abscissa $datarange [lback $item]]}]
    return $newdataline
}


# return ranges plus data between 0.0 and 1.0
DATALINE proc normdataline {dataline} {
    set timerange [DATALINE::timerange $dataline]
    set datarange [DATALINE::datarange $dataline]
    return [DATALINE::normdatalinewithranges $timerange $datarange $dataline]
}

DATALINE proc opposite {dataline} {
    return [map item $dataline {list [lfront $item] [- 1.0 [lback $item]]}]
}

DATALINE proc 0fill {dataline} {
    set newdataline [list]
    foreach item $dataline {
	lappend newdataline [list [lfront $item] [DATALINE::0fillitem [lback $item]]]
    }
    return $newdataline
}

DATALINE proc compress {dataline} {
    set newdataline [list [lfront $dataline]]
    set oldvalue [lback [lfront $dataline]]
    set valuerange [DATALINE::datarange $dataline]
    puts "valuerange $valuerange"
    foreach item [lrange $dataline 1 end] {
	set newvalue [lback $item]
	set diff [- $oldvalue $newvalue]
	if {$diff < 0.0} {set diff [- 0.0 $diff]}
	set diffvalue [abscissa $valuerange $diff]
	if {$diffvalue >= 0.001} {
	    lappend newdataline $item
	    set oldvalue $newvalue
	}
    }
    return $newdataline
}


DATALINE proc sub {dataline period} {
    return [lsublist $dataline 0 $period]
}

DATALINE proc movingmean {dataline meanperiod} {
    set newdataline [list]
    foreach {index item} [liter $dataline] {
	set subitems [lrange $dataline [- $index [/ $meanperiod 2]] [+ $index [/ $meanperiod 2]]]
	set sum 0.0
	foreach subitem $subitems {
	    set sum [+ $sum [lindex $subitem 1]]
	}
	set mean [/ $sum [double [llength $subitems]]]
	lappend newdataline [list [lindex $item 0] $mean]
    }
    return $newdataline
}

DATALINE proc maxrange {dataranges} {
    set values [lflatten $dataranges]
    return [lminmax $values]
}

DATALINE proc normmergescale {datalines} {
    set maxdatarange [DATALINE::maxrange [map dataline $datalines {DATALINE::datarange $dataline}]]
    set maxtimerange [DATALINE::maxrange [map dataline $datalines {DATALINE::timerange $dataline}]]
    return [map dataline $datalines {DATALINE::normdatalinewithranges $maxtimerange $maxdatarange $dataline}]
}

DATALINE proc enveloppeold {dataline minmaxf size} {
    set result [list [lfront $dataline]]
    set lastindex 0

    while {$lastindex < [- [llength $dataline] $size]} {
	# puts "lastindex $lastindex size [llength $dataline]"
	set nextvalues [lrange $dataline [+ $lastindex 1] [+ $lastindex $size]]
	set values     [map value $nextvalues {lindex $value 1}]
	set maxvalue   [$minmaxf $values]
	set maxindex   [lsearch $values $maxvalue]

	puts "nextvalues $nextvalues values $values maxvalue $maxvalue maxindex $maxindex"
	set lastindex  [+ $lastindex [+ $maxindex 1]]
	lappend result [lindex $nextvalues $maxindex]
    }
    return $result
}

DATALINE proc enveloppe {dataline} {
    set resultmin [list [lfront $dataline]]
    set resultmax [list [lfront $dataline]]
    set lastitem [lfront $dataline]
    lpop! dataline
    set trend 0
    
    foreach item $dataline {
	set cvalue    [lback $item]
	set lastvalue [lback $lastitem]
	if {!$trend} {
	    if {$cvalue <= $lastvalue} {
		set trend -1
		set resultvar resultmin
	    } else {
		set trend 1
		set resultvar resultmax		
	    }
	    lappend $resultvar $item
	} elseif {[s= $trend -1]} {
	    if {$cvalue < $lastvalue} {
	    } else {
		lappend resultmin $lastitem
		set trend 1
	    }
	} elseif {[s= $trend 1]} {
	    if {$cvalue > $lastvalue} {
	    } else {
		lappend resultmax $lastitem
		set trend -1
	    }
	}
	set lastitem $item
    }
    return [list $resultmin $resultmax]
}

DATALINE proc minenveloppe {dataline times} {
    fortimes i $times {
	set dataline [lindex [DATALINE::enveloppe $dataline] 0]
    }
    return $dataline
}

DATALINE proc maxenveloppe {dataline times} {
    fortimes i $times {
	set dataline [lindex [DATALINE::enveloppe $dataline] 1]
    }
    return $dataline
}

DATALINE proc value {dataline time} {
    foreach item $dataline {
	foreach {ctime value} $item  break
	if {$time <= $ctime} {
	    return $value
	}
    }
    return ""
}

DATALINE proc divide {d1 d2} {
    set result [list]
    set d2index 0
    foreach item $d1 {
	foreach {ctime value} $item  break
	foreach {2time  2value} [lindex $d2   $d2index] break
	foreach {2timeb 2valueb} [lindex $d2 [+ $d2index 1]] break
	while {$ctime > $2timeb} {
	    incr d2index
	    set 2value $2valueb
	    foreach {2timeb 2valueb} [lindex $d2 [+ $d2index 1]] break
	    if {$d2index >= [llength $d2]} {
		break
	    }
	}
	
	# set divider [DATALINE::value $d2 $ctime]
	set divider $2value
	if {![sempty $divider] && ![s= $divider 0.0]} {
	    set newvalue [/ $value [double $divider]]
	    if {![s= $newvalue Inf]} {
		set newitem [list $ctime $newvalue]
		lappend result $newitem
		puts "newitem $newitem"
	    }
	}
    }
    return $result
}

DATALINE proc + {d1 d2} {
    set result [list]

    foreach d {d1 d2} {
	set z$d [list]
	foreach item [set $d] {
	    lappend z$d [lconcat $item $d]
	}
    }

    set zd [lsort -increasing -integer -index 0 [lconcat $zd1 $zd2]]

    set result [list]
    set v1 ""
    set v2 ""

    foreach item $zd {
	set date [lfront $item]
	if {[s= [lback $item] d1]} {
	    set v1 [lindex $item 1]
	}
	if {[s= [lback $item] d2]} {
	    set v2 [lindex $item 1]
	}
	set newvalue 0
	if {[string length $v1]} {
	    set newvalue [+ $newvalue $v1]
	}
	if {[string length $v2]} {
	    set newvalue [+ $newvalue $v2]
	}
	lappend result [list $date $newvalue]
    }
    
    return $result
}



DATALINE proc setmax {d1 maxvalue} {
    set result [list]
    foreach item $d1 {
	foreach {time value} $item break
	lappend result [list $time [lmin [list $value $maxvalue]]]
    }
    return $result
}

DATALINE proc scale {d1 factor} {
    set result [list]
    foreach item $d1 {
	foreach {time value} $item break
	lappend result [list $time [* [double $value] $factor]]
    }
    return $result
}

DATALINE proc svgvalues {dataline} {
    set result ""
    foreach item $dataline {
	append result "[* [lfront $item] 1000] [lback $item] "
    }
    return $result
}