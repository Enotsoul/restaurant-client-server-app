if {$::argv0 != [info script]} { return }
package require Tk
#Draw a table that has x nr seats
# and the table will be either rectangular or round
#Save location
 
#Recommended for formal dining
set tableTypes {
 2 seats	75 x 75  rect/round
 4 seats 100 x 100  rect/round all corners 
 4 seats 120 x 75 rect
 6 seats 180 x 75 rect
 8 seats 240 x 80 rect
 6 seats 120 x 120 round
 8 seats 150 x 180 round
 10 seats 180 x 180 round
}
grid [canvas .c -width 1000 -height 600 -bg white]

set tables [dict create]

proc drawTable {seats {tableType rect}} {
	set t [llength [dict keys $::tables]]
	incr t
	
	#Sizes in CM
	set tableWidthPerPerson 60
	set tableHeightPerPerson 75
	
	set seatWidth [expr {$tableWidthPerPerson/2}]
	#Determine & calculate starting position somehow based on all tables around
	#height + width of table + seats/chairs
	set tablex 10
	set tabley 45
	
	set tablewidth [expr {$seats/2*$tableWidthPerPerson*0.66}]
	set tableheight [expr {$tableHeightPerPerson*0.66}]

	set tableFinalY [expr {$tabley+$tableheight}] 
	#Draw out the table
	set table [.c create rect $tablex $tabley  [expr {$tablex+$tablewidth}] $tableFinalY  -fill gray]
	
	#Draw the seats 
	set startPosY [expr {10}]
	set j 0
	set seatHeight $seatWidth
	for {set i 0} {$i <$seats} {incr i} {
		#Width / 600 if exceeding, then draw on the other side
		set start 0
		set startPosX [expr {$tablex+$i*$seatWidth+$i*10+5}]
		set startPosY [expr {10}]

		if {$tablewidth <= $startPosX} {
			set startPosX [expr {$tablex+$j*$seatWidth+$j*10+5}]
			set startPosY [expr {$tableFinalY+5}]
			incr j
			set start 180
			.c create rect $startPosX $startPosY [expr {$startPosX+$seatWidth}]  [expr {$startPosY+$seatHeight/2}] -fill lightgreen -outline lightgreen
		#	incr startPosY 15
			.c create arc $startPosX $startPosY  [expr {$startPosX+$seatWidth}]  [expr {$startPosY+$seatHeight}] -fill lightgreen -extent 180 -start $start  -outline lightgreen
		} else {
			.c create arc $startPosX $startPosY  [expr {$startPosX+$seatWidth}]  [expr {$startPosY+$seatHeight}] -fill lightgreen -extent 180 -start $start  -outline lightgreen
			incr startPosY 15
			.c create rect $startPosX $startPosY [expr {$startPosX+$seatWidth}]  [expr {$startPosY+$seatHeight/2}] -fill lightgreen  -outline lightgreen
		}
		
	#	break
	}
}
#drawTable 4
#drawTable 6
#drawTable 8

#Rotate an existing image 
 proc imgrot90t {img {clockwise 0} {bg {255 255 255}}} {
    set w [image width $img]
    set h [image height $img]
    set im2 [image create photo -width $h -height $w]
    for {set i 0} {$i<$h} {incr i} {
         for {set j 0} {$j<$w} {incr j} {
             if $clockwise {
                 set color [$img get $j [expr {$h-$i-1}]]
             } else {
                 set color [$img get [expr {$w-$j-1}] $i]
             }
             if {$color ne $bg} {
                 $im2 put [eval format #%02x%02x%02x $color] -to $i $j
             }
         }
    }
    set im2
 }
 
foreach size {2 4 6 8 12} {
	 image create photo table_$size -file ./img/rect_table_${size}.png
}

foreach {loc} {n e w s} {
image create photo chair_$loc -file ./img/chairsmall_${loc}.png
}

#Total space arround a table
#table width  + chairheight x 2
#table height + chairheight x 2

