
proc rank2abs {coords} {
    global layout
    
    foreach {x y} $coords break

    foreach attr {x y} {
	set $attr [double [set $attr]]
    }

    return [list [abscissa [$layout xcoordrange] $x] [abscissa [$layout ycoordrange] $y]] 
}

proc abs2line {coords} {
	set pyrange {100.0 1000.0}
	set pxrange {100.0 10000.0}

	foreach {x y} $coords break
    
	return [list [int [sample $pxrange $x]] [int [sample $pyrange $y]]]
    
}

proc int2pixel {coords} {
    global layouttype

    if {[s= $layouttype line]} {

	if {0} {
	    global ccllinewidth
	    global ccllinenumber

	    set trackinterspace [* $ccllinenumber [* $ccllinewidth 2]]
	    foreach {x y} $coords break
	    return [list [expr {100 + $x * 30}] [expr {100 + $y * $trackinterspace}]]
	}
	return [abs2line [rank2abs $coords]]
    } elseif {[s= $layouttype circle]} {
	return [circlecoords $coords] 
    } 
}

proc polycoords {ext1 ext2 width shape} {
    foreach {x1 y1} $ext1 break
    foreach {x2 y2} $ext2 break
    set coords [list $x1 [+ $y1 $width] $x2 [+ $y1 $width] $x2 [- $y2 $width] $x1 [- $y2 $width] $x1 [+ $y1 $width]]
    return $coords
}

proc middlecoords {coords1 coords2 offset} {
    forzip a $coords1 b $coords2 {
	lappend middlecoords [expr {double($a + $b)/2.0}]
    }
    lset middlecoords 1 [expr {[lindex $middlecoords 1] + $offset}]
    return $middlecoords
}

proc roundedrect {coords1 coords2 width} {
    foreach {x1 y1} $coords1 break
    foreach {x2 y2} $coords2 break

    return [list drawline [list [- $x1 $width] $y1 [+ $x2 $width] $y1 [+ $x2 $width] $y2 [- $x1 $width] $y2 [- $x1 $width] $y1] \
		drawline [list $x1 [- $y1 $width] $x2 [- $y1 $width] $x2 [+ $y2 $width] $x1 [+ $y2 $width] $x1 [- $y1 $width]] \
		drawcircle [list $x1 $y1 $width] drawcircle [list $x1 $y2 $width] drawcircle [list $x2 $y2 $width] drawcircle [list $x2 $y1 $width]]
}


proc roundedline {coords1 coords2 width offset} {
    foreach {x1 y1} $coords1 break
    foreach {x2 y2} $coords2 break
    
    if {$y1 == $y2} {
	set rx1 [+ $x1 $width]
	set rx2 [- $x2 $width]
	set xmax [expr {$x2 > $x1 ? $x2 : $x1}]
	set xmin [expr {$x2 < $x1 ? $x2 : $x1}]
	set x1 $xmin
	set x2 $xmax
	set rcoords  [list $rx1 [+ $y1 $width] $rx2 [+ $y1 $width] $rx2 [- $y2 $width] $rx1 [- $y2 $width] $rx1 [+ $y1 $width]]
	set ccoords1 [list $rx1 $y1 $width]
	set ccoords2 [list $rx2 $y2 $width]
    } else {
	set x [expr {double(abs($x2 - $x1))}]
	set y [expr {double(abs($y2 - $y1))}]
	set dist [expr {sqrt($x * $x + $y * $y)}]
	set cos  [expr {$x / $dist}]
	set sin  [expr {$y / $dist}]
	set rcoords  [list [- $x1 $width] [+ $y1 $width] [- $x2 $width] [- $y2 $width] [+ $x2 $width] [- $y2 $width] [+ $x1 $width] [+ $y1 $width] [- $x1 $width] [+ $y1 $width]]
	set op1 [expr {$y1 > $y2 ? "+" : "-"}]
	set op2 [expr {$y1 > $y2 ? "-" : "+"}]
	set ccoords1 [list $x1 [$op1 $y1 $width] $width]
	set ccoords2 [list $x2 [$op2 $y2 $width] $width]
    }
    # return [list drawline $rcoords drawcircle $ccoords1 drawcircle $ccoords2]
    if {$y1 == $y2} {
	return [list drawline [list $x1 [+ $y1 $width] $x2 [+ $y1 $width] $x2 [- $y2 $width] $x1 [- $y2 $width] $x1 [+ $y1 $width]]]
    } else {
	return [list drawline [list [- $x1 $width] $y1 [- $x2 $width] $y2 [+ $x2 $width] $y2 [+ $x1 $width] $y1 [- $x1 $width] $y1]]
    }
    # return [list drawline [list $x1 $y1 $x2 $y2]]
}

proc ccltrackpath {rankcoords1 rankcoords2 width offset layouttype} {
    if {[s= $layouttype line]} {
	return [ccllinepath $rankcoords1 $rankcoords2 $width $offset]
    } elseif {[s= $layouttype circle]} {
	return [cclcirclerailpath $rankcoords1 $rankcoords2 $width $offset]
    } else {
	puts "ERROR: no layouttype $layouttype"
    }
}

proc ccllinepath {rankcoords1 rankcoords2 width offset} {
    foreach {coords1 coords2} [map intcoords [list $rankcoords1 $rankcoords2] {int2pixel $intcoords}] break
    foreach {x1 y1} $coords1 break
    foreach {x2 y2} $coords2 break    
    
    if {$y1 == $y2} {
	set y1  [+ [+ $y1 $offset] $width]
	set sens [? [expr {$offset > 0}] 1 -1]
	set y2  [+ $y2 [* $sens $width]]
	return [list $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1]
    } else {
	set x11 [+ [+ $x1 $offset] $width]
	set x12 [- [+ $x1 $offset] $width]
	set x21 [+ [+ $x2 $offset] $width]
	set x22 [- [+ $x2 $offset] $width]
	return [list $x11 $y1 $x12 $y1 $x22 $y2 $x21 $y2 $x11 $y1]	
    }
}

proc cclrailpath {rankcoords1 rankcoords2 width offset} {
    foreach {coords1 coords2} [map intcoords [list $rankcoords1 $rankcoords2] {int2pixel $intcoords}] break
    foreach {x1 y1} $coords1 break
    foreach {x2 y2} $coords2 break    
    if {$y1 == $y2} {
	return [list [ccllinepath $rankcoords1 $rankcoords2 [/ $width 2] [+ $offset [/ $width 2]]] [ccllinepath $rankcoords1 $rankcoords2 [/ $width 2] [- $offset [/ $width 2]]]]
    } else {
	return [list [ccllinepath $rankcoords1 $rankcoords2 [/ $width 3] [+ $offset [/ $width 3]]] [ccllinepath $rankcoords1 $rankcoords2 [/ $width 3] [- $offset [/ $width 3]]]]
    }
}

proc cclarcpath {coords1 coords2 width offset} {
    global layouttype
    global layout
    
    foreach {x1 y1} $coords1 break
    foreach {x2 y2} $coords2 break

    foreach attr {x1 y1 x2 y2} {
	set $attr [rank2abs [set $attr]]
    }

    set circleradiusranges [list 1000.0 1500.0]
    set angleranges        [list 0.0 2.0 * 3.14159]
    foreach {xcenter ycenter} [list 1500.0 1500.0] break
    
    set r11 [sample $circleradiusranges [- $y1 $width]]
    set r12 [sample $circleradiusranges [+ $y1 $width]]
    set r21 [sample $circleradiusranges [- $y2 $width]]
    set r22 [sample $circleradiusranges [+ $y2 $width]]

    set a1 [sample $angleranges $x1]
    set a2 [sample $angleranges $x2]
    
    set x11 [expr {$xcenter + $r11 * cos($a1)}]
    set y11 [expr {$ycenter + $r11 * sin($a1)}]
    set x21 [expr {$xcenter + $r21 * cos($a2)}]
    set y21 [expr {$ycenter + $r21 * sin($a2)}]
    set x12 [expr {$xcenter + $r12 * cos($a1)}]
    set y12 [expr {$ycenter + $r12 * sin($a1)}]
    set x22 [expr {$xcenter + $r22 * cos($a2)}]
    set y22 [expr {$ycenter + $r22 * sin($a2)}]

    return [list $x11 $y11 $x12 $y22 $x22 $x21 $y21 $x11 $y11] 
}

proc circlecoords {rankcoords} {    
    set circleradiusranges [list 2000.0 1500.0]
    set angleranges        [list 0.0 [* 2.0 3.14159]]
    foreach {xcenter ycenter} [list 1000.0 1000.0] break

    foreach {x y} [rank2abs $rankcoords] break
    set r [sample $circleradiusranges $y]
    set a [sample $angleranges $x]
    set rx [expr {$xcenter + $r * cos($a)}]
    set ry [expr {$ycenter + $r * sin($a)}]
    return [list $rx $ry]
}

proc cclcirclerailpath {rankcoords1 rankcoords2 width offset} {
    global layout
    
    # foreach {x1 y1} [rank2abs $rankcoords1] break
    # foreach {x2 y2} [rank2abs $rankcoords2] break

    foreach {x1 y1} $rankcoords1 break
    foreach {x2 y2} $rankcoords2 break

    set linewidth [* 0.01 $width]
    set y11 [- $y1 $linewidth]
    set y12 [+ $y1 $linewidth]
    set y21 [- $y2 $linewidth]
    set y22 [+ $y2 $linewidth]

    foreach {x11 y11} [circlecoords [list $x1 $y11]] break
    foreach {x12 y12} [circlecoords [list $x1 $y12]] break
    foreach {x21 y21} [circlecoords [list $x2 $y21]] break
    foreach {x22 y22} [circlecoords [list $x2 $y22]] break

    # set result [list [map d [list $x11 $y11 $x12 $y12 $x22 $y22 $x21 $y21 $x11 $y11] {int $d}]]
    set result [list $x11 $y11 $x12 $y12 $x22 $y22 $x21 $y21 $x11 $y11]
    puts "result $result"
    return $result
}




proc polypath {skeleton width offset} {
    set upcoordlist [list]
    set downcoordlist [list]
    foreach coords $skeleton {
	foreach {x y} $coords break
	lappend upcoordlist   [list [double $x] [double [- $y $offset]]]
	lappend downcoordlist [list [double $x] [double [+ $y $offset]]]
    }

    set result [lconcat $upcoordlist [lreverse $downcoordlist]]
    lappend result [lindex $upcoordlist 0]
    return $result
}
