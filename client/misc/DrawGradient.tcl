#!/usr/bin/wish -f
##
## SCRIPT: make_colorGradientOnCanvas_entryField7parms.tk
##
##+#######################################################################
## PURPOSE:  This TkGUI script facilitates the creation of
##           rectangular color-gradient images that can be used, for example,
##           for the background of 'buttons' in GUIs such as 'toolchests'.
##
##           A screen/window capture utility (like 'gnome-screenshot' on Linux)
##           can be used to capture the image in a PNG file, say.
##
##           Then, if necessary, an image editor (like 'mtpaint' on Linux)
##           can be used to crop the window capture image to get only the
##           rectangular area of the canvas containing the color-gradient
##           --- or some sub-rectangle of that area.
##
##           Furthermore, utilities (such as the ImageMagick 'convert' command
##           on Linux) can be used to 'mirror' or 'flip' a gradient image in
##           an image file (PNG or JPEG or GIF). The 'mirror'  and 'flip'
##           operations can be applied vertically or horizontally ---  and
##           can be applied multiple times, for various visual effects.
##
##           The resulting rectangular color-gradient image can then be used as a
##           background in Tk widgets, such as button or canvas or label widgets
##           in 'toolchests' or other types of GUIs. 
##
##+#####################
## GUI LAYOUT and METHOD:
##
##           The GUI contains a rectangular canvas widget into which the
##           color gradient is drawn with canvas 'create line' commands,
##           where the lines can be either horizontal (in the x direction)
##           or vertical (in the y direction).
##
##           In addition to the canvas widget (in a bottom frame of the GUI
##           window), in a top frame of the GUI window, there are a couple of
##           buttons ('Draw' and 'Exit') and an entry field.
##
##           The entry field contains 7 values --- of the format
##               x/y r1 g1 b1 r2 g2 b2
##           Examples:
##             x 255 255 0 255 0 0
##             y 255 0 255 0 0 255
##
##           The first example says draw the lines horizontally starting
##           from yellow on the left to red on the right.
##
##           The second example says draw the lines vertically starting
##           from magenta at the top to blue on the bottom.
##
##           The seven parms (x/y r1 g1 b1 r2 g2 b2)
##           are passed into a 'DrawGradient' proc that draws the lines
##           within the canvas, filling the canvas with colored pixels.
##
##+########################################################################
## REFERENCE:
## The 'DrawGradient' proc is based on a Tcl-Tk script by Damon Courtney
## --- published at http://wiki.tcl.tk/6100 .  (downloaded 2011sep26)
## That script draws gradients on multiple rectangular canvases, packed
## top to bottom. You need to edit that script to change colors or
## gradient direction. No GUI for entry of those indicators is provided.
##
##+########################################################################
## 'CANONICAL' STRUCTURE OF THIS CODE:
##
##  0) Set general window parms (win-name,win-position,color-scheme,fonts,
##                 widget-geometry-parms,text-array-for-labels-etc).
##  1a) Define ALL frames (and sub-frames, if any).
##  1b) Pack the frames and sub-frames.
##  2) Define all widgets in the frames, frame-by-frame.
##     When the widgets for a frame are defined, pack them.
##
##  3) Define keyboard and mouse/touchpad/touch-sensitive-screen
##     'event' BINDINGS, if needed.
##  4) Define PROCS, if needed.
##  5) Additional GUI INITIALIZATION (typically with one or two procs),
##     if needed.
##
##
## Some detail on the code structure for this particular script:
##
##  1a) Define ALL frames:
## 
##      Top-level :  '.fRbuttons' and '.fRcanvas'
##
##      Sub-frames: none
##
##  1b) Pack ALL frames.
##
##  2) Define all widgets in the frames (and pack them):
##
##       - In '.fRbuttons': 2 button widgets ('Draw' and 'Exit') and
##                        an entry widget (for the 7 gradient-drawing parms)
##
##       - In '.fRcanvas': one 'canvas' widget 
##
##  3) Define bindings:  one, for the entry widget
##
##  4) Define procs:
##     - 'DrawGradient'    invoked by the 'Draw' button
##
##  5) Additional GUI initialization:  Execute 'DrawGradient' once
##                                     with an initial, example
##                                     set of 7 parms --- to start with
##                                     a color-gradient in the canvas
##                                     rather than a blank canvas.
##
##+#######################################################################
## DEVELOPED WITH:
##   Tcl-Tk 8.5  on Ubuntu 9.10 (2009 October - 'Karmic Koala').
##
##   $ wish
##   % puts "$tcl_version $tk_version"
##                                  showed  8.5 8.5   on Ubuntu 9.10,
##   after installing Tcl-Tk 8.5 in place of Tcl-Tk 8.4.
##
##+########################################################################
## MAINTENANCE HISTORY:
## Created by: Blaise Montandon 2012aug01
## Changed by: Blaise Montandon 2012nov18 Added braces to 9 'expr' statements.
##                                        Provided more consistent indenting
##                                        of the code. Touched up the comments
##                                        to match the final code. Added a
##                                        text-array for labels,buttons,etc.
##                                        Added calc of minsize of window.
##                                        Moved canvas to bottom of GUI.
##+########################################################################

##+######################################################################
## Set WINDOW TITLES.
##+######################################################################

wm title    . "Draw-Color-Gradient in a Rectangular Canvas"
wm iconname . "DrawGradient"


##+######################################################################
## Set WINDOW POSITION.
##+######################################################################

wm geometry . +15+30


##+#####################################################################
## Set a COLOR SCHEME for the window and its widgets.
##+#####################################################################

tk_setPalette "#cfcfcf"


##+#####################################################################
## SET FONT-NAMES.
## We use a variable-width font for buttons and labels.
## We use a fixed-width font for the entry field, for easy access
## to narrow characters like i, j, l, and the number 1.
##+#####################################################################

font create fontTEMP_varwidth \
   -family {comic sans ms} \
   -size -14 \
   -weight bold \
   -slant roman

## Some other possible (similar) variable width fonts:
##  Arial
##  Bitstream Vera Sans
##  DejaVu Sans
##  Droid Sans
##  FreeSans
##  Liberation Sans
##  Nimbus Sans L
##  Trebuchet MS
##  Verdana

font create fontTEMP_fixedwidth  \
   -family {liberation mono} \
   -size -14 \
   -weight bold \
   -slant roman

## Some other possible fixed width fonts (esp. on Linux):
##  Andale Mono
##  Bitstream Vera Sans Mono
##  Courier 10 Pitch
##  DejaVu Sans Mono
##  Droid Sans Mono
##  FreeMono
##  Nimbus Mono L
##  TlwgMono


##+#######################################################################
## SET GEOM VARS FOR THE VARIOUS WIDGET DEFINITIONS.
## (e.g. width and height of canvas, padding for Buttons)
##+#######################################################################

## CANVAS parms:

set initCanWidthPx 400
set initCanHeightPx 24
# set BDwidthPx_canvas 2
set BDwidthPx_canvas 0


## BUTTON parms:

set PADXpx_button 0
set PADYpx_button 0
set BDwidthPx_button 2


## ENTRY parms:

set BDwidthPx_entry 2
set initENTRYwidthChars 30


##+##################################################################
## Set a MINSIZE of the window (roughly),
## according to the approx WIDTH of the widgets in the
## 'fRbuttons' frame --- 2 buttons, 1 label, 1 entry.
##
## --- and according to the approx HEIGHT of the 2 frames
## --- 'fRbuttons', 'fRcanvas'.
##+##################################################################
## We allow the window to be resizable. We pack the canvas with
## '-fill both' so that the canvas can be enlarged by enlarging the
## window. The 'Draw' proc can be used to re-fill the canvas with
## the user-specified color gradient.
##+#################################################################

set minWinWidthPx [font measure fontTEMP_varwidth \
   " Exit  Draw  Draw-Color-Gradient parms: x 255 255 0 255 0 0"]

## Add some to account for right-left-side window border-widths
## (about 2x3=6 pixels) and widget border-widths --- about
## 4 widgest x 4 pixels/widget = 16 pixels.

set minWinWidthPx [expr {22 + $minWinWidthPx}]


## For MIN-HEIGHT, allow:
##      1 char    high for frame 'fRbuttons',
##     24 pixels  high for frame 'fRcanvas'.

set minCharHeightPx [font metrics fontTEMP_fixedwidth -linespace]

set minWinHeightPx [expr { 24 + $minCharHeightPx}]

## Add some to account for top-bottom window decoration (about 23 pixels)
## and frame/widget padding/borders (about
## 4 frames/widgets x 4 pixels/frame-widget = 16 pixels).

set minWinHeightPx [expr {39 + $minWinHeightPx}]

## FOR TESTING:
#   puts "minWinWidthPx = $minWinWidthPx"
#   puts "minWinHeightPx = $minWinHeightPx"

wm minsize . $minWinWidthPx $minWinHeightPx


## If you want to make the window un-resizable, 
## you can use the following statement.

# wm resizable . 0 0



##+################################################
##  Load a TEXT-ARRAY variable with text for
## labels and other GUI widgets --- to facilitate
## 'internationalization' of this script.
##+################################################

## if { "$VARlocale" == "en"}

set aRtext(buttonEXIT)   "Exit"
set aRtext(buttonDRAW)   "Draw"
set aRtext(labelENTRY)   "\
Draw-Color-Gradient parms:
     (x/y r1 g1 b1 r2 g2 b2)"


## END OF  if { "$VARlocale" == "en"}


##+####################################################################
## DEFINE *ALL* THE FRAMES:
##
##   Top-level :  '.fRbuttons' and '.fRcanvas'
##               
##   Sub-frames: none
##+####################################################################

## FOR TESTING:  (of expansion of frames, esp. during window expansion)
# set RELIEF_frame raised
# set BDwidth_frame 2

set RELIEF_frame flat
set BDwidth_frame 0

frame .fRcanvas   -relief $RELIEF_frame  -borderwidth $BDwidth_frame

frame .fRbuttons  -relief $RELIEF_frame  -borderwidth $BDwidth_frame


##+################################################################
## PACK the 2 top-level FRAMES. 
##+################################################################

pack .fRbuttons \
   -side top \
   -anchor nw \
   -fill x \
   -expand 0

pack .fRcanvas \
   -side top \
   -anchor nw \
   -fill both \
   -expand 1

## OK. All frames are defined and packed.
## Now define the widgets within the frames.


##+#######################################################################
## IN THE '.fRbuttons' frame -
## DEFINE the 'Draw' and 'Exit' buttons
## --- and a pair of label and entry widgets.
##+#######################################################################

button .fRbuttons.buttEXIT \
   -text "$aRtext(buttonEXIT)" \
   -font fontTEMP_varwidth \
   -padx $PADXpx_button \
   -pady $PADYpx_button \
   -relief raised \
   -bd $BDwidthPx_button \
   -command {exit}

button .fRbuttons.buttDRAW \
   -text "$aRtext(buttonDRAW)" \
   -font fontTEMP_varwidth \
   -padx $PADXpx_button \
   -pady $PADYpx_button \
   -relief raised \
   -bd $BDwidthPx_button \
   -command {eval DrawGradient .fRcanvas.can $ENTRYstring}

label .fRbuttons.lab \
   -text "$aRtext(labelENTRY)" \
   -font fontTEMP_varwidth \
   -justify left \
   -anchor w \
   -relief flat \
   -bd $BDwidthPx_button

set ENTRYstring "x 255 255 0 255 0 0"

entry .fRbuttons.ent \
   -textvariable ENTRYstring \
   -bg "#f0f0f0" \
   -font fontTEMP_fixedwidth \
   -width $initENTRYwidthChars \
   -relief sunken \
   -bd $BDwidthPx_entry


##+##############################################
## Pack ALL the widgets in the .fRbuttons' frame.
##+##############################################

pack .fRbuttons.buttEXIT \
   -side left \
   -anchor w \
   -fill none \
   -expand 0

pack .fRbuttons.buttDRAW \
   -side left \
   -anchor w \
   -fill none \
   -expand 0

pack .fRbuttons.lab \
   -side left \
   -anchor w \
   -fill none \
   -expand 0

pack .fRbuttons.ent \
   -side left \
   -anchor w \
   -fill x \
   -expand 1


##+#############################
## In the '.fRcanvas' frame -
## DEFINE-and-PACK CANVAS WIDGET.
##+#############################
## We set highlightthickness & borderwidth of the canvas to
## zero, as suggested on page 558, Chapter 37, 'The Canvas
## Widget', in the 4th edition of the book 'Practical
## Programming in Tcl and Tk'.
##+######################################################

canvas .fRcanvas.can \
   -width $initCanWidthPx \
   -height $initCanHeightPx \
   -relief flat \
   -highlightthickness 0 \
   -borderwidth 0

pack .fRcanvas.can \
   -side top \
   -anchor nw \
   -fill both \
   -expand 1

## OK. All widgets are defined and packed.
## Now define bindings and procs.

##+#######################################################################
##  BINDINGS SECTION:  one, for Enter key in the entry field.
##+#######################################################################

bind .fRbuttons.ent <Return>  {eval DrawGradient .fRcanvas.can $ENTRYstring}


##+#######################################################################
##  PROCS SECTION: 
##    - DrawGradient'   to fill the specified canvas according to the
##                      7 parms from the ENTRYstring variable
##+#######################################################################

##+#####################################################################
## proc DrawGradient -
##
## PURPOSE:
##     Draws the gradient on the canvas using canvas 'create line'
##     commands. Draws vertical or horizontal lines according to
##     the axis-specification: 'x' or 'y'. Interpolates between
##     2 RGB colors.
##
## CALLED BY:  <Return> binding on .fRbuttons.ent
##             and in the additional-GUI-initialization section at
##             the bottom of this script.
##+####################################################################

proc DrawGradient {win axis r1 g1 b1 r2 g2 b2} {

   global ENTRYstring

   # $win delete TAGgradient

   set width  [winfo width $win]
   set height [winfo height $win]

   switch -- $axis {
      "x" { set max $width; set x 1 }
      "y" { set max $height; set x 0 }
      default {
         ## We could put the error msg on the end of the user-entry
         ## in the entry-field.
         # set ENTRYstring "$ENTRYstring ERR: Invalid 1st parm. Must be x or y."
         # return
         return -code error "Invalid 1st parm: $axis.  Must be x or y"
      }
   }

   if { $r1 > 255 || $r1 < 0 } {
      return -code error "Invalid color value for r1: $r1"
   }


   if { $g1 > 255 || $g1 < 0 } {
      return -code error "Invalid color value for g1: $g1"
   }

   if { $b1 > 255 || $b1 < 0 } {
      return -code error "Invalid color value for b1: $b1"
   }

   if { $r2 > 255 || $r2 < 0 } {
      return -code error "Invalid color value for r2: $r2"
   }

   if { $g2 > 255 || $g2 < 0 } {
      return -code error "Invalid color value for g2: $g2"
   }

   if { $b2 > 255 || $b2 < 0 } {
      return -code error "Invalid color value for b2: $b2"
   }

   set rRange [expr {$r2 - double($r1)}]
   set gRange [expr {$g2 - double($g1)}]
   set bRange [expr {$b2 - double($b1)}]

   set rRatio [expr {$rRange / $max}]
   set gRatio [expr {$gRange / $max}]
   set bRatio [expr {$bRange / $max}]

   for {set i 0} {$i < $max} {incr i} {
      set nR [expr {int( $r1 + ($rRatio * $i) )}]
      set nG [expr {int( $g1 + ($gRatio * $i) )}]
      set nB [expr {int( $b1 + ($bRatio * $i) )}]

      set col [format {%2.2x} $nR]
      append col [format {%2.2x} $nG]
      append col [format {%2.2x} $nB]

      ## FOR TESTING:
      #  puts "col = $col"

      if {$x} {
         $win create line $i 0 $i $height -tags TAGgradient -fill "#$col"
      } else {
         $win create line 0 $i $width $i -tags TAGgradient -fill "#$col"
      }
   }

}
## END OF proc 'DrawGradient'


##+###############################################################
## ADDITIONAL-GUI-INITIALIZATION, if needed (or wanted).
##
## We draw a gradient on the canvas, rather than letting the
## GUI come up with an empty canvas.
##+###############################################################

update

## 'update' is needed before DrawGradient so that the
## canvas width and height are implemented.
## DrawGradient uses 'winfo' to get those dimensions.

eval DrawGradient .fRcanvas.can $ENTRYstring
