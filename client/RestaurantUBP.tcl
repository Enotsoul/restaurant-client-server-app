#!/usr/bin/env tclsh
#####################
# Aplicatia Clientului Pentru Restaurant
#####################
set ::VERSION 0.4

# 0. Includem pachetele necesare
foreach pkg {tls Tk nx nx::trait Img canvas::gradient} {
	package require $pkg
}
set files [glob -d [file dir [info script]] *.tcl]
#foreach file {theme.tcl wordwrap.tcl Scrolledframe.tcl} 
source UIFunctions.tcl
foreach file $files {
	if {[string match *$file* [info script]]} { continue }
	source $file
}
ttk::setTheme cerulean
#ttk::setTheme clam
namespace import ::scrolledframe::scrolledframe
#

nx::Class create RestaurantUI -mixins [list UIFunctions  ] {
	:require trait nx::traits::callback

	:variable productManagement:object,type=ProductManagementUI 
	:variable tableManagement:object,type=TableManagementUI
	:variable authentication:object,type=AuthenticationUI

	:variable -accessor public width
	:variable -accessor public height

	#CREATE ICON IMAGE FOR DESKTOP
	if {0} {
		image create photo cool -file  ~/Projects/RestaurantApp/server/images/pepsi.jpg

		wm iconphoto .twind cool
	}

	:method init {  } {
		set :authentication [AuthenticationUI new]
		set :tableManagement [TableManagementUI new]
		set :productManagement [ProductManagementUI new]
	
		:screenSettings
	
		#	:scrolledFrameExample
		${:authentication}	drawLoginScreen
		${:authentication} loadSettings
	}

	#View device DPI and screen size
		 #Define FONTsize and image size
		 #Make fullscreen
	:public method screenSettings {  } {
		#Differentiate between desktop zoomed and fullscreen on android
		wm attributes . -zoomed 1
	#	wm attributes . -fullscreen 1
		set :height [winfo  height .]
		set :width [winfo  width .]
	}
	

	:public method drawProductScreen {products} {
		${:productManagement} drawProductScreen $products	
	}
	:public method drawTableScreen {tables} {
		${:tableManagement} drawTableScreen -canvas_width 800 -canvas_height 600 $tables
	}

	:public method productOrderScreen {command data} {
		${:productManagement} productOrderScreen $command  $data	
	}
	
	proc writePdf {} {
		package require pdf4tcl
		pdf4tcl::new mypdf -paper a4
		mypdf canvas . 
		mypdf write -file products.pdf
		mypdf destroy
	}


}

######################## 
# Starting Up!
######################## 

set client [ClientConnection new -port 7737 -host localhost]
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
