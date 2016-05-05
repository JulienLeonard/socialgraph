source utils.tcl
source datalinegraph.tcl

proc faa_stat_dir {} {
    # to be overloaded
}

proc pystatdir {} {
    # to be overloaded
}

proc faa_stat_filepaths {} {
    set result []
    foreach dir [glob -directory [faa_stat_dir] -type d *] {
	if {[string match *fineartamerica $dir]} {
	    catch {lappend result [lindex [glob -directory $dir *] 0]}
	}
    }
    return $result
}

proc faa_format_stats {v} {
    return [string map {"," ""} $v]
}

proc faa_nfollowers {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	instxmlattributes $xmlroot {nfollowers}
	return [faa_format_stats $nfollowers]
    }
    return ""
}

proc faa_timestamp {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	instxmlattributes $xmlroot {timestamp}
	return [lfront [split $timestamp .]]
    }
    return ""
}

proc faa_nvisitors {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	instxmlattributes $xmlroot {nvisitors}
	return [faa_format_stats $nvisitors]
    }
    return ""
}

proc faa_nviews {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	if {[$xmlroot hasAttribute nviews]} {
	    instxmlattributes $xmlroot {nviews}
	    return [faa_format_stats $nviews]
	}
    }
    return ""
}


proc faa_nfollowers_timeline {} {
    set result [list]
    foreach filepath [faa_stat_filepaths] {
	set nfollowers [faa_nfollowers $filepath]
	set timestamp  [faa_timestamp  $filepath]
	if {![sempty $nfollowers] && ![sempty $timestamp]} {
	    lappend result [list $timestamp $nfollowers]
	}
    }
    return [lsort -integer -index 0 -increasing $result]
}

proc faa_nvisitors_timeline {} {
    set result [list]
    foreach filepath [faa_stat_filepaths] {
	set nvisitors     [faa_nvisitors     $filepath]
	set timestamp     [faa_timestamp  $filepath]
	if {$nvisitors != 0 && ![sempty $timestamp]} {
	    lappend result [list $timestamp $nvisitors]
	}
    }
    return [lsort -integer -index 0 -increasing $result]
}

proc faa_nviews_timeline {} {
    set result [list]
    foreach filepath [faa_stat_filepaths] {
	set nviews        [faa_nviews     $filepath]
	set timestamp     [faa_timestamp  $filepath]
	if {![sempty $nviews] && ![sempty $timestamp]} {
	    lappend result [list $timestamp $nviews]
	}
    }
    return [lsort -integer -index 0 -increasing $result]
}

proc faa_graph_datalines {{filepath "faa_datalines.svg"}} {
    gen_graph_datalines [list [list [faa_nfollowers_timeline] orange nfollowers] [list [faa_nvisitors_timeline] yellow nvisitors] [list [faa_nviews_timeline] green nviews]] $filepath yes   
}

proc faa_new_stats {} {
    puts "start fineartamerica"
    if {[catch "exec python.exe [pystatdir]/pystats.py fineartamerica" msg]} {
	puts "Something seems to have gone wrong $msg"
    }
}

proc faa_refresh_timelines {{filepath "faa_datalines.svg"}} {
    faa_new_stats
    faa_graph_datalines $filepath
}

proc test_faa_stat_filepaths {} {
    puts "faa_stat_filepaths [join [faa_stat_filepaths] \n]"
}

proc test_faa_nfollowers {} {
    foreach filepath [faa_stat_filepaths] {
	puts "filepath $filepath nfollowers [faa_nfollowers $filepath]"
    }
}

proc test_faa_nviews {} {
    foreach filepath [faa_stat_filepaths] {
	puts "filepath $filepath nviews [faa_nviews $filepath]"
    }
}

proc test_faa_timestamp {} {
    foreach filepath [faa_stat_filepaths] {
	puts "filepath $filepath timestamp [faa_timestamp $filepath]"
    }
}

proc test_faa_nfollowers_timeline {} {
    puts [join [faa_nfollowers_timeline] \n]
}

proc test_graph_dataline_faa_nfollowers {{filepath "faa_nfollowers_timeline.svg"}} {
    gen_graph_datalines [list [list [faa_nfollowers_timeline] orange nfollowers]] $filepath
}



# test_faa_stat_filepaths
# test_faa_nfollowers
# test_faa_timestamp
# test_faa_nfollowers_timeline
# test_graph_dataline_faa_nfollowers
# test_faa_nviews
# faa_graph_datalines
# faa_refresh_timelines
