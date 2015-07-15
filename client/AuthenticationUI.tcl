#Handle Login/Register UI
nx::Class create AuthenticationUI -mixins [list UIFunctions  ]  {

	:require trait nx::traits::callback

	#################################	
	# Login Screen
	#################################	
	
	:public method drawLoginScreen {} {
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

	}

	
	:public method login {} {
		set errors ""

		if {![:loginVerification]} { return }

		.login.lblinfo configure -text "" 	
		:saveSettings
		if	{[$::client Connect]} {
			$::client AuthUser ${:txtUsername} ${:txtPassword} 
		}

	}

	:method loginVerification {  } {
		if {![info exists :txtUsername] || ![info exists :txtPassword]} {
			set errors "Username and/or password must not be empty"
			return 0
		}
		if {[string length ${:txtUsername}] < 3 || [string length ${:txtPassword}] < 3 } {
			set message "Username and password must be at least 3 characters long"
			tk_messageBox -message $message 
			.login.lblinfo configure -text $message -style Danger.TLabel
			puts [.login.lblinfo configure -style]
			return 0
		}
		return 1
	}


	:public method saveSettings {args} {
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

}
