
# source ../utils/hmiutils.tcl
source "utils.tcl"
package require XOTcl; namespace import ::xotcl::* 

Class RENDER
RENDER abstract instproc init {width height}
RENDER abstract instproc get_coords {name anchor}
RENDER abstract instproc remove {tag}
RENDER abstract instproc drawline {args}
RENDER abstract instproc drawcircle {args}
RENDER abstract instproc drawtext {args}
RENDER abstract instproc step {comment}
RENDER abstract instproc update {}
RENDER abstract instproc stepend {}
RENDER abstract instproc stop {}
RENDER abstract instproc tempo {}
RENDER abstract instproc ytrans {}

Class ZINCRENDER -superclass RENDER
ZINCRENDER instproc init {width height tempo} {
    source tkzinc.kit
    package require Tk
    package require Tkzinc
    package require tdom
    
    my instvar scale canvas
    
    my set width  $width
    my set height $height
    my set tempo  $tempo
    
    set scale 1.0
        
    # font create smallfont -family {Arial} -size 8 -weight bold

    # set background "#CEF"
    set background white
    # catch {destroy .}
    # set w [toplevel .]
    set w .
    set canvas [zinc ${w}canvas -width $width -height $height -render 1 -backcolor $background]

    bind $canvas <MouseWheel>       "[self] zoom %D %x %y"
    focus $canvas
    bind $canvas <ButtonPress-1>    "[self] translate_view %x %y start"
    bind $canvas <ButtonRelease-1>  "[self] translate_view %x %y stop"
    bind $canvas <Motion>           "[self] track %x %y"

    grid $canvas -row 0 -column 0 -sticky news
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1
}


Class TRACKER -parameter {{bbox [list]} callbackenter callbackleave {active 0}}

TRACKER instproc contains {x y} {
    foreach {xmin ymin xmax ymax} [my bbox] break
    if {$xmin <= $x && $x <= $xmax && $ymin < $y && $y < $ymax} {
	return 1
    }
    return 0
}

ZINCRENDER instproc track {x y} {
    my instvar trackers

    if {[info exists trackers]} {
    foreach tracker $trackers {
	if {![$tracker active] && [$tracker contains $x $y]} {
	    $tracker active 1
	    eval [$tracker callbackenter]
	} elseif {[$tracker active] && ![$tracker contains $x $y]} {
	    $tracker active 0
	    eval [$tracker callbackleave]
	}
    }
    }
}

ZINCRENDER instproc addtracker {bbox callbackenter callbackleave} {
    my instvar trackers
    lappend trackers [TRACKER new -bbox $bbox -callbackenter $callbackenter -callbackleave $callbackleave]
}


ZINCRENDER instproc ytrans {} {
    return 0
}

ZINCRENDER instproc tempo {} {
    after [my set tempo]
}

ZINCRENDER instproc zoom {dir x y} {
    my instvar scale width height canvas
    global fonts
    
    set dscale [expr {$dir > 0 ? 1.1 : 0.9}]
    set scale  [expr {$scale * $dscale}]

    $canvas translate 1 -$x -$y
    $canvas scale 1 $dscale $dscale
    $canvas translate 1 $x $y

    set plug_visibility [expr {$scale > 0.8} ? 1 : 0]
    $canvas itemconfig plugname -visible $plug_visibility
    $canvas itemconfig plug     -visible $plug_visibility

    if {$scale > 0.5} {
	set newfonts [list]
	foreach font $fonts {
	    set newfont [font create -family Helvetica -size [expr {int(2.0 * $scale)}] -weight bold]
	    .canvas itemconfig $font -font $newfont
	    .canvas addtag $newfont withtag $font
	    lappend newfonts $newfont
	}
	set fonts $newfonts
    }
}

ZINCRENDER instproc translate_view {x y mode} {
    my instvar canvas OX OY xspeeds yspeeds scale stopSlide nmove

    if {[string equal $mode start]} {
	set stopSlide 1
	set xspeeds [list]
	set yspeeds [list]
	bind $canvas <Motion> "[self] translate_view %x %y move"
	foreach {OX OY} [list $x $y] break 
    } elseif {[string equal $mode move]} {
	foreach {x2 y2} [list $x $y] break
	foreach {x1 y1} [list $OX $OY] break    
	# foreach {X1 Y1} [$canvas transform 1 [list $x1 $y1]] break
	# foreach {X2 Y2} [$canvas transform 1 [list $x2 $y2]] break
	# $canvas translate 1 [expr {($X2 - $X1) * $scale}] [expr {($Y2 - $Y1) * $scale}]
	lappend xspeeds [expr {$x2 - $x1}]
	lappend yspeeds [expr {$y2 - $y1}]
	$canvas translate 1 [expr {$x2 - $x1}] [expr {$y2 - $y1}]
	foreach {OX OY} [list $x $y] break
    } elseif {[string equal $mode stop]} {
	bind $canvas <Motion> ""
	set stopSlide 0
	set xspeeds [lrange $xspeeds end-5 end]
	set yspeeds [lrange $yspeeds end-5 end]
	if {[llength $xspeeds]} {
	    set x [expr { double([lsum x $xspeeds {set x}]) / double([llength $xspeeds])}]
	    set y [expr { double([lsum y $yspeeds {set y}]) / double([llength $yspeeds])}]
	    after 10 "[self] translate_view $x $y slide"
	}
    } elseif {[string equal $mode slide]} {
	# puts "translate_view slide $x $y"
	set x [* $x 0.92]
	set y [* $y 0.92]
	set x [expr {abs($x) < 0.001 ? 0.0 : $x}]
	set y [expr {abs($y) < 0.001 ? 0.0 : $y}]
	if {$x != 0.0 || $y != 0.0} {
	    $canvas translate 1 $x $y
	    after 10 "[self] translate_view $x $y slide"
	}
    }
}

ZINCRENDER proc get_circle_coords {xcenter ycenter radius} {
    return [list [expr {$xcenter - $radius}] \
		[expr {$ycenter - $radius}] \
		[expr {$xcenter + $radius}] \
		[expr {$ycenter + $radius}]]
}

ZINCRENDER instproc get_circle_center {circle} {
    my instvar canvas
    
    foreach {P1 P2} [$canvas coords $circle] break
    foreach {x1 y1} $P1 break
    foreach {x2 y2} $P2 break
    return [list [expr {($x1 + $x2) / 2}] [expr {($y1 + $y2) / 2}]]
}


ZINCRENDER instproc get_coords {name} {
    my instvar canvas
    
    foreach {P1 P2} [$canvas coords $name] break
    foreach {x1 y1} $P1 break
    foreach {x2 y2} $P2 break

    return [list $x1 $y1 $x2 $y2]
}

ZINCRENDER instproc remove {tag} {
    [my set canvas] remove $tag
}

ZINCRENDER instproc drawline {args} {
    my instvar canvas

    foreach {key value} $args {
	if {[string equal $key -coords]} {
	    set coords $value
	} else {
	    set keys($key) $value
	}
    }
    eval $canvas add curve 1 [list $coords] [array get keys]
}

ZINCRENDER instproc drawcircle {args} {
    my instvar canvas

    foreach {key value} $args {
	if {[string equal $key -coords]} {
	    set coords $value
	} else {
	    set keys($key) $value
	}
    }

    foreach {x y r} $coords break
    set coords [list [expr {$x - $r}] \
		    [expr {$y - $r}] \
		    [expr {$x + $r}] \
		    [expr {$y + $r}]]

    eval $canvas add arc 1 [list $coords] [array get keys]
}

ZINCRENDER instproc drawrect {args} {
    my instvar canvas

    foreach {key value} $args {
	if {[string equal $key -coords]} {
	    set coords $value
	} else {
	    set keys($key) $value
	}
    }

    eval $canvas add rectangle 1 [list $coords] [array get keys]
}


ZINCRENDER instproc drawtext {args} {
    my instvar canvas

    foreach {key value} $args {
	if {[string equal $key -coords]} {
	    set keys(-position) $value
	} else {
	    set keys($key) $value
	}
    }
    
    array unset keys -fontsize
    eval $canvas add text 1 [array get keys]
}

ZINCRENDER instproc step {comment} {
    my instvar canvas

    # puts "comment $comment"
    $canvas remove stepcomment
    $canvas add text 1 -position {50 50} -text $comment -tags stepcomment
}

ZINCRENDER instproc update {} {
    update
}

ZINCRENDER instproc stepend {} {
    update
}

ZINCRENDER instproc stop {} {
    my tempo
}

Class SVGRENDER -superclass RENDER
SVGRENDER instproc init {width height output} {
    my set width  $width
    my set height $height
    my set output [open $output w+]

    my set Y 10
    my set X 10
    my set ytrans 0
    
    my set network_dumped 0
    my set configuration [list]
    my set network       [list]
}

SVGRENDER proc begin {} {
    return {<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="15cm" height="20cm" viewBox="0 180 %WIDTH% %HEIGHT%" version="1.1"
     xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
}
}

SVGRENDER proc end {} {
    return {
    </svg>
}
}

Class SHAPE -parameter {tags}
SHAPE abstract instproc dump {output}
SHAPE instproc viewbox {} {
    foreach {xmin ymin xmax ymax} [my coords] break
    if {$xmin > $xmax} {
	set dump $xmax; set xmax $xmin; set xmin $dump
    }
    if {$ymin > $ymax} {
	set dump $ymax; set ymax $ymin; set ymin $dump
    }
    return [list $xmin $ymin $xmax $ymax]
}

SHAPE instproc translate {v} {
    foreach {x1 y1 x2 y2} [my coords] break
    foreach x {x1 x2} {
	if {[string length [set $x]]} {
	    set $x [expr {[set $x] + [lindex $v 0]}]
	}
    }
    foreach y {y1 y2} {
	if {[string length [set $y]]} {
	    set $y [expr {[set $y] + [lindex $v 1]}]
	}
    }
    
    set coords [list $x1 $y1]
    if {[string length $x2]} {
	lappend coords $x2 $y2
    }
    my coords $coords
}

Class RLINE -superclass SHAPE -parameter {coords {linestyle simple} {lastend ""} {firstend ""} {linecolor black} {linewidth 1.0}}

RLINE instproc content {} {
    set color [my linecolor]
    set strokedasharray [expr {[string equal [my linestyle] simple] ? "none" : "10,10"}]
    set linewidth [my linewidth]
    set result [list]
    foreach {x1 y1 x2 y2} [my coords] break
    append result "<path d=\"M $x1,$y1 L $x2,$y2\" stroke-width=\"$linewidth\" stroke=\"$color\" fill=\"$color\" stroke-dasharray=\"${strokedasharray}\"/>"
    if {![string equal [my lastend] ""]} {
	set sens [expr {$x2 > $x1 ? -1.0 : 1.0}]
	set rotation [expr {$x2 > $x1 ? "" : "rotate(180.0)"}]
	set xarrow [expr {$x2 + $sens * 8.0}]
	set spath [expr {[string equal [lindex [my lastend] 1] 10] ? "M 0 -10 L 0 10 L 10 0 z" : "M 0 -10 L 0 10 L 10 10 L 10 -10 z"}]

	append result "<path d=\"${spath}\" fill=\"$color\" transform=\"translate($xarrow,$y2) $rotation\"/>"
    }
    if {![string equal [my firstend] ""]} {
	set sens [expr {$x2 > $x1 ? -1.0 : 1.0}]
	set rotation [expr {$x2 > $x1 ? "" : "rotate(180.0)"}]
	set xarrow [expr {$x1 + $sens * 8.0}]
	append result "<path d=\"M 0 -10 L 0 10 L 10 10 L 10 -10 z\" fill=\"$color\" transform=\"translate($xarrow,$y2) $rotation\"/>"
    }

    return $result
}


Class TEXT -superclass SHAPE -parameter {coords text {color black} {fontsize 10} {alignment center} {anchor center}}

TEXT instproc viewbox {} {
    foreach {x y} [my coords] break
    return [list $x $y [expr {$x + [string length [my text]]}] [expr {$y + [my fontsize]}]]
}

TEXT instproc content {} {
    set color [my color]
    foreach {x y} [my coords] break
    set y [expr {$y + [my fontsize] / 2}]
    return "<text x=\"$x\" y=\"$y\" fill=\"$color\" font-size=\"[my fontsize]\" text-anchor=\"middle\">[my text]</text>"
}


Class RECT -superclass SHAPE -parameter {coords {filled true} {fillcolor black} {linewidth 0}}

RECT instproc content {} {
    # puts "RECT content"
    foreach {x1 y1 x2 y2} [my coords] break
    set x $x1
    set y $y1
    set width     [expr {$x2 - $x1}]
    set height    [expr {$y2 - $y1}]
    
    return [string map [list %X% $x %Y% $y %WIDTH% $width %HEIGHT% $height %FILLCOLOR% [my fillcolor]] {<rect x="%X%" y="%Y%" width="%WIDTH%" height="%HEIGHT%" fill="%FILLCOLOR%"/>}]
}

SVGRENDER instproc get_coords {name} {
    # puts "name $name"
    return [$name coords]
}

SVGRENDER instproc remove {tag} {
    my instvar configuration
    set configuration [lremove $configuration $tag]
    # $tag destroy
}

SVGRENDER instproc is_network {tag} {
    if {([string match "*TP*" $tag] || [string match "*TC*" $tag] || [string match "intersector" $tag]) && ![string match "*TI*" $tag]} {
	return 1
    }
    return 0
}

SVGRENDER instproc draw {class args} {
    set args [lindex $args 0]
    array set keys $args
    set name $keys(-tags)
    if {![llength [$class info instances $name]]} {
	$class create $name
    }
    # puts "$name init $args"
    eval $name configure $args
    if {[my is_network $name]} {
	# puts "append $name to network"
	my lappend network $name
    } else {
	# puts "append $name to configuration"
	$name set ytrans [my set ytrans]
	my lappend configuration $name
    }
}

SVGRENDER instproc drawline {args} {
    my draw RLINE $args
}

SVGRENDER instproc drawrect {args} {
    # puts "SVGRENDER drawrect"
    my draw RECT $args
}

SVGRENDER instproc drawtext {args} {
    array set keys $args
    my draw TEXT [array get keys]
}

SVGRENDER instproc network_viewbox {} {
   my instvar network

    foreach shape $network {
	if {![$shape istype TEXT]} {
	    if {![info exists xmin]} {
		foreach {xmin ymin xmax ymax} [$shape coords] break
	    }
	    foreach {sxmin symin sxmax symax} [$shape coords] break
	    if {$sxmin < $xmin} {set xmin $sxmin}
	    if {$symin < $ymin} {set ymin $symin}
	    if {$sxmax > $xmax} {set xmax $sxmax}
	    if {$symax > $ymax} {set ymax $symax}
	}
    }
    
    return [list $xmin $ymin $xmax $ymax]
}

SVGRENDER instproc network_size {} {
    foreach {xmin ymin xmax ymax} [my network_viewbox] break
    set width  [expr {$xmax - $xmin}]
    set height [expr {$ymax - $ymin}]
    return [list $width $height]
}

SVGRENDER instproc dump_network {} {
    my instvar network

    my addcontent "<defs>\n"
    my addcontent "<g id=\"Network\">\n"
    foreach shape $network {
	my addcontent [$shape content]
    }
    my addcontent "</g>\n"
    my addcontent "</defs>\n"
}

# must split a text in lines containin complete words and whose number of char is inferior to nletters
SVGRENDER instproc split_string {string nletters} {
    set result [list]
    set line   ""
    while {[llength $string]} {
	set word [lindex $string 0]
	set string [lrange $string 1 end]
	if {[string length $line] + [string length $word] + 1 > $nletters} {
	    lappend result $line
	    set line ""
	}
	append line "$word "
    }

    lappend result $line
    
    return $result
}

SVGRENDER instproc step {comment} {
    my instvar network X Y ytrans oytrans
    
    if {![my set network_dumped]} {
	my dump_network
	my set network_dumped 1
    }
    
    my addcontent "<g transform=\"translate(0.0,[expr {double($Y)}])\" >\n"
    set pagewidth  [lindex [my network_size] 0]
    set xnetwork   [lindex [my network_viewbox] 0]
    set fontsize   20
    set lines      [my split_string $comment [expr {$pagewidth / ( $fontsize / 2 )}]]
    set interline  $fontsize
    set ytext      210

    set xframe      $xnetwork
    set yframe      [expr {$ytext - $fontsize}]    
    set frameheight [expr {([llength $lines] + 0.5) * $interline}]
    set framewidth  $pagewidth
    
    my addcontent [string map [list %Y% $yframe %X% $xframe %WIDTH% $framewidth %HEIGHT% $frameheight] {<rect x="%X%" y="%Y%" width="%WIDTH%" height="%HEIGHT%" fill="black" stroke="none" />}]
    foreach line $lines {
	my addcontent "<text x=\"[expr {$xframe + $fontsize / 2}]\" y=\"$ytext\" fill=\"white\" font-size=\"$fontsize\">$line</text>\n"
	incr ytext $interline
    }
    incr Y      [expr {int($frameheight)}]
    if {[info exists ytrans]} {
	set oytrans $ytrans
    }

    set X $pagewidth
    set ytrans [expr {[expr {int($frameheight)}] - $fontsize}]
}

SVGRENDER instproc update {} {
    # nothing to do
}

SVGRENDER instproc ytrans {} {
    return [my set ytrans]
}

SVGRENDER instproc stepend {} {
    my instvar X Y ytrans oytrans

    set fontsize 20
    my addcontent "<use xlink:href=\"\#Network\" transform=\"translate(0,${ytrans})\"/>\n"
    
    foreach shape [my set configuration] {
	if {[info exists oytrans]} {
	    $shape translate [list 0 [expr {$ytrans - [$shape set ytrans]}]]
	}
	my addcontent [$shape content]
    }
    
    my addcontent "</g>\n"
    incr Y 280
}

SVGRENDER instproc addcontent {newcontent} {
    my instvar content
    append content "$newcontent\n"
}

SVGRENDER instproc stop {} {
    my instvar output X Y content
    incr Y 40
    incr X 40
    puts $output [string map [list %WIDTH% $X %HEIGHT% $Y] [SVGRENDER begin]]
    puts $output $content
    puts $output [SVGRENDER end]
    close $output
}

SVGRENDER instproc tempo {} {
    # nothing to do
} 
