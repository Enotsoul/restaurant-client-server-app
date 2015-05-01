#####################
# Aplicatia Clientului Pentru Restaurant
#####################
set ::VERSION 0.2.3

# 0. Includem pachetele necesare
foreach pkg {tls Tk nx} {
	package require $pkg
}
# 1. Interfata Grafica UI
proc LoginScreen {} {
	grid [ttk::labelframe .login -text "Login Screen" ] -column 0 -row 0 -sticky news 

	grid [ttk::label .login.lblUsername -text "Username:"] -column 1 -row 1 -sticky news  -in .login
	grid [ttk::label .login.lblPassword -text "Password:"] -column 1 -row 2 -sticky news  -in .login

	grid [ttk::entry .login.txtUsername -textvariable txtUsername  ] -column 2 -row 1 -sticky news  -in .login -columnspan 2
	grid [ttk::entry .login.txtPassword -show * -textvariable txtPassword  ] -column 2 -row 2 -sticky news  -in .login -columnspan 2
	grid [ttk::button .login.btnLogin -text "Autentificare!" -command [list Login]  ] -column 0 -row 7 -sticky news  -in .login -columnspan 3
}

	#Serverul trebuie sa ne transmita datele despre mese.. si noi desenam asta
proc DrawTableScreen {tablesData} {
	destroy .login
	set canvas_width 1000
	set canvas_height 600
	
	set start_x 10
	set start_y 10
	set width 200
	set height 100
	set spacing 30

	grid [canvas .table -bg  #eff2f3 -width $canvas_width -height $canvas_height]
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
		DrawAllProducts
		$::client getAllProducts
}
proc DrawProductScreen {tablesData} {
	destroy .table
	set canvas_width 1000
	set canvas_height 600
	
	set start_x 10
	set start_y 10
	set width 200
	set height 100
	set spacing 30

	grid [canvas .table -bg  #eff2f3 -width $canvas_width -height $canvas_height]
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
proc DrawAllProducts {} {

}

# 2. Functiile care lucreaza cu itnerfata grafica.. si fac conexiunea pt server
proc Login {} {
	#VERIFICARI, exista variabila
	#Nu e gol? Are minimum 3 caractere
	if {![info exists ::txtUsername] || ![info exists ::txtPassword]} {
		tk_messageBox -message "Completeaza Utilizatorul si Parola!"
		return
	}
	#TODO arata-i eroarea pe ecran nu cu messagebox..
	$::client AuthUser $::txtUsername $::txtPassword 

}

# 3. Functiile de conexiune/transmisie Date
nx::Class create ClientConnect {
	:property host
	:property port

	:variable server	
	
	:method init {  } {
		:Connect 
	}

	:method Connect {} {
		#Connect to server
		set :server [tls::socket ${:host} ${:port}]
		fconfigure ${:server} -buffering line -blocking 0
		fileevent ${:server} readable  [list [self] FromServer ${:server}]
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

vwait zambile
