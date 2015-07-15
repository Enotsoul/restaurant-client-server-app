# fmt.tcl by Jim Graham, N5IAL/4.
#
# Feel free to use this in your code.  I would, however, ask that you
# leave these comments in place, and if you improve it, please send your
# changes to me at spooky130u AT gmail DOT com.  Thanks!
#
# I wrote this to use with my as-of-yet unnamed brewer's inventory /
# grain/hop/yeast database (it's both), which I plan on integrating with
# my brewer's recipe formulator (also written with Tcl/Tk) called
# GTbrew2.
#
# This is a crude attempt at implementing word-wrap in Tcl.  I'm writing
# this because when I tried to use "-wrap word" in a text widget, as the
# docs suggest, it didn't wrap by word boundaries at all....  This script
# makes some limited attempts to avoid wrapping at bad places (e.g.,
# don't wrap "20 deg." between 20 and deg....wrap the 20 along with the
# unit that follows.  Sadly, I don't have (or, at least, am not aware of
# having) a typography document that lists bad points to wrap a line, so
# I'm just having to use the ones I DO know (and that I thought about as
# I wrote this).
#
# I almost forgot....  USAGE:  fmt n s
# Where:  n is an integer number for the maximum width of each line,
# and s is the string you want reformatted.
#

# from jdglib
proc streq {s1 s2} { return [expr {[string compare $s1 $s2] == 0}] }

# from jdglib
# Compare multiple strings with s1 ... return number of matches
proc streqx {s1 s2 args} {
   set ret 0
   foreach s "$s2 $args" { if {[streq $s1 $s]} { incr ret } }
   return $ret
}

# NOT all-inclusive, but check for some obvious bad breaks

proc check_return {s1 s2} {
   regsub {  *$} $s1 {} s3 ; set s1 $s3
   regsub {^  *} $s2 {} s3 ; set s2 $s3
   set cut1 [string last " " $s1] ; incr cut1
   set cut2 [string first " " $s2] ; incr cut2 -1
   set w1 [string range $s1 $cut1 end]
   set w2 [string range $s2 0 $cut2]
   set goodbreak 1

   if {[streqx $w1 Mr. Mr Mrs. Mrs Miss Dr Dr. Prof.]} { set goodbreak 0 }

# Here we try to prevent wrapping between a number and its unit.

#  if {[regexp {^[0-9\.]*$} $w1] && [regexp {^[a-zA-Z][a-zA-Z]\.?$} $w2]} {
#     set goodbreak 0
#  }
#  if {[regexp {^[0-9\.]*$} $w1] && \
#      [streqx $w2 mL L cc gal gal. deg deg. lb lb. IBU SRM °P °F]} {
#     set goodbreak 0
#  }

# Better still, don't wrap after ANY number...wrap the number, too.

   if {[regexp {^[0-9\.]*$} $w1]} { set goodbreak 0 }

   if {$goodbreak} { return [list $s1 $s2] }
   incr cut1 -2
   set s1 [string range $s1 0 $cut1]
   set s2 "$w1 $s2"

   return [list $s1 $s2]
}

proc fmt_core {n s} {
   set maxlen $n
   if {[string length $s] < $maxlen} { return $s }
   set s1 [string range $s 0 $maxlen]
   set cut [string last " " $s1]
   # prevent eternal loop, by just chopping words into pieces,
   # that are longer than maxlen:
   if {$cut == -1} {set cut $maxlen}
   set s1 [string range $s 0 $cut]
   incr cut 1
   set s2 [string range $s $cut end]
   regsub {  *$} $s1 {} s3 ; set s1 $s3
   regsub {^  *} $s2 {} s3 ; set s2 $s3
   set retval [list $s1 $s2]
# Before we return this, check for bad breakpoints (e.g., Mr/Mrs, after a
# number and before the unit (e.g., don't break between 20 mL), etc.

   set slist [check_return $s1 $s2]
   return $slist
}


proc fmt {n s} {
   set maxlen $n
   if {[string length $s] < $maxlen} { return $s }
   set finished 0
   set newstring ""
   while {!$finished} {
      set slist [fmt_core $maxlen $s]
      if {[llength $slist] == 2} {
         foreach {s1 s2} $slist { break }
      } else {
         set s1 [lindex $slist 0]
         set s2 ""
      }
      if {[string length $newstring] == 0} {
         set newstring $s1
      } else {
         set newstring "$newstring\n$s1"
      }
      if {[string length $s2]} {
         if {[string length $s2] < $maxlen} {
            return "$newstring\n$s2"
         } else {
            set s $s2
         }
      } else {
         return $newstring
      }
   }
}
