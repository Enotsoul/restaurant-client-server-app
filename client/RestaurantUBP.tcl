#!/usr/bin/env tclsh
#####################
# Aplicatia Clientului Pentru Restaurant
#####################
set ::VERSION 0.2.3

# 0. Includem pachetele necesare
foreach pkg {tls Tk nx nx::trait Img canvas::gradient} {
	package require $pkg
}
foreach file {theme.tcl wordwrap.tcl Scrolledframe.tcl} {
	source $file
}
ttk::setTheme cerulean
#ttk::setTheme clam

#
#CREATE ICON IMAGE FOR DESKTOP
if {0} {
image create photo cool -file  ~/Projects/RestaurantApp/server/images/pepsi.jpg

 wm iconphoto .twind cool

}
nx::Class create RestaurantUI {
	:require trait nx::traits::callback

	:variable order ""

	:method init {  } {
		 #View device DPI and screen size
		 #Define FONTsize and image size
		 #Make fullscreen
		set :productSettings [dict create height 300 width 300]
		set :productInfo [dict create]
		#draw login screen
	#	:scrolledFrameExample
		:drawLoginScreen
		:loadSettings
	}
	:method drawLoginScreen {} {
	#	canvas .canvas	
	#	canvas::gradient .canvas  -direction y  -color1  #88c149  -color2 #699934 
	#	grid .canvas -columnspan 10 -rowspan 10 -column 0 -row 0
		grid [ttk::labelframe .login -text "Login Screen" -labelanchor n ] -column 0 -row 0 -sticky news  
		grid [ttk::label .login.lblinfo  -style Hide.TLabel ] -sticky news -columnspan 3
		grid [ttk::label .login.lblUsername -text "Username:"] -column 1 -row 3 -sticky news  -in .login
		grid [ttk::label .login.lblPassword -text "Password:"] -column 1 -row 4 -sticky news  -in .login

		grid [ttk::entry .login.txtUsername -textvariable [:bindvar txtUsername] -width 30 ] -column 2 -row 3 -sticky news  -in .login \
			-columnspan 2 -pady 3 -padx 3 
		grid [ttk::entry .login.txtPassword -show * -textvariable [:bindvar txtPassword] -width 30 ] -column 2 -row 4 -sticky news  -in .login \
			-columnspan 2 -pady 3 -padx 3 
		grid [ttk::checkbutton .login.btnRememberMe -variable [:bindvar rememberMe] -text "Remember me"  ] -column 2 -row 5 -sticky news  -in .login -columnspan 2
		ttk::button .login.btnLogin -style "Primary.TButton" -text "Autentificare!" -command [:callback login]  -compound center 
		grid .login.btnLogin -column 2 -row 7 -sticky news  -in .login -columnspan 1

		#	font create ProductItem -family {Ubuntu Mediuim} -size 16 -weight normal -slant roman
		.login.txtUsername configure -font  $::ttk::theme::cerulean::theme(entryfont) 
		.login.txtPassword configure -font  $::ttk::theme::cerulean::theme(entryfont) 

		#	wm attributes . -alpha 0.5 ;# $::ttk::theme::cerulean::theme(bgcolor) 
	}

	
	:public method login {} {
	#VERIFICARI, exista variabila
	#Nu e gol? Are minimum 3 caractere
	#TODO arata-i eroarea pe ecran nu cu messagebox..
		set errors ""
		if {![info exists :txtUsername] || ![info exists :txtPassword]} {
			set errors "Username and/or password must not be empty"
			return 0
		}
		if {[string length ${:txtUsername}] < 3 || [string length ${:txtPassword}] < 3 } {
			set message "Username and password must be at least 3 characters long"
			tk_messageBox -message $message 
			.login.lblinfo configure -text $message -style Danger.TLabel
			puts [.login.lblinfo configure -style]
			return
		}
		.login.lblinfo configure -text "" 	
		if {[info exists :rememberMe]} {
			if {${:rememberMe}} {
				set configFile config.db
				set file [open $configFile w]
				dict set dict username ${:txtUsername}
				dict set dict password ${:txtPassword}
				puts $file $dict
				close $file
			}
		}
		if	{[$::client Connect]} {
			$::client AuthUser ${:txtUsername} ${:txtPassword} 
		}

	}
	:public method loadSettings {args}  {
		set configFile config.db
		if {[file exists $configFile ]} {
			set file [open $configFile r]
			set :settings [read $file]
			close $file

			if {[dict exists ${:settings} password]} {
				set :txtUsername [dict get ${:settings} username]
				set :txtPassword [dict get ${:settings} password]
			}
		}
	}


	#Serverul trebuie sa ne transmita datele despre mese.. si noi desenam asta
	#TODO get screen size and draw based on that size!
	:public method DrawTableScreen {tablesData} {
		grid forget .login
		set canvas_width 1000
		set canvas_height 600

		set start_x 10
		set start_y 10
		set width 200
		set height 100
		set spacing 30

		##eff2f3 
		grid [canvas .table -bg #fbfcfc   -width $canvas_width -height $canvas_height]
		#bind .table <1> { onClick %x %y } ;#unfortenately binds all
		.table bind table <1>  [:callback  SelectTable %x %y ] 

		foreach {id persoane fumatori ocupat} $tablesData {
			if {$ocupat} { set color #c0392b	} else { set color #2ecc71  }
			set cid [.table create rectangle $start_x $start_y [expr {$start_x+$width}] [expr {$start_y+$height}] \
				-tags [list table table.$id] -fill $color -outline black]

				#Masa.id este id-ul mesei, salvam id-ul desenului pe canvas
			set ::Tables(masa.$id) $cid
			set ::Tables(canvasid.$cid) $id

			incr start_x [expr {$width+$spacing}]
			if {$start_x >= [expr {$canvas_width-$width}]} {
				set start_x 10
				incr start_y [expr {$height+$spacing}]
			}
		}
	}
	:public method SelectTable {x y} {
		set x [.table canvasx $x] ; set y [.table canvasy $y]
		set i [.table find closest $x $y]
		set t [.table gettags $i]
		puts "$i $t"

		#Select a table to either
		#1. place / update an order 
		#2. view order status (if already occupied)
		#3. view statistics
		set :currentTable $i
		$::client getProductList
	}
	
	proc writePdf {} {
		package require pdf4tcl
		pdf4tcl::new mypdf -paper a4
		mypdf canvas . 
		mypdf write -file products.pdf
		mypdf destroy
	}

	:public method DrawProductScreen {data} {
	#	wm geometry . 640x640
	#FORGET OR DESTROY?
		grid forget .table
		#	grid [ttk::labelframe .products -height 300 -yscrollcommand ".productScrollbar set" ] -row 1 -column 1
		grid [canvas .products  -bg  $::ttk::theme::cerulean::theme(bgcolor)  -width 10 -height 10 ] -row 1 -column 1  -sticky news
		foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds

		foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
		foreach {color1 color2}  { lightgreen orange } {} ;#electric violet
		canvas::gradient .products   -direction y  -color1  $color1 -color2 $color2 

		grid [ttk::scrollbar .productScrollbar -orient vertical -command ".products yview" ] -row 1 -column 10 -sticky ns -rowspan 10

		set ::productsData $data
		:showNextProductScreen 0
		puts "Products are $data"
		grid columnconfigure . { 1} -uniform 1 -weight 1
		grid rowconfigure . { 1} -uniform 1 -weight 1

	}

	#TODO CALCULATE NEXT LOCATION ON GRID BASED ON TOTAL COLUMNS/ROWS OF PRODUCTS
	:public method showNextProductScreen {productNr} {
		set maxProducts [:maxProductsToShow [dict get ${:productSettings} width] [dict get  ${:productSettings} height] ]
		set i 0
		set slaves  [grid slaves .products]
		set lastTime [:moveOldProductsFromScreen $slaves ]

		:drawProductsForNextScreen  
		set totalProducts [expr {[llength $::productsData]/6}]


		puts "i is $i totalProducts $totalProducts productNr $productNr"
		set prevNumber [expr {$productNr-$maxProducts}] 
		set previousState [expr {$prevNumber < 0 ? "disabled" : "normal"}]
		set nextState [expr {$i >= $totalProducts  ? "disabled" : "normal"}]

		after $lastTime [:callback btnPlaceOrderUpdate $column ]
		if {[winfo exists .products.btnNext]} {
			after $lastTime [list 	grid .products.btnPrevious  .products.separator ]
			after $lastTime [list grid .products.btnNext -column $column]
			.products.btnPrevious configure -state $previousState  -command [:callback showNextProductScreen $prevNumber ] 
			.products.btnNext configure -state $nextState -command [:callback showNextProductScreen $i] 
		} else {
			grid [ttk::separator .products.separator -orient horizontal ] -row 30 -sticky news -columnspan 10 
			grid [ttk::button .products.btnPrevious -text "< Previous" -state $previousState -command [:callback showNextProductScreen $prevNumber ] ] \
				-padx 5	-row 33 -column 1 -pady 5 -sticky [expr {$column==1 ? "w" : "n"}]
			grid [ttk::button .products.btnNext -text "Next >" -state $nextState -command [:callback showNextProductScreen $i] ]  \
				-padx 5 -row 33 -column $column -pady 5 -sticky [expr {$column==1 ? "e" : "n"}] 
		}
	}


	:public method btnPlaceOrderUpdate { column } {
		set widget .products.btnPlaceOrder 
		set items [llength [dict keys ${:order}]]

		set btnordercolumn [expr int(ceil($column/2.))]
		set btnordercolumnspan [expr {$column%2==0 ? 2 : 1}]

		set orderState [expr {$items  ? "normal" : "disabled"}]
	#	puts "Columns $column ordercolumn $btnordercolumn ordercolumnspan $btnordercolumnspan "
	#
		if {[winfo exists $widget ]} {
			grid $widget -column $btnordercolumn -columnspan $btnordercolumnspan
			$widget configure -state $orderState	-text "Finalize Order ($items)"
		} else {
			grid [ttk::button $widget -text "Finalize Order ($items)" -state $orderState \
				-style Success.TButton	-command [:callback PlaceOrder]] -row 1 -column $btnordercolumn -columnspan $btnordercolumnspan -pady 5
		}
	}
	

	:method moveOldProductsFromScreen {slaves} {
		set nextStartTime 100
		set lastTime 0
		set speedPerIteration 20
		set iterations 13 

		foreach slave [lreverse $slaves] {
			if {![string match *.lblProduct* $slave]} {  puts "to destroy $slave ?" ; grid remove $slave; continue  }; # destroy $slave;
			foreach var {x y width height} { set $var [winfo $var $slave] }
			grid forget $slave
			place $slave -x $x -y $y -width $width -height $height
			set currentPosition [expr $x+$width*1.1]

			for {set var 1} {$var <= $iterations} {incr var} {
				after [expr $nextStartTime*2+$var*$speedPerIteration] [list place configure $slave -x [expr {$x-$currentPosition/$iterations*$var}]   ]
			}

			after [expr $nextStartTime*2+$var*$speedPerIteration] [list destroy $slave ]
			set lastTime [expr $nextStartTime*2+$var*$speedPerIteration]
			incr nextStartTime 100
		}
		puts "time for products $lastTime"
		return $lastTime
	}
	
	:method drawProductsForNextScreen {} {
		foreach {var}  {productNr maxProducts i lastTime column row } { upvar $var $var }

		foreach {id name price weight img stock} $::productsData {
			if {$i < $productNr} { incr i ; continue }
			#dict merge :productInfo ${:productInfo} [dict create $id "name $name price $price weight $weight stock $stock img $img"]
			foreach var {id name price weight img stock} { dict set :productInfo $id $var [set $var] }

			set column [expr {$i%$::productsPerRow+1}]
			set row [expr {$i/$::productsPerRow+2}]

			set imgName product.$id
			:createProductImage $imgName $img medium	
			:createProductImage product_thumb_$id $img thumb	

			#If using ttk::label try to use -class ProductLabel and  bindtags
			## -wraplength [dict get ${:productSettings} width] 
			#For buttons we calculate length of info

			set correctWidth [:getCorrectWidth Primary.TLabel $imgName]
			set text [fmt $correctWidth "$name | $price RON"]

			set labelName .products.lblProduct$id 
			after $lastTime [list ttk::button $labelName  -compound top -width $correctWidth  \
				-text $text -image $imgName -style Primary.TLabel -command [:callback  SelectProduct $id ] ]

		#	after $lastTime [list ttk::label $labelName  -compound top -wraplength [dict get ${:productSettings} width]   \
				-text $text -image $imgName -style Primary.TLabel ]

			after $lastTime [list 	grid  $labelName -row $row -column $column   -padx 5 -pady 5 -sticky ns ] ;#-in .products 
		#	after $lastTime [list bind $labelName <ButtonRelease-1> [:callback  SelectProduct $id ] ]

			incr i
			if {$maxProducts <= [expr {abs($productNr-$i)}]} { puts "Showing $i products, exceeding $maxProducts stopping!" ; break }

		}

		set :currentColumns $column
	}

	#Calculate correct width based on the normal product width OR
	#on the actual image width if a image is specified! (useful to remove unwanted padding!)
 	:public method getCorrectWidth {{-width ""} style {image ""}} {
		if {$width == ""} {
			if {$image == ""} {
				set width [dict get ${:productSettings} width]
			} else {
				set width [image width $image]
			}
		}
			set font [ttk::style lookup $style -font]
			set testtext "1234567890-=qwertyuiop[]asdfghjkl;'\<zxcvbnm,./QWERTYUIOPASDFGHJKLZXCVBNM"
			set textlength [string length $testtext]
			set measurement [font measure $font $testtext]
			set wpc [expr {double($measurement)/$textlength}]

			set correctWidth [expr {int($width/$wpc)}]

			puts "For a width of $width the width per character is $wpc and the correctWidth is $correctWidth"
			return $correctWidth
}
	:public method VerifyButton {args} {
		#method body

	}
	

	:public method createProductImage {imgName img type} {
		if {![string match *$imgName* [image names]  ]} { 
			set img [image create photo $imgName -file "../server/images/${type}_$img"] 
		}
	}

#Calculate how many max products to show based on screen size
	:method maxProductsToShow {productWidth productHeight} {
		set width [winfo screenwidth .]
		set height [winfo screenheight .]
		puts "Screen width & height  $width x $height"
		set height 600
		set width 600

		set ::productsPerRow [expr {$width/$productWidth }]
		return [expr {($height*$width) / ($productWidth*$productHeight)}]

	}

	:public method SelectProduct {{-new 1} id} {
		set name  "Quantity for product [dict get ${:productInfo} $id name]"

		:generateDialog -grab 1 -dialog 1 .selectQuantity $name
		set stock [dict get ${:productInfo} $id stock] 
		
		set select "Add"
		if {!$new} { set select Update }
		set imgName product.$id
		set spinBox .selectQuantity.txtQuantity
	#	grid [ttk::labelframe .selectQuantity.frame -labelanchor n -text  $name] -columnspan 2
		grid [ttk::label .selectQuantity.lblQuantity -style H3.TLabel -text $name -wraplength 250 -anchor n -justify center] -row 1 -column 1 -columnspan 3 -padx 5 -pady 5 -sticky news

		grid [ttk::spinbox $spinBox   -from 1 -to $stock -increment 1 -width 3  ] -row 2 -column 1 -columnspan 3 
		grid [ttk::button .selectQuantity.btnSelectQuantity -text $select -style Success.TButton -command [:callback SelectQuantity $id] ] -row 10 -column 1 -pady 5 -sticky s -padx 3
		grid [ttk::button .selectQuantity.btnCancel -text "Cancel" -command [list destroy .selectQuantity] ] -row 10 -column 2 -pady 5 -sticky s -padx 3
		
		$spinBox set 1
		if {!$new} {
			$spinBox set [dict get ${:order} $id quantity]
			grid [ttk::button .selectQuantity.btnRemove -text "Remove" -style Danger.TButton \
				-command [:callback RemoveProductFromOrder $id] ] -row 10 -column 3 -pady 5 -sticky s -padx 3
		}

		$spinBox	 configure -font  $::ttk::theme::cerulean::theme(entryfont) 
	}


	
	

	:public method SelectQuantity {id} {
		set quantity [.selectQuantity.txtQuantity get ]
		dict set :order $id quantity  $quantity

		set treeview .placeorder.sf.scrolled.tvProducts
		if {[winfo exists $treeview ]} {
			 if {0} {
			set name [dict get ${:productInfo} $id name ]
			set price [dict get ${:productInfo} $id price ]
			set quantity  [dict get ${:order} $id quantity] 
			set subtotal [expr {$quantity*$price}]

			set text "$name   $quantity x $price = $subtotal"
			$treeview item product.$id -text $text
			# $treeview insert {} end -id product.$key  -text  $text -tags product
			# }
			:productsTreeViewInitCalculations
			:productsTreeViewAddOrUpdateItems -update 1
		}
		destroy .selectQuantity
		:btnPlaceOrderUpdate ${:currentColumns}
	}

 	:public method RemoveProductFromOrder {id} {
		dict unset :order $id
		set treeview .placeorder.sf.scrolled.tvProducts
		$treeview delete product.$id
		:productsTreeViewInitCalculations
		:productsTreeViewAddOrUpdateItems -update 1
		destroy .selectQuantity]
	}

	#Dialog for finishing order by customer/waiter/cook
	#Showing all ordered things
	#TODO make good dimensions..
	:public method PlaceOrder {} {
		set dialog .placeorder 
		set dialog [:scrolledFrameToplevel $dialog  "Place order"]
		 #Large screen
		 :PlaceOrderTreeView $dialog
		#Small Screen
	#	:PlaceOrderLabels $dialog
				
			tkwait visibility $dialog
	#	puts "DIALOG SIZE [wm geometry $dialog] [winfo width $dialog] [winfo height $dialog]"
#
	#	set treeview $dialog.tvProducts
		#foreach column {#0 price subtotal} {
		#	puts "$treeview column $column width [$treeview column $column -width ]"
		#}
	}

	#Treeview is used for larger screens
	:public method PlaceOrderTreeView {dialog} {
		set totalRows [llength [dict  keys ${:order}]]
		incr totalRows 1 

		set treeview $dialog.tvProducts

		:productsTreeViewInitCalculations

		ttk::treeview $treeview -columns $columns -height $totalRows -padding 0 ;#-yscrollcommand [list $dialog.vbar set]
		grid $treeview -row 0 -column 0 -sticky news -columnspan 5 
		grid columnconfigure $treeview 0 -weight 1
		grid rowconfigure $treeview 0 -weight 1

		:placeOrderTreeviewColumnSettings

		:productsTreeViewAddOrUpdateItems 

		:placeOrderTreeviewEndConfiguration
	}

	:public method productsTreeViewInitCalculations {} {
		foreach {var}  {maxWidth columns nameWidth otherWidth nameColumnWidth charsPerLine } { upvar $var $var }
		set maxWidth 240

		set columns {price quantity subtotal}
		set nr [llength $columns]	
		incr nr 2

		set nameWidth [expr int($maxWidth/$nr*1.5)]
		set otherWidth [expr int($maxWidth/$nr)]
		set nameColumnWidth $otherWidth

		if {$maxWidth < 300} {
			set nameColumnWidth [expr int($maxWidth*0.9)]
			set nameWidth [expr int($maxWidth*0.99)]
			set columns ""
		}
		set charsPerLine [:getCorrectWidth -width $nameColumnWidth Primary.TLabel]
		puts "nameWidth $nameWidth otherWidth $otherWidth"
	}

	:method placeOrderTreeviewColumnSettings {} {
		foreach {var}  {columns treeview otherWidth nameWidth } { upvar $var $var }
		foreach {column} $columns {
			$treeview heading $column -text [string totitle $column] -anchor center
			$treeview column $column -width $otherWidth -stretch 1
		}
		$treeview heading #0 -text "Products"
		
		$treeview column #0 -anchor w -width $nameWidth -stretch 1
	}

	:public method productsTreeViewAddOrUpdateItems {{-update 0}} {
		foreach {var}  {treeview maxWidth charsPerLine} { upvar $var $var }
		#TODO group by type
		set orderedItems [dict  keys ${:order}]
		set total 0
		foreach key $orderedItems {
			set values ""
			foreach {var} {name price} { set $var [dict get ${:productInfo} $key $var] } 
			set quantity  [dict get ${:order} $key quantity] 
			set subtotal [expr {$price*$quantity}]

				
			set text [fmt $charsPerLine  "$name   $quantity x $price = $subtotal"]
			if {!$update} {
				$treeview insert {} end -id product.$key  -text  $text -tags product
			} else {
				$treeview item product.$key -text $text -tags product
			}
			#	lappend values   $price  $quantity $subtotal
			#	$treeview insert {} end -id product.$key -tags product  -text $name -values $values  {*}[expr {$maxWidth <300 ? "" : "-image product_thumb_$key "}]
			
			set total [expr {$total+$subtotal}]
		}

		:productTreeViewTotal $total
	}

	:method productTreeViewTotal {total} {
		foreach {var}  {treeview maxWidth update} { upvar $var $var }
		if {$update} {
			$treeview item total -text 	"Total: $total "
		} else {
			$treeview insert {} end -id total -tags total -text "Total: $total "
		}
		#	$treeview insert {} end -id total -tags total -text "" -values " - -  Total: $total  "
	}

	:method placeOrderTreeviewEndConfiguration {args} {
		foreach {var}  {treeview dialog} { upvar $var $var }

		$treeview tag bind product <ButtonRelease> [:callback changeProductOrder $treeview  %x %y]
		$treeview tag  configure total -font $::ttk::theme::cerulean::theme(h3font) \
			-background #b5191f  -foreground $::ttk::theme::cerulean::theme(bgcolor) 
	
		grid [ttk::button $dialog.btnPlaceOrder -text "Place Order" -style Success.TButton] -row 15 -column 0 -padx 3 -pady 3 -sticky s
		#When selecting a treeview item allow to modify total and/or delete!
		#grid [ttk::button $dialog.btnDeleteSelected -text "Delete Selected" -style Danger.TButton] -row 15 -column 2 -padx 3
		grid [ttk::button $dialog.btnCancel -text "Cancel" -command [list destroy [winfo toplevel $dialog] ]] -row 15 -column 1 -padx 3 -pady 3 -sticky s

		set height 50
		ttk::style configure Height.Treeview -rowheight $height
		$treeview configure -style Height.Treeview
	}


	:public method changeProductOrder {treeview x y} {
		set selection [$treeview selection]
		set item [$treeview identify item $x $y]
		#We're interested if the current item under the finger/mouse is the same as the selection!
		#Then it means the user didn't just swype, so we can change info of product
		if {$selection == $item} {
			puts "Selection $selection item at x,y $x,$y is $item"
			set id [lindex [split $selection .] 1]
			:SelectProduct -new 0 $id
		}
	}


	#Labels are used for screens with smaller size (ie, mobile phones) 
	:public method PlaceOrderLabels {} {
		#method body
		set orderedItems [dict  keys ${:order}]
		set total 0
		set row 1
		foreach key $orderedItems {
			set values ""
			foreach {var} {name price} { set $var [fmt 20 [dict get ${:productInfo} $key $var]] } 
			set quantity  [dict get ${:order} $key quantity] 
			set subtotal [expr {$price*$quantity}]
			lappend values  $name $price  $quantity $subtotal
			$treeview insert {} end -id product.$key  -image product_thumb_$key  -values $values
			
			set total [expr {$total+$subtotal}]

			incr row
			grid [ttk::label $dialog.lblProductInfo$key  -image product_thumb_$key -compound bottom -style Primary.TLabel -text "$name "] -row $row -column 0 -sticky news
			grid [ttk::label $dialog.lblProductPrice$key  -style Primary.TLabel -text " $price x $quantity = $subtotal "  -anchor e] -row $row -column 1 -sticky news

		}

		grid [ttk::label $dialog.lblProducttotal -style H2.TLabel -text "Total: $total"  -anchor e] -sticky news -columnspan 2

	}
	
	
	:public method motion {mode path W X Y finger} {
		global movex
		global movey
		set ::motion 1
		puts "mode $mode path $path W $W  X $X Y $Y finger $finger"
		#  if {$finger != 1} {return}
		if {$mode eq "motion" && [winfo exists $path]  &&  [string match $path* $W] } {
			$path xview scroll [expr { ($movex - $X) * [winfo screenwidth .] / 10000 } ] units
			$path yview scroll [expr { ($movey - $Y) * [winfo screenheight .] / 10000 } ] units
			set ::motion 0
		}
		set movex $X
		set movey $Y
		return
	}

	:public method scrolledFrameToplevel {args} {

		namespace import ::scrolledframe::scrolledframe
		set toplevel [:generateDialog {*}$args]
		set scrolledFrame $toplevel.sf
		scrolledframe $scrolledFrame -height 400 -width 240 \
			-xscroll [list $toplevel.hs set] -yscroll [list $toplevel.vs set]
		ttk::scrollbar $toplevel.vs -command [list $scrolledFrame yview]
		ttk::scrollbar $toplevel.hs -command [list $scrolledFrame xview] -orient horizontal
		grid $scrolledFrame -row 0 -column 0 -sticky nsew
		grid $toplevel.vs -row 0 -column 100 -sticky ns
		grid $toplevel.hs -row 100 -column 0 -sticky ew
		grid rowconfigure . 0 -weight 1
		grid columnconfigure . 0 -weight 1
		set f $scrolledFrame.scrolled
		$scrolledFrame configure -bg $::ttk::theme::cerulean::theme(bgcolor) 
		$f configure -bg $::ttk::theme::cerulean::theme(bgcolor) 

		grid [canvas $f.canvas  -bg  $::ttk::theme::cerulean::theme(bgcolor) \
			-xscrollincrement 1 -yscrollincrement 1 -width 10 -height 10  ] \
			-row 0 -column 0  -rowspan 100 -columnspan 100 -sticky news
		foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds

		foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
		foreach {color1 color2}  { lightgreen orange } {} ;#electric violet
		canvas::gradient $f.canvas   -direction y  -color1  $color1 -color2 $color2 

		bind [winfo toplevel $scrolledFrame] <<FingerDown>> [:callback motion start $scrolledFrame %W %x %y %s]
		bind [winfo toplevel $scrolledFrame] <<FingerMotion>> [:callback motion motion $scrolledFrame  %W %x %y %s]
		bind [winfo toplevel $scrolledFrame] <1> [:callback motion start $scrolledFrame  %W %X %Y %s]
		bind [winfo toplevel $scrolledFrame] <B1-Motion> [:callback motion motion $scrolledFrame  %W %X %Y %s]
		bind [winfo toplevel $scrolledFrame] <MouseWheel>       [list $scrolledFrame yview %W %D]
		bind [winfo toplevel $scrolledFrame] <Shift-MouseWheel> [list $scrolledFrame xview %W %D]
		return $f
		return $scrolledFrame 

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
		:centerWindowBasedOn $name . 

		#Grab makes selected window active, 
		#to avoid error we need to tkwait for the visibility of the window
		if {$grab} {
			tkwait visibility $name
			grab set $name
		}
		return $name
	}
	
	#Center childwindow based on the parentwindow x,y and width/height location
	#TODO get width/height of current window in calculation
	:public method centerWindowBasedOn { childWindow parentWindow} {
		set x [winfo x $parentWindow]
		set y [winfo y $parentWindow]
		set width [winfo width $parentWindow]
		set height [winfo height $parentWindow]
		set x [expr {int($x+$width*0.3)}]
		set y [expr {int($y+$height*0.3)}]
		wm geometry $childWindow  +$x+$y
	}

	:public method scrolledFrameExample {args} {

		namespace import ::scrolledframe::scrolledframe
		scrolledframe .sf -height 400 -width 240 \
			-xscroll {.hs set} -yscroll {.vs set}
		ttk::scrollbar .vs -command {.sf yview}
		ttk::scrollbar .hs -command {.sf xview} -orient horizontal
		grid .sf -row 0 -column 0 -sticky nsew
		grid .vs -row 0 -column 1 -sticky ns
		grid .hs -row 1 -column 0 -sticky ew
		grid rowconfigure . 0 -weight 1
		grid columnconfigure . 0 -weight 1
		set f .sf.scrolled

		grid [canvas $f.products  -bg  $::ttk::theme::cerulean::theme(bgcolor)  -xscrollincrement 1 -yscrollincrement 1 -width 10 -height 10  ] -row 0 -column 0  -rowspan 100 -columnspan 100 -sticky news
		foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds

		foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
		foreach {color1 color2}  { lightgreen orange } {} ;#electric violet
		canvas::gradient $f.products   -direction y  -color1  $color1 -color2 $color2 


		foreach i { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20} \
			{ 
				ttk::label $f.l$i -text "Hi! I'm the scrolled label $i" -relief groove
				ttk::button $f.b$i -text "Click me $i" -command [list tk_messageBox -message "Hello from Button $i"] 
				grid $f.l$i -row $i -column 0 -padx 2 -pady 2
				grid $f.b$i -row $i -column 1 -padx 2 -pady 2

				bind $f.l$i <ButtonRelease-1> {
					if {!$::motion} {
						tk_messageBox -message "Selected label  YO"
					}
				}
		}

		foreach {f fs} {  . .sf  } {
			bind $f <<FingerDown>> [:callback motion start $fs %W %x %y %s]
			bind $f <<FingerMotion>> [:callback motion motion $fs %W %x %y %s]
			bind $f <ButtonPress-1> [:callback motion start $fs %W %X %Y %s]
			bind $f <B1-Motion> [:callback motion motion $fs %W %X %Y %s]
			bind [winfo toplevel $fs] <MouseWheel>       [list .sf yview %W %D]
			bind [winfo toplevel $fs] <Shift-MouseWheel> [list .sf xview %W %D]
		}
	}
if {0} {
#TEXT thing stuff!
	grid [text .products  -yscrollcommand ".productScrollbar set" ] -row 1 -column 1
.products window create end -create [list ttk::label .products.lblProduct$id -compound top -wraplength 300  \
			-text $text -image $imgName -style Primary.TLabel]
#Canvas stuf
#	set canvas_width 300
	set canvas_height 700
	
#	set start_x 10
	set start_y 10
	set width 300
	set height 200
	set spacing 20
	set textSpacing 5

	set canvas .products
grid [canvas $canvas  -bg  $::ttk::theme::cerulean::theme(bgcolor)  -xscrollincrement 1 -yscrollincrement 1 \
		-width $canvas_width -height $canvas_height] -row 1 -column 1 -columnspan 5 -rowspan 10
#bind $canvas <<FingerDown>> [list +motion start $canvas %W %x %y %s]
bind $canvas <<FingerMotion>> [list +motion motion $canvas %W %x %y %s]
bind $canvas <2> "$canvas scan mark %x %y"
bind $canvas <B2-Motion> "$canvas scan dragto %x %y"

	.products bind product <1> { SelectProduct %x %y  }

	#foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet

	#foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds
#	foreach {color1 color2}  {   #ED4264  #FFEDBC } { } ;#pink orange
	canvas::gradient .products   -direction y  -color1  $color1 -color2 $color2 

		set cid [.products create rectangle $start_x $start_y [expr {$start_x+$width}] [expr {$start_y+$height}] \
			-tags [list product product.$id] -outline "" ] ;# -fill $color -outline black]

		
		if {$imgheight >= 150} {
			set product_x [expr {$start_x+$imgwidth+$textSpacing }]
			set product_y [expr {$start_y+($imgheight)/4+$textSpacing}]
		} else {
			set product_x [expr {$start_x +$textSpacing }]
			set product_y [expr {$start_y+$imgheight+$textSpacing}]

		}

		set imgwidth [image width $imgName]; set imgheight [image height $imgName] 
		.products create text $product_x $product_y     \
			-fill black -activefill red \
			-anchor nw  -font ProductItem -text $text 
		#$cid -image $imgName
		#Masa.id este id-ul mesei, salvam id-ul desenului pe canvas
		set ::Products(product.$id) $cid
		set ::Products(canvasid.$cid) $id

		incr start_x [expr {$width+$spacing}]
		if {$start_x >= [expr {$canvas_width-$width}]} {
			set start_x 10
			incr start_y [expr {$height+$spacing}]
		}



	.products configure -scrollregion [.products bbox all]
}





}
# 3. Functiile de conexiune/transmisie Date
nx::Class create ClientConnect {
	:property host
	:property port

	:variable server	
	
	:method init {  } {
	#	:Connect 
	}

	:public method Connect {} {
		#Connect to server
		set :server [tls::socket ${:host} ${:port}]
		fconfigure ${:server} -buffering line -blocking 0
		fileevent ${:server} readable  [list [self] FromServer ${:server}]

		#Return 0 if anything bad happens
		return 1
		#Send msg saying auth
		#	puts $server "CONNECT"
	}

	:public method FromServer {sock} {
		if {[eof $sock] || [catch {gets $sock line}]} {
			#TODO GUI informing client!
			puts "Server just quit!"
			close $sock
		} else {
			:CommandSwitch  $sock $line
		}
	}


	:method CommandSwitch {sock msg} {
		set command [lindex $msg 0]
		set theRest [lrange $msg 1 end]
		switch -- [lindex $msg 0] {
			AUTH { 
				#Verificam ce fel de autentificare este
				:AuthType $theRest
			}
			CONNECTED { 
				#Conectat la server.. putem arata interfata pt autentificare
				puts "CONNECTED: $theRest"
			}
			TABLE { :TableManagement $theRest  }
			PRODUCT { :ProductManagement $theRest }
			default { puts "Comanda $command :nu este cunoscuta (extra details: $theRest)"  }
		}
	}

	:method AuthType {msg} {
		set command [lindex $msg 0] 
		switch -- $command { 
			INEXISTENT { puts "SERVER: User-ul este inexistent"   }
			WRONGPASSWORD { puts "SERVER: parola este incorecta." }
			OK  {  
				set nivel [lindex $msg 1]
				puts "SERVER: Autentificare cu succes, ai nivelul $nivel"
				#STARTSCREEN 
				#ospatar - mese
				#bucatar - comenzi
				#administrator - administrare
				:getTablesList
			 }
		 }
	}

	:method TableManagement {msg} {
		set command [lindex $msg 0]
		set tables [lrange $msg 1 end]
		$::ui DrawTableScreen $tables
	}

	:method ProductManagement {msg} {
		set command [lindex $msg 0]
		set products [lrange $msg 1 end]
		$::ui DrawProductScreen $products
	}



	:public method SendToServer {message} {
		puts ${:server} $message
	}
	
	:public method AuthUser {username password} {
		puts ${:server} "AUTH  $username $password"
		puts "Am trimis serverului ca ne logam.. "
	}

	:public method getTablesList {args} {
		puts ${:server} "TABLE LIST"
	}

	:public method getProductList {} {
		puts ${:server} "PRODUCT LIST"
	}
	
}
######################## 
# Starting Up!
######################## 

set client [ClientConnect new -port 7737 -host localhost]
set ui [RestaurantUI new]

if {0} {

Large 500x500 
Medium 300x300
Small 100x100
Thumbnail 75x75
Tiny 32x32
	
foreach image {mamaliga papanasi cola pepsi pizza ciorba salatafructe soup} {
catch {
exec convert  $image.jpg  -quality 90 -write mpr:img  \( mpr:img -thumbnail 500x500 -write large_$image.jpg \) 
\( mpr:img -thumbnail 300x300 -write medium_$image.jpg \)  \( mpr:img -thumbnail 150x150 -write small_$image.jpg \) 
\( mpr:img -thumbnail 100x100 -write thumb_$image.jpg  \)
}
}
}
wm protocol . WM_DELETE_WINDOW {
    if {[tk_messageBox -message "Are you sure you want to quit?" -type yesno] eq "yes"} {
       exit
    }
}

vwait zambile
