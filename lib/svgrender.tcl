source render.tcl

Class SVGRENDER -superclass RENDER 
SVGRENDER instproc init {width height output {background "white"}} {
    my set width  $width
    my set height $height
    my set output $output
    my set content ""
    my set content2 ""
    my set background $background
}

SVGRENDER instproc x1y1x2y2TOxywithheight {coords} {
    foreach {x1 y1 x2 y2} $coords break
    set width  [- $x2 $x1]
    set height [- $y2 $y1]
    return [list $x1 $y1 $width $height]
}

SVGRENDER instproc rgbfromstring {string} {
    if {[s= $string white]} {
	return {255 255 255}
    } elseif {[s= $string grey]} {
	return {125 125 125}
    } elseif {[s= $string red]} {
	return {255 0 0}
    } elseif {[s= $string yellow]} {
	return {255 255 0}
    } elseif {[s= $string black]} {
	return {0 0 0}
    } elseif {[s= $string blue]} {
	return {0 0 255}
    } elseif {[s= $string green]} {
	return {0 255 0}
    } elseif {[s= $string violet]} {
	return {255 0 255}
    } elseif {[s= $string pink]} {
	return {255 200 200}
    } elseif {[s= $string darkblue]} {
	return {0 0 200}
    } elseif {[s= $string lightblue]} {
	return {220 220 255}
    } elseif {[s= $string darkgreen]} {
	return {0 200 0}
    } elseif {[s= $string orange]} {
	return {255 100 0}
    } else {
	puts "error: color $string unknown"
	return {100 100 100}
    }
}

SVGRENDER instproc c255int {v} {
    if {[s= [int $v] $v]} {
	return $v
    } elseif {$v < 1.0} {
	return [expr {int(255.0 * $v)}]
    } else {
	return NA
    }
}

SVGRENDER instproc c1double {v} {
    if {[s= [double $v] $v]} {
	return $v
    } else {
	return [expr {double($v)/100.0}]
    }
}

SVGRENDER instproc rgba {color} {
    if {[llength $color] == 1} {
	foreach {color a} [split $color ";"] break
	if {![string length $a]} {
	    set a 100
	}
	set rgb [my rgbfromstring $color]
	set a [expr {double($a)/100.0}]
	return [lconcat $rgb [list $a]]
    } else {
	foreach {r g b a} $color break
	foreach v {r g b} {
	    set $v [my c255int [set $v]]
	}
	set a [my c1double $a]
	return [list $r $g $b $a]
    }
}

SVGRENDER instproc opengroup {args} {
    setargs
    checkargs id
    my instvar content
    append content "<g id=\"$id\" opacity=\"1.0\">\n"
}

SVGRENDER instproc closegroup {args} {
    setargs
    checkargs id
    my instvar content
    append content "</g>\n"    
}

SVGRENDER instproc drawtext {args} {
}

SVGRENDER instproc drawcircle {args} {
    source svgtemplate.tcl
    setargs
    checkargs coords ID CLASS
    my instvar content
    foreach {sfillcolor fillopacity sstrokecolor strokeopacity} [eval my svgcolors $args] break 

    set TITLE $ID
    foreach {cx cy radius} $coords break
    append content [string map [list %ID% $ID %CLASS% $CLASS %TITLE% $TITLE %CX% $cx %CY% $cy %RADIUS% $radius %FILLCOLOR% $sfillcolor %STROKECOLOR% $sstrokecolor] $circletemplate]
    append content "\n"
}

SVGRENDER instproc svgcolors {args} {
    setargs
    # colors
    set sfillcolor none
    set sstrokecolor none
    set fillopacity 1.0
    set strokeopacity 1.0
    if {[info exists fillcolor] && [info exists filled]} {
	set sfillcolor  "#[join [map v [lrange [my rgba $fillcolor] 0 end-1] {format %02x $v}] {}]"
	set fillopacity [lback [my rgba $fillcolor]]
    }
    if {[info exists linewidth] && $linewidth > 0} {
	if {[info exists linecolor]} {
	    set sstrokecolor  "#[join [map v [lrange [my rgba $linecolor] 0 end-1] {format %02x $v}] {}]"
	    set strokeopacity [lback [my rgba $linecolor]]
	} else {
	    set sstrokecolor "black"  
	}
    }
    return [list $sfillcolor $fillopacity $sstrokecolor $strokeopacity]
}

SVGRENDER instproc drawline {args} {
    my instvar content
    setargs
    checkargs coords ID CLASS

    source svgtemplate.tcl

    # points string 
    set points "M"
    foreach {x y} $coords {
	append points "$x $y "
    }

    checkvar closed 1
    if {$closed} {
	append points "z"
    }

    checkvar linewidth 0
    
    
    # colors
    foreach {sfillcolor fillopacity sstrokecolor strokeopacity} [eval my svgcolors $args] break 

    set TITLE $ID
    append content [string map [list %ID% $ID %CLASS% $CLASS %TITLE% $TITLE %FILLCOLOR% $sfillcolor %STROKECOLOR% $sstrokecolor %FILLOPACITY% $fillopacity %STROKEOPACITY% $strokeopacity %STROKEWIDTH% $linewidth %POINTS% $points] $itemtemplate]             
    append content "\n"
}

SVGRENDER instproc drawanime {args} {
    my instvar content
    setargs
    checkargs coordss ID CLASS

    source svgtemplate.tcl

    set paths [list]
    foreach {pathtype coords} $coordss { 
	# points string 
	set points "M"
	foreach {x y} $coords {
	    append points "$x $y "
	}
	append points "z"
	lappend paths $pathtype $points
    }

    array set svgpaths $paths
    set linecirclevalues "$svgpaths(line);$svgpaths(circle)"
    set circlelinevalues "$svgpaths(circle);$svgpaths(line)"
    set points [lindex $paths 1]
    
    # colors
    foreach {sfillcolor fillopacity sstrokecolor strokeopacity} [eval my svgcolors $args] break 

    set TITLE $ID
    append content [string map [list %LINECIRCLEVALUES% $linecirclevalues %CIRCLELINEVALUES% $circlelinevalues %ID% $ID %CLASS% $CLASS %TITLE% $TITLE %FILLCOLOR% $sfillcolor %STROKECOLOR% $sstrokecolor %POINTS% $points] $animtemplate]             
    append content "\n"
}


SVGRENDER instproc drawrect {args} {
    my instvar content
    setargs
    checkargs coords color

    set coords [my x1y1x2y2TOxywithheight $coords]
    set color  [my rgba $color]

    set scoords [join $coords ,]
    set scolor  [join $color ,]

    append content [string map [list %ID% $ID %CLASS% $CLASS %TITLE% $TITLE %FILLCOLOR% $fillcolor %STROKECOLOR% $strokecolor %POINTS% $points] $itemtemplate]             
    append content "\n"
}

SVGRENDER instproc drawimage {args} {
    my instvar content2
    setargs
    checkargs name filename x y width height source
    append content2 [string map [list  %FILENAME% $filename %X% $x %Y% $y %WIDTH% $width %HEIGHT% $height %SOURCE% $source] {<image name="%NAME%" ID="%ID%" x="%X%" y="%Y%" width="%WIDTH%" height="%HEIGHT%" preserveAspectRatio="xMaxYMax" source="%SOURCE%" xlink:href="%FILENAME%"/>}]             
    append content2 "\n"
}


SVGRENDER instproc dump {} {
    my instvar output content content2 background
    source svgtemplate.tcl    
    fput $output [string map [list %CONTENT% $content %CONTENT2% $content2  %BACKGROUND% $background] $svgtemplate]
}
