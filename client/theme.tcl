
#How to style TTK colours
# http://wiki.tcl.tk/37973
#.lblImg  configure -image soup.medium -text "Soup" -compound top

#tk scaling -displayof . 10
proc determineDPI {} {
	set cm [winfo pixels . 1c]
	set screenwidth
	set screenheight
}


namespace eval ttk::theme::cerulean {

	variable version 0.1

	#TODO Define fonts size based on SCREEN SIZE and DPI!
	array set theme {
		fontcolor white
		bgcolor #fbfcfc
		checkbuttonfont {Helvetica 12}
		radiobuttonfont {Helvetica 12}
		labelfont {Helvetica 12}
		entryfont {Helvetica 12}
		buttonfont {Helvetica 14}

	}
	set theme(subheadingfont) [font create HelveticaSubheading -family Helvetica -size 14 -weight bold]

	. configure -background $theme(bgcolor)

	#Loading images.
	#####################################
	#Create images for checkbox and radiobutton
	#####################################
	foreach {image file} {
		chk_unchecked img/A-checkbox.png	 chk_unchecked_focus img/B-checkbox-focus.png
		chk_checked img/C-checkbox-checked.png
		chk_checked_focus img/D-checkbox-checked-focus.png
		chk_unchecked_disabled img/E-checkbox-disabled.png
		chk_checked_disabled img/F-checkbox-checked-disabled.png

		radio_unchecked img/G-radio.png radio_unchecked_focus img/H-radio-focus.png
		radio_checked_focus img/J-radio-checked-focus.png
		transparent img/transparent.png
	} {
		set $image [image create photo -file $file]
	}



	ttk::style theme create cerulean -parent clam -settings {
		ttk::style element create Checkbutton.myindicator \
			image [list $chk_unchecked   selected $chk_checked_focus   hover $chk_unchecked_focus \
	disabled $chk_unchecked_disabled  {disabled selected} $chk_checked_disabled  ]

		ttk::style element create Radiobutton.myindicator \
			image [list $radio_unchecked   selected $radio_checked_focus   hover $radio_unchecked_focus   ] 

			#####################################
			# Redefine the checkbutton layout with the new element
			#####################################
		ttk::style layout TCheckbutton {
			Checkbutton.padding -sticky nswe -children {
				Checkbutton.myindicator -side left -sticky {}
				Checkbutton.focus -side left -sticky w -children {
					Checkbutton.label -sticky nswe
				}
			}
		}

		ttk::style configure TCheckbutton -background $theme(bgcolor) -font $theme(checkbuttonfont) ;#$theme(labelfont)
		ttk::style map TCheckbutton -background \
			[list active $theme(bgcolor) disabled $theme(bgcolor) readonly $theme(bgcolor)]

			#####################################
			# Redefine the radiobutton layout with the new element
			#####################################
		ttk::style layout TRadiobutton {
			Radiobutton.padding -sticky nswe -children {
				Radiobutton.myindicator -side left -sticky {}
				Radiobutton.focus -side left -sticky w -children {
					Radiobutton.label -sticky nswe
				}
			}
		}

		ttk::style configure TRadiobutton -background  $theme(bgcolor)  -font $theme(radiobuttonfont) ;#$theme(labelfont)
		#ttk::style configure TRadiobutton -font namedfont
		ttk::style map TRadiobutton -background \
			[list active  $theme(bgcolor) disabled  $theme(bgcolor) readonly  $theme(bgcolor)]



		###########################
		#Buttons
		###########################


		#linear-gradient(#54b4eb, #2fa4e7 60%, #1d9ce5)
		set foreground $theme(fontcolor)
		foreach {type} {Primary Success Info Warning Danger}  {background hover pressed} { 
		#54b4eb #2fa4e7  #1d9ce5 
		#88c149 #73a839  #699934
		#04519b #033c73  #02325f
		#ff6707 #dd5600  #c94e00
		#e12b31 #c71c22  #b5191f
		}	{
			ttk::style configure $type.TButton -font $theme(buttonfont) -foreground $foreground   -background $background  -anchor center -padding {15 5} 
			ttk::style map $type.TButton -background  [list pressed $pressed disabled grey   hover $hover  ]
			ttk::style configure $type.TButton  -bordercolor $pressed  -lightcolor $hover  -darkcolor $pressed 

		}
		#black #233641 #57666E 
		foreach {var} { 	#54b4eb #2fa4e7  #1d9ce5  } color {background hover pressed} { set $color $var  }
		#Default Buttons
		ttk::style configure TButton -font $theme(buttonfont) -foreground $foreground   -background $background  -anchor center -padding {15 5} 
		ttk::style map TButton -background  [list pressed $pressed  disabled grey hover $hover  ]
		ttk::style configure TButton  -bordercolor $pressed  -lightcolor $hover  -darkcolor $pressed 





#		image create photo greenbutton -file img/green_button.png 
#		ttk::style configure Zero.TButton -font {Helvetica 14} -image greenbutton -borderwidth 0



		###########################
		#ttk::combobox
		###########################
		if {0} {
			ttk::style configure TCombobox -background color
			ttk::style configure TCombobox -foreground color
			ttk::style configure TCombobox -fieldbackground color
			ttk::style configure TCombobox -selectbackground color
			ttk::style configure TCombobox -selectforeground color
			ttk::style map TCombobox -background \
				[list disabled color readonly color]
			ttk::style map TCombobox -foreground \
				[list disabled color readonly color]
			ttk::style map TCombobox -fieldbackground \
				[list disabled color readonly color]
			option add *TCombobox*Listbox.background color
			option add *TCombobox*Listbox.foreground color
			option add *TCombobox*Listbox.selectBackground color
			option add *TCombobox*Listbox.selectForeground color
		}

		###########################
		#ttk::entry
		###########################

		if {0} {
		}
		#	#54b4eb #2fa4e7  #1d9ce5 
		ttk::style configure TEntry -background #1d9ce5   -foreground black 
		ttk::style configure TEntry -fieldbackground  $theme(bgcolor) 
		ttk::style configure TEntry -selectbackground #54b4eb -selectforeground white
		ttk::style configure TEntry -padding {5 3}
		#.entry configure -font $theme(buttonfont)
		#set focus #54b4eb 
		set normal #bdc3c7 
		set focus #1d9ce5
		ttk::style configure TEntry -bordercolor  $normal -lightcolor $normal  -darkcolor $normal 
		#TODO success, warning, error..
		ttk::style map TEntry \
			-bordercolor	[list hover $focus focus $focus] \
			-lightcolor	[list hover $focus focus $focus] \
			-darkcolor	[list hover $focus  focus $focus] 

		#dOES NOT WORK!
		ttk::style configure TEntry -font $theme(subheadingfont)
		#Instead you must configure each entry manually
		#.entry configyre -font fontname ;# Instead

		###########################
		#ttk::frame
		###########################
		ttk::style configure TFrame -background $theme(bgcolor)

		###########################
		#ttk::label
		###########################
		


		ttk::style configure TLabel -background  $theme(bgcolor) ;# -foreground color
		ttk::style configure TLabel -font {Helvetica 12}
		ttk::style map TLabel -background \
			[list disabled  $theme(bgcolor)  readonly  $theme(bgcolor)]
			#ttk::style map TLabel -foreground \
			[list disabled color readonly color]

	foreach {type} {Primary Success Info Warning Danger}  {background hover pressed} { 
		#54b4eb #2fa4e7  #1d9ce5 
		#88c149 #73a839  #699934
		#04519b #033c73  #02325f
		#ff6707 #dd5600  #c94e00
		#e12b31 #c71c22  #b5191f
		}	{
		ttk::style configure $type.TLabel -background  $background -foreground white -font {Helvetica 12} \
			-bordercolor  $background  -lightcolor $background  -darkcolor $background 
		ttk::style map $type.TLabel -background \
			[list hover $hover]
	}

		ttk::style configure Hide.TLabel -font {Helvetica 1}

			###########################
			#ttk::labelframe
			###########################
			#http://wiki.tcl.tk/20054
		set background #54b4eb 
		set foreground white
		ttk::style configure TLabelframe -background $theme(bgcolor)  -bordercolor #1d9ce5 
		ttk::style configure TLabelframe.Label -background $theme(bgcolor)   -foreground #54b4eb -font $theme(subheadingfont) 

		#ttk::style configure TLabelframe.Label -font namedfont

		ttk::style configure custom.TLabelframe \
			-labeloutside true \
			-labelmargins { 10 10 10 10}  

		ttk::style configure TLabelframe -background $theme(bgcolor)  -bordercolor #1d9ce5 
		# ttk::style layout custom.TLabelframe {
		#  Separator.separator -sticky new
			# }


			###########################
			#ttk::separator
			###########################
		ttk::style configure TSeparator -background #1d9ce5

		###########################
		#ttk::spinbox
		###########################

		###########################
		#ttk::scrollbar
		###########################

		###########################
		#ttk::treeview
		###########################
		if {0} {

			ttk::style configure Treeview -background color
			ttk::style configure Treeview -foreground color
			ttk::style configure Treeview -font namedfont
			ttk::style configure Treeview -fieldbackground color
			ttk::style map Treeview -background \
				[list selected color]
			ttk::style map Treeview -foreground \
				[list selected color]
			ttk::style configure Heading -font namedfont
			ttk::style configure Heading -background color
			ttk::style configure Heading -foreground color
		}
		###########################
		#ttk::menubutton
		###########################
		if {0} {
			ttk::style configure TMenubutton -background color
			ttk::style configure TMenubutton -foreground color
			ttk::style configure TMenubutton -font namedfont
			ttk::style map TMenubutton -background \
				[list active color disabled color]
			ttk::style map TMenubutton -foreground \
				[list active color disabled color]
		}

		###########################
		#ttk::notebook
		###########################
		if {0} {

			ttk::style configure TNotebook -background color
			ttk::style configure TNotebook.Tab -background color
			ttk::style configure TNotebook.Tab -foreground color
			ttk::style map TNotebook.Tab -background \
				[list selected color active color disabled color]
			ttk::style map TNotebook.Tab -foreground \
				[list selected color active color disabled color]
			ttk::style configure TNotebook.Tab -font namedfont
			ttk::style map TNotebook.Tab -font \
				[list selected namedfont active namedfont disabled namedfont]
		}
		###########################
		#ttk::progressbar
		###########################
		#ttk::style configure TProgressbar -background color
		#ttk::style configure TProgressbar -troughcolor color

		###########################
		#ttk::pannedwindow
		###########################

		#ttk::style configure TPanedwindow -background color
		#ttk::style configure Sash -sashthickness 5

		###########################
		#ttk::slider
		###########################

		###########################
		#ttk::scale
		###########################
		if {0} {
			ttk::style configure TScale -background color
			ttk::style configure TScale -troughcolor color
			ttk::style map TScale -background \
				[list active color]

			ttk::style configure TScale -lightcolor color
			ttk::style configure TScale -darkcolor color
			ttk::style configure TScale -bordercolor color
		}
	}
}

#####################################
#Showing to screen
#####################################
if {[info exists showtestgui]} {
proc watch {name} {
	set watch  "" ;#.theme
	#toplevel .theme -padx 14 -pady 15
#	toplevel .theme -padx 14 -pady 15

	ttk::labelframe $watch.lf -text "Country of choice"  -style custom.TLabelframe -labelanchor n
	ttk::label $watch.lf.value -textvariable $name

	grid $watch.lf -sticky news
	grid  $watch.lf.value -padx 0 -pady 0 -sticky news
	grid [ttk::checkbutton $watch.lf.chkOk -text "Do you agree to our laws?"] -sticky news
	grid [ttk::radiobutton $watch.lf.radiosuccess  -variable type -value success -text "Success!"] -sticky news
	grid [ttk::radiobutton $watch.lf.radiowarning -variable type  -value warning -text "/!\\Warning /!\\"] -sticky news
	grid [ttk::button $watch.lf.disable  -text "Disable" -command changeState ] -sticky news
}
proc changeState {} {
	set newState !disabled
	.lf.chkOk configure -state $newState 
	puts "newstate $newState and states $state"
}

set country Romania
watch country


foreach {type} {Primary Success Info Warning Danger Zero} {
	grid [ttk::button .btn$type -style $type.TButton -text "$type and to talk about having a nice day! " -compound center] -padx 0 -pady 0 -ipady 0 -ipadx 0
}
grid [ttk::entry .txtEnter -font $theme(entryfont) ] -sticky news
 

#puts [ttk::style element options TButton.label]
puts [ttk::style element options  TLabelframe.label]

}

if {0} {
	winfo class .lblCool
	#See layout of class
	ttk::style layout TLabel
	#Get all available options for Class
	ttk::style element options TLabel.label
	ttk::style configure TLabel -foreground green
}
