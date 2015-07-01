#!/usr/bin/env tclsh
#####################
# Aplicatia Clientului Pentru Restaurant
#####################
set ::VERSION 0.2.3

# 0. Includem pachetele necesare
foreach pkg {tls Tk nx Img canvas::gradient} {
	package require $pkg
}
source theme.tcl
ttk::setTheme cerulean
#ttk::setTheme clam
#
#CREATE ICON IMAGE FOR DESKTOP
if {0} {
image create photo cool -file  ~/Projects/RestaurantApp/server/images/pepsi.jpg

 wm iconphoto .twind cool

}
proc LoginScreen {} {
#	canvas .canvas	
#	canvas::gradient .canvas  -direction y  -color1  #88c149  -color2 #699934 
#	grid .canvas -columnspan 10 -rowspan 10 -column 0 -row 0
	grid [ttk::labelframe .login -text "Login Screen" -labelanchor n ] -column 0 -row 0 -sticky news  
	grid [ttk::label .login.lblinfo  -style Hide.TLabel ] -sticky news -columnspan 3
	grid [ttk::label .login.lblUsername -text "Username:"] -column 1 -row 3 -sticky news  -in .login
	grid [ttk::label .login.lblPassword -text "Password:"] -column 1 -row 4 -sticky news  -in .login

	grid [ttk::entry .login.txtUsername -textvariable txtUsername -width 30 ] -column 2 -row 3 -sticky news  -in .login \
		-columnspan 2 -pady 3 -padx 3 
	grid [ttk::entry .login.txtPassword -show * -textvariable txtPassword -width 30 ] -column 2 -row 4 -sticky news  -in .login \
		-columnspan 2 -pady 3 -padx 3 
	grid [ttk::checkbutton .login.btnRememberMe -variable rememberMe -text "Remember me"  ] -column 2 -row 5 -sticky news  -in .login -columnspan 2
	 ttk::button .login.btnLogin -style "Primary.TButton" -text "Autentificare!" -command [list Login]  -compound center 
	grid .login.btnLogin -column 2 -row 7 -sticky news  -in .login -columnspan 1

#	font create ProductItem -family {Ubuntu Mediuim} -size 16 -weight normal -slant roman
	.login.txtUsername configure -font  $::ttk::theme::cerulean::theme(entryfont) 
	.login.txtPassword configure -font  $::ttk::theme::cerulean::theme(entryfont) 
	
#	wm attributes . -alpha 0.5 ;# $::ttk::theme::cerulean::theme(bgcolor) 
}

	#Serverul trebuie sa ne transmita datele despre mese.. si noi desenam asta
	#TODO get screen size and draw based on that size!
proc DrawTableScreen {tablesData} {
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
	.table bind table <1> { SelectTable %x %y  }

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
proc SelectTable {x y} {
        set x [.table canvasx $x] ; set y [.table canvasy $y]
        set i [.table find closest $x $y]
        set t [.table gettags $i]
        puts "$i $t"

		#Select a table to either
		#1. place / update an order 
		#2. view order status (if already occupied)
		#3. view statistics
		$::client getProductList
}
proc writePdf {} {
	package require pdf4tcl
	pdf4tcl::new mypdf -paper a4
  mypdf canvas . 
  mypdf write -file products.pdf
  mypdf destroy
}
proc DrawProductScreen {data} {
#	wm geometry . 640x640
	#FORGET OR DESTROY?
	grid forget .table
#	grid [ttk::labelframe .products -height 300 -yscrollcommand ".productScrollbar set" ] -row 1 -column 1
	grid [canvas .products  -bg  $::ttk::theme::cerulean::theme(bgcolor)  ] -row 1 -column 1 -columnspan 5 -rowspan 10 -sticky news
	foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds

	foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
	foreach {color1 color2}  { lightgreen orange } {} ;#electric violet
	canvas::gradient .products   -direction y  -color1  $color1 -color2 $color2 

	grid [ttk::scrollbar .productScrollbar -orient vertical -command ".products yview" ] -row 1 -column 10 -sticky ns -rowspan 10
	
	set ::productsData $data
	showNextProductScreen 0
	puts "Products are $data"

}

#TODO CALCULATE NEXT LOCATION ON GRID BASED ON TOTAL COLUMNS/ROWS OF PRODUCTS
proc showNextProductScreen {productNr} {
	set maxProducts [maxProductsToShow 300 300]
	set i 0
	set slaves  [grid slaves .products]
	set lastTime [moveOldProductsFromScreen $slaves ]

	#if {$slaves != ""} { return  }	

	drawProductsForNextScreen  
	set totalProducts [expr {[llength $::productsData]/6}]


	puts "i is $i totalProducts $totalProducts productNr $productNr"
	set prevNumber [expr {$productNr-$maxProducts}] 
	set previousState [expr {$prevNumber < 0 ? "disabled" : "normal"}]
	set nextState [expr {$i >= $totalProducts  ? "disabled" : "normal"}]
	if {[winfo exists .products.btnNext]} {
		after $lastTime [list 	grid .products.btnPrevious .products.btnNext .products.separator ]
		.products.btnPrevious configure -state $previousState  -command [list showNextProductScreen $prevNumber ] 
		.products.btnNext configure -state $nextState -command [list showNextProductScreen $i] 
	} else {
		grid [ttk::separator .products.separator -orient horizontal ] -row 30 -sticky news -columnspan 10 
		grid [ttk::button .products.btnPrevious -text "< Previous" -state $previousState -command [list showNextProductScreen $prevNumber ] ] -row 33 -column 1 -pady 5
		grid [ttk::button .products.btnNext -text "Next >" -state $nextState -command [list showNextProductScreen $i] ] -row 33 -column 2 -pady 5
	}
	
}
proc moveOldProductsFromScreen {slaves} {
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
proc drawProductsForNextScreen {} {
	foreach {var}  {productNr maxProducts i lastTime } { upvar $var $var }

	puts "Current Product Nr $productNr and $i"
	foreach {id denumire pret grame img stock} $::productsData {
		if {$i < $productNr} { incr i ; continue }

		set column [expr {$i%$::productsPerRow+1}]
		set row [expr {$i/$::productsPerRow+2}]

		set imgName product.$id
		createProductImage $imgName $img small	
			
		set text "$denumire | $pret RON"

		after $lastTime [list ttk::label .products.lblProduct$id -compound top -wraplength 200  \
			-text $text -image $imgName -style Primary.TLabel]
		after $lastTime [list 	grid  .products.lblProduct$id  -row $row -column $column   -padx 5 -pady 5 -sticky ns ] ;#-in .products 

		incr i
		if {$maxProducts <= [expr {abs($productNr-$i)}]} { puts "Showing $i products, exceeding $maxProducts stopping!" ; break }
	}
}

proc createProductImage {imgName img type} {
	if {![string match *$imgName* [image names]  ]} { 
		set img [image create photo $imgName -file "../server/images/${type}_$img"] 
	}
}

#Calculate how many max products to show based on screen size
proc maxProductsToShow {productWidth productHeight} {
	set width [winfo screenwidth .]
	set height [winfo screenheight .]
	puts "Screen width & height  $width x $height"
	set height 600
	set width 900

	set ::productsPerRow [expr {$width/$productWidth }]
	return [expr {($height*$width) / ($productWidth*$productHeight)}]

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


proc motion {mode path W X Y finger} {
        global movex
        global movey
        if {$finger != 1} {return}
        if {$mode eq "motion" && [winfo exists $path]  &&  [string match $path* $W] } {
                $path xview scroll [expr { ($movex - $X) * [winfo screenwidth .] / 10000 } ] units
                $path yview scroll [expr { ($movey - $Y) * [winfo screenheight .] / 10000 } ] units
        }
        set movex $X
        set movey $Y
        return
}

proc SelectProduct {x y} {
        set x [.products canvasx $x] ; set y [.products canvasy $y]
        set i [.products find closest $x $y]
        set t [.products gettags $i]
        puts "$i $t"
		
		#Select product.. view it larger & have possibility to order

	#	$::client getProductList
}
proc DrawAllProducts {} {

}

# 2. Functiile care lucreaza cu itnerfata grafica.. si fac conexiunea pt server
proc Login {} {
	#VERIFICARI, exista variabila
	#Nu e gol? Are minimum 3 caractere
	#TODO arata-i eroarea pe ecran nu cu messagebox..
	set errors ""
	if {![info exists ::txtUsername] || ![info exists ::txtPassword]} {
		set errors "Username and/or password must not be empty"
		return 0
	}
	if {[string length $::txtUsername] < 3 || [string length $::txtPassword] < 3 } {
			set message "Username and password must be at least 3 characters long"
			tk_messageBox -message $message 
			.login.lblinfo configure -text $message -style Danger.TLabel
			puts [.login.lblinfo configure -style]
			return
	}
	.login.lblinfo configure -text "" 	
	if {[info exists ::rememberMe]} {
		if {$::rememberMe} {
			set configFile config.db
			set file [open $configFile w]
			dict set dict username $::txtUsername
			dict set dict password $::txtPassword
			puts $file $dict
			close $file
		}
	}
	if	{[$::client Connect]} {
		$::client AuthUser $::txtUsername $::txtPassword 
	}

}
proc LoadSettings {} {
	set configFile config.db
	if {[file exists $configFile ]} {
		set file [open $configFile r]
		set ::settings [read $file]
		close $file

		if {[dict exists $::settings password]} {
			set ::txtUsername [dict get $::settings username]
			set ::txtPassword [dict get $::settings password]
		}
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
			default { puts "Comanda $command : $theRest nu este cunoscuta"  }
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
		DrawTableScreen $tables
	}

	:method ProductManagement {msg} {
		set command [lindex $msg 0]
		set products [lrange $msg 1 end]
		DrawProductScreen $products
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
# 4. Incepem
#
set client [ClientConnect new -port 7737 -host localhost]
LoginScreen
LoadSettings 

if {0} {


	
foreach image {mamaliga papanasi cola pepsi pizza ciorba salatafructe soup} {
catch {
exec convert  $image.jpg  -quality 90 -write mpr:img  \( mpr:img -thumbnail 500x500 -write large_$image.jpg \)  \( mpr:img -thumbnail 300x300 -write medium_$image.jpg \)  \( mpr:img -thumbnail 150x150 -write small_$image.jpg \) \( mpr:img -thumbnail 100x100 -write thumb_$image.jpg  \)
}
}
}
wm protocol . WM_DELETE_WINDOW {
    if {[tk_messageBox -message "Are you sure you want to quit?" -type yesno] eq "yes"} {
       exit
    }
}

vwait zambile
