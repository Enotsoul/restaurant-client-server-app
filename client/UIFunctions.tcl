#Utility functions
nx::Class create UIFunctions {
	
	#TODO loading from client location
	:public method createProductImage {imgName img type} {
		if {![string match *$imgName* [image names]  ]} { 
			set img [image create photo $imgName -file "./images/${type}_$img"] 
		}
		return $imgName
	}

	#Calculate correct width based on the normal product width OR
	#on the actual image width if a image is specified! (useful to remove unwanted padding!)
	:public method getCorrectWidth {{-width ""} style {image ""}} {
		if {$width == ""} {
			if {$image == ""} {
				if {[dict exists ${:productSettings} width]} {
					set width [dict get ${:productSettings} width]
				} else { error "You need to either define :productSettings width OR specify a -width argument OR give an image name" }
			} else {
				set width [image width $image]
			}
		}
		set font [ttk::style lookup $style -font]
		set testtext "1234567890-=qwertyuiop[]asdfghjkl;'\<zxcvbnm,./QWERTYUIOPASDFGHJKLZXCVBNM"
		set textlength [string length $testtext]
		set measurement [font measure $font $testtext]
		set wpc [expr {double($measurement)/$textlength}]

		set correctWidth [expr {int(ceil($width/$wpc))}]
		
		if {$correctWidth < 8} { set correctWidth 8 }
	#	puts "For a width of $width the width per character is $wpc and the correctWidth is $correctWidth"
		return $correctWidth
	}

	#Calculate how many max products to show based on screen size
	:public method maxProductsToShow {{-width 0} {-height 0} productWidth productHeight} {
		if {!$width} {  set width [winfo width .] }
		if {!$height} { set height [winfo height .] }

		puts "width x height $width x $height"
		set ::productsPerRow [expr {$width/$productWidth }]
		set ::productsPerPage  [expr {($height*$width) / ($productWidth*$productHeight)}]
		return $::productsPerPage 
	}

	#Generate a "dialog" toplevel
	:public method generateDialog {{-grab 0} {-dialog 0 } name {title ""} } {
		toplevel $name 
		$name configure -bg  $::ttk::theme::cerulean::theme(bgcolor) 
		wm title $name $title

		if {$dialog} {
			#-topmost yes
			wm attributes $name   -type dialog;#notification
			#	wm focusmodel .selectQuantity active
			wm overrideredirect $name  1
		}

		#Grab makes selected window active, 
		#to avoid error we need to tkwait for the visibility of the window
		if {$grab} {
			tkwait visibility $name
			grab set $name
		}

		:centerWindowBasedOn $name . 
		return $name
	}
	
	#Center childwindow based on the parentwindow x,y and width/height location
	#TODO get width/height of current window in calculation
	:public method centerWindowBasedOn { childWindow parentWindow} {
		set x [winfo x $parentWindow]
		set y [winfo y $parentWindow]
		set width [winfo width $parentWindow]
		set height [winfo height $parentWindow]

		set childwidth [winfo width $childWindow]
		set childheight [winfo height $childWindow]
		 
		puts "child $childwidth x $childheight parent $width x $height  x,y $x,$y"

		set x [expr {int($x+($width-$childwidth)/2)}]
		set y [expr {int($y+($height-$childheight)/2)}]
		wm geometry $childWindow  +$x+$y
	}

	:public method scrolledFrameToplevel {{-width 0} {-height 0} args} {
		if {!$width} {  set width [expr {int( [winfo width .]*0.7)} ] }
		if {!$height} {  set height [expr {int( [winfo height .]*0.7)} ] }
		set toplevel [:generateDialog {*}$args]
		
		set scrolledFrame $toplevel.sf
		#-height 400 -width 240
		scrolledframe $scrolledFrame -width $width -height $height  \
			-xscroll [list $toplevel.hs set] -yscroll [list $toplevel.vs set]

		set f $scrolledFrame.scrolled
		:scrolledFrameToplevelGrid
		:scrolledFrameToplevelBackground
		:scrolledFrameToplevelCanvas $f
		:scrolledFrameToplevelBindings $scrolledFrame
		
		set time [clock milliseconds]
		tkwait visibility $toplevel
		 puts "Difference [expr {[clock milliseconds]-$time}]"
		:centerWindowBasedOn $toplevel . 
	#	bind $toplevel <Visibility> [:callback centerWindowBasedOn  $toplevel .]
		
		return $f
	}

	:method scrolledFrameToplevelGrid {} {
		foreach {var}  {scrolledFrame toplevel} { :upvar $var $var }
		ttk::scrollbar $toplevel.vs -command [list $scrolledFrame yview]
		ttk::scrollbar $toplevel.hs -command [list $scrolledFrame xview] -orient horizontal

		grid $scrolledFrame -row 0 -column 0 -sticky nsew
		#Don't show scrollbars on mobile devices
		grid $toplevel.vs -row 0 -column 100 -sticky ns
		grid $toplevel.hs -row 100 -column 0 -sticky ew
		grid rowconfigure $toplevel 0 -weight 1
		grid columnconfigure $toplevel 0 -weight 1
	}

	:method scrolledFrameToplevelBackground {  } {
		foreach {var}  {scrolledFrame f} { :upvar $var $var }
		$scrolledFrame configure -bg $::ttk::theme::cerulean::theme(bgcolor) 
		$f configure -bg $::ttk::theme::cerulean::theme(bgcolor) 
	}

	:method scrolledFrameToplevelCanvas {f} {
		grid [canvas $f.canvas  -bg  $::ttk::theme::cerulean::theme(bgcolor) \
			-xscrollincrement 1 -yscrollincrement 1 -width 10 -height 10  ] \
			-row 0 -column 0  -rowspan 100 -columnspan 100 -sticky news

		foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
		foreach {color1 color2}  { lightgreen orange } {} ;#electric violet

		canvas::gradient $f.canvas   -direction y  -color1  $color1 -color2 $color2 
	}

	:method scrolledFrameToplevelBindings {scrolledFrame} {
		bind [winfo toplevel $scrolledFrame] <<FingerDown>> [:callback motion start $scrolledFrame %W %x %y %s]
		bind [winfo toplevel $scrolledFrame] <<FingerMotion>> [:callback motion motion $scrolledFrame  %W %x %y %s]
		bind [winfo toplevel $scrolledFrame] <1> [:callback motion start $scrolledFrame  %W %X %Y %s]
		bind [winfo toplevel $scrolledFrame] <B1-Motion> [:callback motion motion $scrolledFrame  %W %X %Y %s]
		bind [winfo toplevel $scrolledFrame] <MouseWheel>       [list $scrolledFrame yview %W %D]
		bind [winfo toplevel $scrolledFrame] <Shift-MouseWheel> [list $scrolledFrame xview %W %D]
	}

	
	#Scrolling	
	:public method motion {mode path W X Y finger} {
		global movex
		global movey
		set ::motion 1
	#	puts "mode $mode path $path W $W  X $X Y $Y finger $finger"
		#  if {$finger != 1} {return}
		#  screenwidth and screenheight changed to width & height
		if {$mode eq "motion" && [winfo exists $path]  &&  [string match $path* $W] } {
			$path xview scroll [expr { ($movex - $X) * [winfo width .] / 10000 } ] units
			$path yview scroll [expr { ($movey - $Y) * [winfo height .] / 10000 } ] units
			set ::motion 0
		}
		set movex $X
		set movey $Y
		return
	}

	:public method tvSortBy {tv column {parent {}}} {
		set l [list]
		foreach item [$tv children $parent] {
			lappend l [list $item [$tv set $item $column]]
		}
		set o [list]
		foreach pair [lsort -dictionary -index 1 $l] {
			lappend o [lindex $pair 0]
		}
		$tv children $parent $o
	}



}
