#####################
# Server pentru aplicatia de restaurante
#####################
set ::VERSION 0.3.1
#Includem pachetele necesare
foreach pkg {tls sqlite3 sha1 nx} { package require $pkg }

nx::Class create Server {
	:property port
	
	
	:variable Clients
	:variable Server

	
	
	:method init {} {
		sqlite3 DB [pwd]/../config/restaurantdb.db
		:Server
	}

	:method Server {} {
		set keyfile server.key
		set certfile server.pem

		 #If the certificate doesn't exist create it
		if {![file exists $keyfile]} {
			tls::misc req 1024 $keyfile $certfile [list CN "Server Restaurante United Brain Power" days 7300]
		}

		set :Server [::tls::socket -server [list [self] AcceptConnection]  -keyfile $keyfile -certfile $certfile ${:port} ]
		puts "[getTimestamp] Restaurant Server by United Brain POwer version $::VERSION Listening on port ${:port} "
		vwait forever

	}

	:public method AcceptConnection {sock address port} {
		puts "[getTimestamp] Accepted $sock from $address port $port"
		dict set :Clients $sock host $address
		dict set :Clients $sock port $port

		#Ensure each puts is sent through the network not blocking
		fconfigure $sock -buffering line -blocking 0 

		#set up callback when client sends data
		fileevent $sock readable [list [self] HandleClient $sock] 

		#Let the client know he's connected
		puts $sock "CONNECTED to Restaurant Server version $::VERSION"
	}

	#Check end of file or abnormal connection drop
	# then follow protocol
	:public method HandleClient {sock} {

		if {[eof $sock] || [catch {gets $sock line}]} {
			puts "Close $sock [dict get ${:Clients} $sock host]"
			close $sock
			#Logout user
		} else {
			:CommandSwitch $sock $line
		}
	}

	:method CommandSwitch {sock msg} {
		set command [lindex $msg 0]
		set theRest [lrange $msg 1 end]
		switch -- [lindex $msg 0] {
			AUTH { :AuthUser $sock $theRest   }
			TABLE { :TableManagement $sock $theRest }
			default { puts $sock "NIY Scuze, nu este inca implementat"  }
		}
	}

	:method AuthUser {sock msg} {
		set errors ""
		set username [lindex $msg 0]
		set password [lindex $msg 1]

		#View if username exists and if password is correct
		array set Client [list username "" password ""]
		DB eval {SELECT username,password,nivel FROM utilizatori WHERE username=$username} Client {}
		if {![string match -nocase $Client(username) $username]} {
			puts $sock "AUTH INEXISTENT"
			lappend errors "AUTH INEXISTENT"
		}

		if {![string match [::sha1::sha1 -hex $password] $Client(password)]} {
			#TODO block user for 10 minutes after 5 failed attempts
			puts $sock "AUTH WRONGPASSWORD"
			lappend errors "AUTH WRONGPASSWORD"
		}

		if {[string length $errors] == 0} {
			#TODO control if someone is already logged in with this username
			#If so, log him out and send him a logout message.
			dict set :Clients $sock username $username
			dict set :Clients $username sock $sock
			
			puts $sock "AUTH OK $Client(nivel)"
		}

		puts "[getTimestamp]: AUTH from $sock user $username  $errors"
		
	}

	:method TableManagement {sock msg} {
		#TODO VERIFY IF AUTHENTICATED!
		#VERIFY IF ACCESS (>= 2)
		
		#LIST - Lists all tables
		#INFO <nr> - gives info about table number <nr>
				
		set mese [DB eval {SELECT * FROM masa}]
		puts $sock "TABLE LIST  $mese"

		puts "[getTimestamp]: TABLE $msg from $sock LIST: $mese "

	}

}
proc generateCode {length {type 1}} {
	if {$type == 1} {
		set string "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789"
	} elseif {$type == 2} { set string AZERTYUIOPQSDFGHJKLMWXCVBN0123456789 
	} elseif {$type == 3} { set string azertyuiopqsdfghjklmwxcvbn0123456789 
	} elseif {$type == 4} { set string AZERTYUIOPQSDFGHJKLMWXCVBN } else {  set string 0123456789 }
	set code ""
	set stringlength [expr {[string length $string]-1}]
	for {set i 0} {$i<$length} {incr i} {
		append code [string index $string [rnd 0 $stringlength]]
	}
	return $code
}
proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}
proc getTimestamp {{unixtime ""}} {
	if {$unixtime == ""} { set unixtime [clock seconds] }
	return [clock format $unixtime -format "%Y-%m-%d %H:%M:%S"]
}

#Run Server!
set server [Server new -port 7737]



