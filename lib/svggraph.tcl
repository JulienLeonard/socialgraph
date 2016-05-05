
Class SVGGRAPH -parameter {{output ""} {xrange [list 0 10000]} {yrange [list 0 1000]} {seconds yes} {minutes yes} {hours yes} {days no} {months no} {years no} {timerange ""} {datalines [list]}}

SVGGRAPH instproc initdrawing {{background white}} {
    source "svgrender.tcl"
    SVGRENDER create render1 800 600 [my output] $background
}

SVGGRAPH instproc gx {abscissa} {
    return [sample [my xrange] $abscissa]
}

SVGGRAPH instproc gy {abscissa} {
    return [sample [my yrange] [- 1.0 $abscissa]]
}

SVGGRAPH instproc gt2x {time} {
    return [my gx [abscissa [my timerange] $time]]
}

SVGGRAPH instproc addtimerange {newtimerange} {
    puts "new timerange $newtimerange"
    if {![llength [my timerange]]} {
	my timerange $newtimerange
    } else {
	my timerange [lminmax [eval lconcat [list [my timerange] $newtimerange]]]
	puts "timerange [my timerange]"
    }
}

SVGGRAPH instproc gengrid {} {
    foreach {mmintime mmaxtime} [my timerange] break
    set mintime [clock format $mmintime -format {%Y %m %d %H %M %S}]
    set maxtime [clock format $mmaxtime -format {%Y %m %d %H %M %S}]

    puts "mintime $mintime maxtime $maxtime"
    set linewidth 0.1

    # for hours
    if {[s= [my hours] yes]} {    
	set hmintime $mintime
	lset hmintime 4 00
	lset hmintime 5 00
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	lset hmaxtime 4 00
	lset hmaxtime 5 00
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 hours]

	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 1 hours]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 1.0] $pxline [my gy 1.0]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]"   -CLASS HOUR -fillcolor {0 0 255 0.05} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 2 hours]	
	}
    }

    # for years
    if {[s= [my years] yes]} {
	set hmintime $mintime
	lset hmintime 1 00
	lset hmintime 2 00
	lset hmintime 3 00
	lset hmintime 4 00
	lset hmintime 5 00
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	lset hmaxtime 1 00
	lset hmaxtime 2 00
	lset hmaxtime 3 00
	lset hmaxtime 4 00
	lset hmaxtime 5 00
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 years]
	
	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 1 years]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 1.0] $pxline [my gy 1.0]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]" -CLASS YEAR -fillcolor {0 0 255 0.1} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 2 years]	
	}
    }
    
    # for months
    if {[s= [my months] yes]} {
	set hmintime $mintime
	lset hmintime 2 00
	lset hmintime 3 00
	lset hmintime 4 00
	lset hmintime 5 00
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	lset hmaxtime 2 00
	lset hmaxtime 3 00
	lset hmaxtime 4 00
	lset hmaxtime 5 00
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 months]
	
	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 1 months]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 1.0] $pxline [my gy 1.0]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]" -CLASS MONTH -fillcolor {0 0 255 0.1} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 2 months]	
	}
    }

    
    # for days
    if {[s= [my days] yes]} {
	set hmintime $mintime
	lset hmintime 3 00
	lset hmintime 4 00
	lset hmintime 5 00
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	lset hmaxtime 3 00
	lset hmaxtime 4 00
	lset hmaxtime 5 00
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 days]
	
	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 1 days]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 1.0] $pxline [my gy 1.0]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]" -CLASS DAY -fillcolor {0 0 255 0.1} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 2 days]	
	}
    }

    # for minutes
    if {[s= [my minutes] yes]} {
	set hmintime $mintime
	lset hmintime 5 00
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	lset hmaxtime 5 00
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 minutes]

	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 1 minutes]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 0.75] $pxline [my gy 0.75]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]"   -CLASS HOUR -fillcolor {0 0 255 0.05} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 2 minutes]	
	}
    }

    if {[s= [my seconds] yes]} {
	# for seconds
	set hmintime $mintime
	set rawmintime [clock scan $hmintime -format {%Y %m %d %H %M %S}]

	set hmaxtime $maxtime
	set rawmaxtime [clock scan $hmaxtime -format {%Y %m %d %H %M %S}]
	set rawmaxtime [clock add $rawmaxtime 1 seconds]

	set plinetime $rawmintime
	while {$plinetime < $rawmaxtime} {
	    set pxline [my gt2x $plinetime]
	    set linetime [clock add $plinetime 10 seconds]
	    set xline [my gt2x $linetime]
	    # set coords [list [- $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 0.0] [+ $xline $linewidth] [sample [my yrange] 1.0] [- $xline $linewidth] [sample [my yrange] 1.0]]
	    set coords [list $pxline [my gy 0.0] $xline [my gy 0.0] $xline [my gy 0.5] $pxline [my gy 0.5]]
	    render1 drawline -coords $coords -ID "[clock format $plinetime]\n[clock format $linetime]"   -CLASS HOUR -fillcolor {0 0 255 0.05} -filled 1 -priority 1
	    set plinetime [clock add $plinetime 20 seconds]	
	}
    }
}

SVGGRAPH instproc draweventline {data color datalabel y} {
    set xleft   [lfront [my xrange]]
    set xright  [lback  [my xrange]]
    set ycenter $y

    set linewidth 1.0
    set eventlinecoords [list $xleft [- $ycenter $linewidth] $xleft [+ $ycenter $linewidth] $xright [+ $ycenter $linewidth] $xright [- $ycenter $linewidth] $xleft [- $ycenter $linewidth]]
    render1 drawline -coords $eventlinecoords -ID $datalabel -CLASS PETTERN -linewidth 1.0 -priority 1 -linecolor $color -closed 0
    proc yfunction {graph item} "return $y"     
    my drawevents $data yfunction $color
}

SVGGRAPH instproc eventsize {} {
    return [/ [- [my gt2x [lfront [my timerange]]] [my gt2x [+ [lfront [my timerange]] 1]]] 2.0]
}

SVGGRAPH instproc draweventlinexy {data color datalabel} {
    my drawdataline $data $color $datalabel 0
    
    proc yfunction {graph item} {return [$graph gy [lindex $item 1]]}    
    my drawevents $data yfunction $color
}

SVGGRAPH instproc drawdataline {data datarange color datalabel closed rendertype} {
    if {$closed} {
	# add first and last to 0
	set time1 [lfront [lfront $data]]
	set time2 [lfront [lback  $data]]
	set data [lconcat [list [list $time1 1.0]] $data [list [list $time2 1.0]]] 
    }

    puts "before eventlinecoords"
    set eventlinecoords [list]
    foreach item $data {lappend eventlinecoords [my gt2x [lfront $item]] [my gy [abscissa $datarange [lindex $item 1]]]}
    puts "after eventlinecoords"

    if {!$closed} {
	set linewidth 5
	if {![s= $rendertype datapoint]} {
	    render1 drawline -coords $eventlinecoords -ID $datalabel -CLASS PETTERN -linewidth $linewidth -priority 1 -linecolor $color -closed $closed
	} else {
	    set index 0
	    foreach {x y} $eventlinecoords {
		set r 1
		if {0} {
		set squarecoords [list [- $x $r] [- $y $r] \
				      [- $x $r] [+ $y $r] \
				      [+ $x $r] [+ $y $r] \
				      [+ $x $r] [- $y $r]]
		} else {
		    set squarecoords [list $x [- $y $r]  $x [+ $y $r]]
		}
		set dataitem [lindex $data $index]
		render1 drawline -coords $squarecoords -ID "$datalabel $dataitem" -CLASS PETTERN -linewidth $linewidth -priority 1 -linecolor $color -closed $closed
		incr index
	    }
	}
    } else {
	render1 drawline -coords $eventlinecoords -ID $datalabel -CLASS PETTERN -fillcolor $color -filled 1 -priority 1  -closed $closed
    }
}

SVGGRAPH instproc drawevents {data yfunction color} {
    set xdiffmin [my eventsize]

    set coords [list]
    set lastx -1.0
    set lastdate 0
    # set lasty $ycenterbase
    set linewidth 3.0
    foreach item $data {
	set date   [lfront $item]
	set x      [my gt2x $date]
	set xleft  [- $x $xdiffmin]
	set xright [+ $x $xdiffmin]
	if {[- $date $lastdate] < 2} {
	    set ycenter [+ $lasty [* $linewidth 3.0]]
	} else {
	    set ycenter [$yfunction [self] $item]
	}
	set coords [list $xleft [- $ycenter $linewidth] $xleft [+ $ycenter $linewidth] $xright [+ $ycenter $linewidth] $xright [- $ycenter $linewidth] $xleft [- $ycenter $linewidth]]
	render1 drawline -coords $coords -ID [lback $item] -CLASS PETTERN -fillcolor $color -filled 1 -linewidth 0.0 -priority 1 -linecolor $color
	set lasty $ycenter
	set lastx $x
	set lastdate $date
    }
}

SVGGRAPH instproc adddataline {dataline datarange color name closed rendertype} {
    my addtimerange [DATALINE::timerange $dataline]
    my lappend datalines $dataline $datarange $color $name $closed $rendertype
}

SVGGRAPH instproc end {} {
    
    foreach {dataline datarange color name closed rendertype} [my datalines] {
        puts "draw dataline"
	my drawdataline $dataline $datarange $color  $name $closed $rendertype
    }
    
    render1 dump
}
