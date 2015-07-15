nx::Class create ProductManagementUI -mixins [list UIFunctions  ]  {

	:require trait nx::traits::callback

	:variable order ""

	:method init {} {
		set :productSettings [dict create height 300 width 300]
		set :productInfo [dict create]
	}

	:public method drawProductScreen {data} {
	#	wm geometry . 640x640
	#FORGET OR DESTROY?
		destroy .table
		#	grid [ttk::labelframe .products -height 300 -yscrollcommand ".productScrollbar set" ] -row 1 -column 1
		grid [canvas .products  -bg  $::ttk::theme::cerulean::theme(bgcolor)  -width 10 -height 10 ] -row 1 -column 1  -sticky news
		foreach {color1 color2}  { #ECE9E6 #FFFFFF } {} ;#clouds

		foreach {color1 color2}  {#7474BF  #348AC7 } {} ;#electric violet
		foreach {color1 color2}  { lightgreen orange } {} ;#electric violet
		canvas::gradient .products   -direction y  -color1  $color1 -color2 $color2 

		grid [ttk::scrollbar .products.productScrollbar -orient vertical -command ".products yview" ] -row 1 -column 10 -sticky ns -rowspan 10

		set ::productsData $data
		:showNextProductScreen 0
		#puts "Products are $data"
		grid columnconfigure . { 1} -uniform 1 -weight 1
		grid rowconfigure . { 1} -uniform 1 -weight 1

	}

	##TODO if using thumb small image, when clicking on next screen locks!
	:public method showNextProductScreen {productNr} {
		#puts "show next product screen $productNr"
		set maxProducts [:maxProductsToShow [dict get ${:productSettings} width] [dict get  ${:productSettings} height] ]
		set i 0
		set slaves  [grid slaves .products]
		set lastTime [:moveOldProductsFromScreen $slaves ]

		:drawProductsForNextScreen  

		after $lastTime [:callback btnPlaceOrderUpdate $column ]
		:productScreenButtons
	}


	:method moveOldProductsFromScreen {slaves} {
		set nextStartTime 100
		set lastTime 0
		set speedPerIteration 20
		set iterations 13 

		foreach slave [lreverse $slaves] {
			if {![string match *.lblProduct* $slave]} {   grid remove $slave; continue  }; # destroy $slave;
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
		lassign "5 5" padx pady

		foreach {id name price weight img stock} $::productsData {
			if {$i < $productNr} { incr i ; continue }
			foreach var {id name price weight img stock} { dict set :productInfo $id $var [set $var] }

			set column [expr {$i%$::productsPerRow+1}]
			set row [expr {$i/$::productsPerRow+2}]

			set imgName product.$id
			:createProductImage $imgName $img medium	
			:createProductImage product_thumb_$id $img thumb	

			set correctWidth [:getCorrectWidth  Primary.TLabel $imgName]
			set text [fmt $correctWidth "$name | $price RON"]

			set labelName .products.lblProduct$id 
			after $lastTime [list ttk::button $labelName  -compound top -width $correctWidth  \
				-text $text -image $imgName -style Primary.TLabel -command [:callback  SelectProduct $id ] ]

			after $lastTime [list 	grid  $labelName -row $row -column $column   -padx $padx -pady $pady -sticky ns ] ;#-in .products 

			incr i
			if {$maxProducts <= [expr {abs($productNr-$i)}]} {  break }
		}
		set :currentColumns $column
	}

	:public method productScreenButtons {  } {
		foreach {var}  {productNr maxProducts i  column row lastTime } { upvar $var $var }

		set totalProducts [expr {[llength $::productsData]/6}]
		#puts "i is $i totalProducts $totalProducts productNr $productNr"
		set prevNumber [expr {$productNr-$maxProducts}] 
		set previousState [expr {$prevNumber < 0 ? "disabled" : "normal"}]
		set nextState [expr {$i >= $totalProducts  ? "disabled" : "normal"}]

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
				-style Success.TButton	-command [:callback showPlaceOrderDialog]] -row 1 -column $btnordercolumn -columnspan $btnordercolumnspan -pady 5
		}
	}

	:public method SelectProduct {{-new 1} id} {
		set name  "Quantity  [dict get ${:productInfo} $id name]"

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
		#TODO if screen lower than 300, hide cancel button!
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
			set dialog .placeorder.sf.scrolled 
			:productsTreeViewInitCalculations
			:productsTreeViewAddOrUpdateItems -update 1
		}
		destroy .selectQuantity
		:btnPlaceOrderUpdate ${:currentColumns}
	}

	:public method RemoveProductFromOrder {id} {
		dict unset :order $id

		set dialog .placeorder.sf.scrolled 
		set treeview $dialog.tvProducts
		

		$treeview delete product.$id
		:productsTreeViewInitCalculations
		:productsTreeViewAddOrUpdateItems -update 1
		:btnPlaceOrderUpdate ${:currentColumns}
		destroy .selectQuantity
	}

	#Dialog for finishing order by customer/waiter/cook
	#Showing all ordered things
	:public method showPlaceOrderDialog {} {
		set :placeOrderToplevel [set dialog .placeorder]
		set width [winfo width .]
		if {$width > 600} { set width 600 }

		set dialog [:scrolledFrameToplevel -width $width $dialog  "Place order"]
		 
		#Large screen
		:placeOrderTreeView $dialog
	}

	#Treeview is used for larger screens
	:public method placeOrderTreeView {dialog} {
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
		foreach {var}  {maxWidth columns nameWidth otherWidth nameColumnWidth charsPerLine  } { :upvar $var $var }
		#TODO get width of current window
		set maxWidth  [winfo width .];#240

		set columns {price quantity subtotal}
		set nr [llength $columns]	
		incr nr 2

		set nameWidth [expr int($maxWidth/$nr*2)]
		set otherWidth [expr int($maxWidth/$nr)]
		
		set columns {}
		set nameWidth [expr int($maxWidth*0.7)]
		if {$nameWidth > 600} { set nameWidth 600 }
		set nameColumnWidth $nameWidth

		if {$maxWidth < 300} {
			set nameColumnWidth [expr int($maxWidth*0.99)]
			set nameWidth [expr int($maxWidth*0.99)]
			set columns ""
		}
		set charsPerLine [:getCorrectWidth -width $nameColumnWidth Primary.TLabel]
		##puts "nameWidth $nameWidth otherWidth $otherWidth charsPerLine $charsPerLine"
	}

	:method placeOrderTreeviewColumnSettings {} {
		foreach {var}  {columns treeview otherWidth nameWidth } { upvar $var $var }
		foreach {column} $columns {
			$treeview heading $column -text [string totitle $column] -anchor center
			$treeview column $column -width $otherWidth -stretch 1
		}
		$treeview heading #0 -text "Products" -anchor center 

		$treeview column #0  -width $nameWidth -stretch 1 -anchor center
	}

	:public method productsTreeViewAddOrUpdateItems {{-update 0}} {
		foreach {var}  {treeview maxWidth charsPerLine dialog} { :upvar $var $var }
		#TODO group by type
		set orderedItems [dict  keys ${:order}]
		set total 0
		foreach key $orderedItems {
			set values ""
			foreach {var} {name price} { set $var [dict get ${:productInfo} $key $var] } 
			set quantity  [dict get ${:order} $key quantity] 
			set subtotal [expr {$price*$quantity}]

			set text [fmt $charsPerLine  "$name  $quantity x $price = $subtotal"]
			if {!$update} {
				$treeview insert {} end -id product.$key  -text  $text -tags product {*}[expr {$maxWidth <300 ? "" : "-image product_thumb_$key "}]
			} else {
				$treeview item product.$key -text $text -tags product
			}

			set total [expr {$total+$subtotal}]
		}
		:productTreeViewTotal $total
	}

	:method productTreeViewTotal {total} {
		foreach {var}  {treeview maxWidth update dialog} { :upvar $var $var }
		if {$update} {
			$treeview item total -text 	"Total: $total "
			set state normal
			if {$total == 0} {
				set state disabled
			}
			$dialog.btnPlaceOrder configure -state $state
		} else {
			$treeview insert {} end -id total -tags total -text "Total: $total " 
		}
	}

	:method placeOrderTreeviewEndConfiguration {args} {
		foreach {var}  {treeview dialog maxWidth} { upvar $var $var }

		$treeview tag bind product <ButtonRelease> [:callback modifyProductDetails $treeview  %x %y]
		$treeview tag  configure total -font $::ttk::theme::cerulean::theme(h3font) \
			-background #b5191f  -foreground $::ttk::theme::cerulean::theme(bgcolor) 

		grid [ttk::button $dialog.btnPlaceOrder -text "Place Order" -style Success.TButton -command [:callback sendOrderToServer]] \
			-row 15 -column 0 -padx 3 -pady 3 -sticky s

		#When selecting a treeview item allow to modify total and/or delete!
		#grid [ttk::button $dialog.btnDeleteSelected -text "Delete Selected" -style Danger.TButton] -row 15 -column 2 -padx 3
		grid [ttk::button $dialog.btnCancel -text "Cancel" -command [list destroy [winfo toplevel $dialog] ]] -row 15 -column 1 -padx 3 -pady 3 -sticky s

		set height [expr {$maxWidth < 300 ? 50 : 80}]
		ttk::style configure Height.Treeview -rowheight $height
		$treeview configure -style Height.Treeview
	}

	#We're interested if the current item under the finger/mouse is the same as the selection!
	#Then it means the user didn't just swype, so we can change info of product
	:public method modifyProductDetails {treeview x y} {
		set selection [$treeview selection]
		set item [$treeview identify item $x $y]
		if {$selection == $item} {
			#puts "Selection $selection item at x,y $x,$y is $item"
			set id [lindex [split $selection .] 1]
			:SelectProduct -new 0 $id
		}
	}
	
	#PROVIDE TEXT sending order to server..
	:public method sendOrderToServer {} {
		puts "the order is ${:order}"
		destroy ${:placeOrderToplevel} 
		destroy .products
		$::client getTablesList 

		$::client placeOrderAtTable [$::client currentTable get] [list ${:order}]	
		#set dialog [:scrolledFrameTodialog .info "Sending order to server"]


	}
	

	############# ############# ############# 
	# Product Order Handling
	############# ############# ############# 
	:public method productOrderScreen {command data} {
		switch -- $command {
			OK {  :productOrderOkScreen $data }
			TAKE {  :productTakeOrder $data }
			YOURORDERS {  :productYourOrders $data }
			COMPLETE {  :productOrderOkScreen $data }
			INACTIVE {  :productOrderInactive $data }
			INVALID {  :productOrderInvalid $data }
		}
	}

	#TODO beautiful popup instead of messagebox
	:public method productOrderOkScreen {nr} {
		set msg "Order has been registered under nr $nr" 
		tk_messageBox -title $msg -message $msg
	}
	
	:public method productTakeOrder {args} {
		 lassign $args orderID products productInfo datePlaced totalProducts
		 #SHOW WHAT HE NEEDS TO PREPARE!
		 dict set :cookOrders $orderID "products $products productInfo $productInfo datePlaced $datePlaced totalProducts $totalProducts"
	}

	:public method productYourOrders {args} {
		foreach {orderID  datePlaced totalProducts status} $args {
			dict set :cookOrders $orderID "datePlaced $datePlaced totalProducts $totalProducts"
		}

		 
	}
	

	:public method productOrderInvalid {msg} {
		set msg "ORDER INVALID: $msg" 
		tk_messageBox -title $msg -message $msg
	}
	


	:public method drawCookOrderList {  } {
		set treeview .cookOrders	
		ttk::treeview $treeview -columns $columns -height $totalRows -padding 0 ;#-yscrollcommand [list $dialog.vbar set]
		grid $treeview -row 0 -column 0 -sticky news -columnspan 5 
		grid columnconfigure $treeview 0 -weight 1
		grid rowconfigure $treeview 0 -weight 1
		
		set columns [list #0 OrderID date "Date Placed" total "Total Products"]
		foreach {column name} $columns {
			$treeview heading $column -text $name -anchor center
			$treeview column $column -stretch 1
		}

		foreach key [dict keys ${:cookOrders}] {
		 		set datePlaced [dict get ${:cookOrders} datePlaced ]
		 		set totalproducts [dict get ${:cookOrders} totalproducts ]
				$treeview insert {} end -id order.$key  -text  $key -tags order -values "$datePlaced totalproducts"
		 }

		$treeview tag bind product <ButtonRelease> [:callback viewOrderForCook $treeview  %x %y]
	#	$treeview tag  configure total -font $::ttk::theme::cerulean::theme(h3font) \
			-background #b5191f  -foreground $::ttk::theme::cerulean::theme(bgcolor) 

		ttk::style configure Height.Treeview -rowheight 30

	}
	:public method viewOrderForCook {treeview x y} {
		set selection [$treeview selection]
		set item [$treeview identify item $x $y]
		if {$selection == $item} {
			puts "Selection $selection item at x,y $x,$y is $item"
			set id [lindex [split $selection .] 1]
			:SelectProduct -new 0 $id
		}
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
}
