nx::Class create ClientConnection {
	:property host
	:property port
	
	:variable server	
	:variable -accessor public currentTable
	
	:method init {  } {
	#	:Connect 
	}

	:public method Connect {} {
		#Connect to server
		set :server [tls::socket ${:host} ${:port}]
		fconfigure ${:server} -buffering line -blocking 0 -encoding utf-8
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
			ORDER { :OrderManagement $theRest }
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
				switch $nivel {
					1 { :getProducts }
					2 { :getTablesList }
					3 { :getAllOrdersForCook }
					default { :getTablesList }
				}
				#ospatar - mese
				#bucatar - comenzi
				#administrator - administrare
				#:getTablesList
			 }
		 }
	}

	:method TableManagement {msg} {
		set command [lindex $msg 0]
		set tables [lrange $msg 1 end]
		$::ui drawTableScreen $tables
	}

	:public method current {tableid} {
		set :currentTable $tableid
	}
	
	:method ProductManagement {msg} {
		set command [lindex $msg 0]
		set products [lrange $msg 1 end]
		$::ui drawProductScreen $products
	}

	:method OrderManagement {msg} {
		set command [lindex $msg 0]
		set data [lrange $msg 1 end]
		$::ui productOrderScreen $command $data

	}



	:method sendToServer {message} {
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
	
	:public method placeOrderAtTable {tableID orderInfo} {
		:sendToServer "ORDER NEW $tableID $orderInfo"
	}

	:public method getAllOrdersForCook {} {
		puts ${:server} "ORDER GETALLMYORDERS"
	}
	
}

