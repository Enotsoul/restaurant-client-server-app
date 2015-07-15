nx::Class create TableManagementUI -mixins [list UIFunctions  ]  {

	:require trait nx::traits::callback
#We draw the table based on data from the server
#TODO get screen size and draw based on that size!
	:public method drawTableScreen {{-canvas_width 0} {-canvas_height 0} tablesData} {
		if {!$canvas_width} {  set canvas_width [winfo width .] }
		if {!$canvas_height} { set canvas_height [winfo height .] }
	#	.login destroy
		grid remove .login
		destroy .login

		lassign "10 10 200 100 30" start_x start_y item_width item_height spacing
		
		grid [canvas .table -bg #fbfcfc   -width $canvas_width -height $canvas_height] -column 1 -row 1
		.table bind table <1>  [:callback  SelectTable %x %y ] 

		foreach {id persoane fumatori ocupat} $tablesData {
			if {$ocupat} { set color #c0392b	} else { set color #2ecc71  }
			set cid [.table create rectangle $start_x $start_y [expr {$start_x+$item_width}] [expr {$start_y+$item_height}] \
				-tags [list table table.$id] -fill $color -outline black]

			set font {Helvetica 12 bold }
			set text "Table  $id  ($persoane)"

			.table create text [expr {$start_x+($item_width)/2}] [expr {$start_y+$item_height/2}] -font $font  -text $text -justify center -fill white 
				#Masa.id este id-ul mesei, salvam id-ul desenului pe canvas
			#TODO salvare detalii undeva.. sau cerere detalii mereu actualizate?:D
			set ::Tables(masa.$id) $cid
			set ::Tables(canvasid.$cid) $id

			incr start_x [expr {$item_width+$spacing}]
			if {$start_x >= [expr {$canvas_width-$item_width}]} {
				set start_x 10
				incr start_y [expr {$item_height+$spacing}]
			}
		}
	}

	:public method SelectTable {x y} {
		set x [.table canvasx $x] ; set y [.table canvasy $y]
		set i [.table find closest $x $y]
		set t [.table gettags $i]
		puts "Table $i $t"

		#Select a table to either
		#1. place / update an order 
		#2. view order status (if already occupied)
		#3. view statistics
		#4. say that table is occupied/unoccupied
		set :currentTable $i
		$::client  currentTable set $i
		$::client getProductList
	}
}
