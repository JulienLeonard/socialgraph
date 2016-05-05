source utils.tcl
source datalinegraph.tcl

proc twitter_stat_dir {} {
    # to be overloaded
}

proc pystatdir {} {
    # to be overloaded
}

proc twitter_stat_filepaths {} {
    set result []
    foreach dir [glob -directory [twitter_stat_dir] -type d *] {
	if {[string match *twitter $dir]} {
	    catch {lappend result [lindex [glob -directory $dir *] 0]}
	}
    }
    return $result
}

proc twitter_format_stats {v} {
    return [string map {"," ""} $v]
}

proc twitter_nfollowers {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	instxmlattributes $xmlroot {nfollowers}
	return [twitter_format_stats $nfollowers]
    }
    return ""
}

proc twitter_nfavsandrt {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	set count 0
	foreach postnode [$xmlroot selectNodes //twitter/post] {
	    instxmlattributes $postnode {name timestamp fav_count rt_count}
	    incr count [+ $fav_count $rt_count]
	}
	return [twitter_format_stats $count]
    }
    return ""
}

proc twitter_timestamp {filepath} {
    set xmlroot [freadxml $filepath]
    if {[string length $xmlroot]} {
	instxmlattributes $xmlroot {timestamp}
	return [lfront [split $timestamp .]]
    }
    return ""
}

proc twitter_nfollowers_timeline {} {
    set result [list]
    foreach filepath [twitter_stat_filepaths] {
	set nfollowers [twitter_nfollowers $filepath]
	set timestamp  [twitter_timestamp  $filepath]
	if {![sempty $nfollowers] && ![sempty $timestamp]} {
	    lappend result [list $timestamp $nfollowers]
	}
    }
    return [lsort -integer -index 0 -increasing $result]
}

proc twitter_nfavs_timeline {} {
    set result [list]
    foreach filepath [twitter_stat_filepaths] {
	set nfavs [twitter_nfavsandrt $filepath]
	set timestamp  [twitter_timestamp  $filepath]
	if {![sempty $nfavs] && ![sempty $timestamp]} {
	    lappend result [list $timestamp $nfavs]
	}
    }
    return [lsort -integer -index 0 -increasing $result]
}



proc twitter_graph_datalines {{filepath "twitter_datalines.svg"}} {
    gen_graph_datalines [list [list [twitter_nfollowers_timeline] orange nfollowers] [list [twitter_nfavs_timeline] yellow nfavs]] $filepath yes   
}

proc twitter_new_stats {} {
    puts "start twitter"
    if {[catch "exec python.exe [pystatdir]/pystats.py twitter" msg]} {
	puts "Something seems to have gone wrong $msg"
    }

}

proc twitter_refresh_timelines {{filepath "twitter_datalines.svg"}} {
    twitter_new_stats
    twitter_graph_datalines $filepath
}

proc test_twitter_stat_filepaths {} {
    puts "twitter_stat_filepaths [join [twitter_stat_filepaths] \n]"
}

proc test_twitter_nfollowers {} {
    foreach filepath [twitter_stat_filepaths] {
	puts "filepath $filepath nfollowers [twitter_nfollowers $filepath]"
    }
}

proc test_twitter_timestamp {} {
    foreach filepath [twitter_stat_filepaths] {
	puts "filepath $filepath timestamp [twitter_timestamp $filepath]"
    }
}

proc test_twitter_nfollowers_timeline {} {
    puts [join [twitter_nfollowers_timeline] \n]
}

proc test_graph_dataline_twitter_nfollowers {} {
    gen_graph_datalines [list [list [twitter_nfollowers_timeline] orange nfollowers]] "twitter_nfollowers_timeline.svg"
}



# test_twitter_stat_filepaths
# test_twitter_nfollowers
# test_twitter_timestamp
# test_twitter_nfollowers_timeline
# test_graph_dataline_twitter_nfollowers
# test_twitter_nviews
# twitter_graph_datalines
# twitter_refresh_timelines
