source svgrender.tcl
source drawutils.tcl
source dataline.tcl
source svggraph.tcl

proc gen_graph_datalines {datalines outputfilepath {days no}} {
    set g [SVGGRAPH new -output $outputfilepath -xrange {0 10000} -yrange {0 1000} -seconds no -minutes no -hours no -days $days -months yes -years yes]
    $g initdrawing grey

    # compute global range
    set dataranges [list]
    set timeranges [list]

    foreach item  $datalines {
	foreach {dataline color label} $item break
	lappend dataranges   [DATALINE::datarange $dataline]
	lappend timeranges   [DATALINE::timerange $dataline]
    }

    set maxdatarange [DATALINE::maxrange $dataranges]
    set maxtimerange [DATALINE::maxrange $timeranges]
    
    foreach item $datalines {
	foreach {dataline color label} $item break
	$g adddataline $dataline $maxdatarange $color $label 0 line
    }

    $g gengrid
    $g end
}
