#!/usr/bin/env tclsh
#####################
# Server pentru aplicatia de restaurante
#####################
set ::VERSION 0.4
#Includem pachetele necesare
foreach pkg {tls sqlite3 sha1 nx nx::trait} { package require $pkg }

nx::Class create Server {
	:require trait nx::traits::callback
	
	:property port
	
	:variable Clients
	:variable Server

	:variable access "banned -1 inactive 0 client 1 waiter 2 cook 3 administrator 4 boss 5 superadmin 7"

	:variable Orders
	:variable inprocess_orders ""
	
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

	:public method getAccess {name} {
		return [dict get ${:access} [string tolower $name] ]
	}
	

	:public method AcceptConnection {sock address port} {
		puts "[getTimestamp] Accepted $sock from $address port $port"
		dict set :Clients $sock host $address
		dict set :Clients $sock port $port

		#Ensure each puts is sent through the network not blocking
		fconfigure $sock -buffering line -blocking 0 -encoding utf-8

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
			PRODUCT { :ProductManagement $sock $theRest }
			ORDER { :OrderManagement $sock $theRest }
			default { puts $sock "NIY Scuze, nu este inca implementat"  }
		}
	}

	:method AuthUser {sock msg} {
		set errors ""
		set email [lindex $msg 0]
		set password [lindex $msg 1]

		#View if email exists and if password is correct
		array set Client [list email "" password ""]
		DB eval {SELECT id,email,password,level FROM users WHERE email=$email OR username=$email} Client {}
		if {![string match -nocase $Client(email) $email]} {
			puts $sock "AUTH INEXISTENT"
			lappend errors "AUTH INEXISTENT"
		}

		if {![string match [::sha1::sha1 -hex $password] $Client(password)]} {
			#TODO block user for 10 minutes after 5 failed attempts
			puts $sock "AUTH WRONGPASSWORD"
			lappend errors "AUTH WRONGPASSWORD"
		}

		if {[string length $errors] == 0} {
			set email $Client(email)
			#TODO control if someone is already logged in with this email
			#If so, log him out and send him a logout message.
			dict set :Clients $sock email $email
			dict set :Clients $email sock $sock
			dict set :Clients $email level $Client(level)
			dict set :Clients $email id $Client(id)

			if {$Client(level) == [:getAccess COOK]} {
				dict set :inprocess_orders $email 0
				dict set :accepting_orders $email 1
			}
			
			#Control if level 0 (banned/inactive), disallow
			puts $sock "AUTH OK $Client(level)"
		}

		puts "[getTimestamp]: AUTH from $sock user $email  $errors"
		
	}

	:method verifyAuthenticated {sock} {
		if {[dict exists ${:Clients} $sock email]} {
			return  1
		} else { 
			puts $sock "AUTH REQUIRED"
			return  0
		}
	}

	:method verifyAccess {sock minAccess} {
		if {![:verifyAuthenticated $sock]} { return 0 }
		set email [dict get ${:Clients} $sock email]

		if {[dict get ${:Clients} $email level] < $minAccess} {
			puts $sock "ACCESS DENIED"
			return 0
		}

		return 1
	}

	:public method getUserId {sock } {
		set email [dict get ${:Clients} $sock email]
		return [dict get ${:Clients} $email id]
	}

	:method TableManagement {sock msg} {
		if {![:verifyAccess $sock  [:getAccess WAITER] ]} { return 0 }

		#LIST - Lists all tables
		#INFO <nr> - gives info about table number <nr>
				
		set mese [DB eval {SELECT * FROM tables}]
		puts $sock "TABLE LIST  $mese"
		puts "[getTimestamp]: TABLE $msg from $sock LIST: $mese "
		#Occupied : 0 =free, 1 =table selected /order in progress, 2=occupied

	}

	:method ProductManagement {sock msg} {
		if {![:verifyAccess $sock  [:getAccess WAITER] ]} { return 0 }
		set subcommand [lindex $msg 0]

		#LIST - Lists all products
		#INFO <nr> - gives info about product number <nr>
		switch -- $subcommand {
			LIST { 
				set products [DB eval {SELECT id,name,price,weight,image,stock FROM products}]
				puts $sock "PRODUCT LIST  $products"
			}
			INFO {
			
			}
		}
		puts "[getTimestamp]: PRODUCT $msg from $sock LIST: $products "
	}

	:method OrderManagement {sock msg} {
		if {![:verifyAccess $sock  [:getAccess WAITER] ]} { return 0 }
		set subcommand [lindex $msg 0]
		set theRest [lrange $msg 1 end]

		#NEW <tableID> <o]der_info>
		switch -- $subcommand {
			NEW { :placeNewOrder $sock $theRest 	}
			ACCEPT {
			#Waiter accepted order	
			}
			FINISHED {
			#ORDER IS FINISHED
			}
			GETALLMYORDERS {
				#Get all unassigned orders	
				:getAllOrdersForCook $sock $theRest
			}
			NOFULFILL {
				#Order has been rejected 
			}
		}

		puts "[getTimestamp]: ORDER $msg from $sock "

	}

	:method getAllOrdersFor {args} {
		#method body
	}

	#Get all unassigned orders, cancel timers and send to cook who just logged in
	:method getAllOrdersForCook {sock msg} {
		set email [dict get ${:Clients} $sock email]
		set cookID [dict get ${:Clients} $email id  ]
		set orders_list [DB eval {SELECT id,order_placed_at,
					(SELECT count(*) FROM order_products WHERE id=order_id) as products,status
						  FROM orders WHERE status=0 OR (status=1 AND cook_id=$cookID) 
					ORDER BY order_placed_at ASC}]

		puts $sock "ORDER YOURORDERS $orders_list"
		
		:sendOrderInformation  $orders_list 

	}

	:method sendOrderInformation { orders_list} {
		set email [dict get ${:Clients} $sock email]
		set inprocess [dict get ${:inprocess_orders} $email]

		foreach {orderID placed_date products status} $orders_list {
			set after [dict get ${:Orders} $orderID timer]
			after cancel $after

			incr inprocess	
			dict set :inprocess_orders $email $inprocess
			dict set :Orders $orderID time [clock seconds]
			set assign [expr {$status ? 0 : 1}]
			:assignOrderToCook -assign $assign  $email $orderID
		}
	}


	
	#order status  0 = just added, 1 = assigned to cook , 3  completed by cook, 4 paid
	:method placeNewOrder {sock msg} {
		set tableID [lindex $msg 0]
		set products [lindex $msg 1]
		set user_id [:getUserId $sock]
		set datePlaced [getTimestamp ]
		
		if {[llength $products] < 2} {
			puts $sock "ORDER INVALID Adauga un produs valid"
			return 0
		}

		:placeNewOrderInsertDB
		
		#INFORM WAITER ORDER HAS BEEN PLACED
		puts $sock "ORDER OK $orderID"
		dict set :Orders $orderID table_id $tableID
		dict set :Orders $orderID products $products
		dict set :Orders $orderID datePlaced $datePlaced
		:selectAvailableCookForOrder $orderID
	}

	:method placeNewOrderInsertDB {  } {
		foreach {var}  {tableID products orderID} { :upvar $var $var }

		puts "tableID $tableID PRODUCTS $products"
		set orderID	[DB eval {INSERT INTO orders (table_id,waiter_id,waiter_assigned_at,order_placed_at) VALUES ($tableID,$user_id,$date_placed,$date_placed) ;
						SELECT last_insert_rowid() FROM orders LIMIT 1}]
		foreach key [dict keys $products] {
			set quantity [dict get $products $key quantity]
			DB eval {INSERT INTO order_products (product_id,order_id,quantity) VALUES  ($key,$orderID,$quantity) }
			append data ($key,$orderID,$quantity),
		}
	}
	
	#Search for available cook and inform him of order!
	#TODO cook must accept within 60-70 seconds or it will be sent to another
	:public method selectAvailableCookForOrder { orderID {trial 0}} {
		foreach {email inprocess} [lsort -stride 2 -increasing -index 1 ${:inprocess_orders}] {
			if {![dict get ${:accepting_orders} $email]} { continue }
			incr inprocess
			dict set :inprocess_orders $email $inprocess
			dict set :Orders $orderID time [clock seconds]
			break
		}

		if {[info exists email]} {
			:assignOrderToCook $email $orderID
		} else {
		#If no cook available, add a timer to recheck in 60 seconds
			incr trial
			#TODO if trial > 5 view if there is a problem
			puts "No available cook found to take order $orderID next trial ($trial) in 60 seconds.."
			set after	[after [expr 60*1000] [:callback selectAvailableCookForOrder $orderID $trial ]]
			dict set :Orders $orderID "timer $after trial $trial"
		}
	}

	#Update cook & status
	:public method assignOrderToCook   {{-assign 1} email orderID} {

		set sock [dict get ${:Clients} $email sock]
		set date [getTimestamp ]

		#Select updated product data to send
		set productInfo [DB eval {SELECT id,name,price,weight,image,stock FROM products WHERE id IN
							(SELECT product_id from order_products where order_id =$orderID)}]
		set cookID [dict get ${:Clients} $email id  ]
		set datePlaced [dict get ${:Orders} $orderID datePlaced]
		if {$assign} {
			DB eval {UPDATE orders SET cook_id=$cookID,status=1,cook_assigned_at=$date WHERE id=$orderID}
		}
		set totalProducts [expr {[llength $productInfo]}/6]
		puts $sock "ORDER TAKE $orderID $products $productInfo $datePlaced $totalproducts"
	}
	

	#TODO if cookhas not accepted it, just assign it to another cook
	:public method reassignOrderToAnotherCook { orderID  } {
	

		puts $sock "ORDER INACTIVE $orderID"
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



