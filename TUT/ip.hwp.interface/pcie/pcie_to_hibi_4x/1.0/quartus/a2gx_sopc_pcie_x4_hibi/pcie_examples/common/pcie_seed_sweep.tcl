#-----------------------------------------------------------------------------
#Copyright (C) 1991-2008 Altera Corporation
#Your use of Altera Corporation's design tools, logic functions
#and other software and tools, and its AMPP partner logic
#functions, and any output files from any of the foregoing
#(including device programming or simulation files), and any
#associated documentation or information are expressly subject
#to the terms and conditions of the Altera Program License
#Subscription Agreement, Altera MegaCore Function License
#Agreement, or other applicable license agreement, including,
#without limitation, that your use is for the sole purpose of
#programming logic devices manufactured by Altera and sold by
#Altera or its authorized distributors.  Please refer to the
#applicable agreement for further details.


#--------------------------------------------------------------#
#
# Load TCL package
#
load_package report
load_package flow

#--------------------------------------------------------------#
#
# pcie_seed_sweep.tcl is a Quartus II tcl script used by the
# PCI Express IP advisor.
#
# This script performs the following  :
#
#   1. Open the Quartus II <project>
#   2. Increment the Quartus II seed value
#   3. Compile the Quartus II <project>
#   4. Retrieve fmax value for <clock_name>.
#   5. If fmax is less than <required_fmax> go to to step 2. else end.
#
# Input argument section
#
#  quartus_sh -t pcie_seed_sweep.tcl <project> <revision>
#                                       <required_fmax> <clock_name>
#                                            <user_lib>
#
#     <project>      : Quartus II project name  - required argument
#     <revision>     : Quartus II revision name - optional argument
#     <required_fmax>: Required Fmax (MHz)      - optional argument
#     <clock_name>   : Clock name               - optional argument
#     <user_lib>     : User library             - optional argument
#

# Input project name
puts "+---------------------------------------------------------------+"
puts "| Running pcie_seed_sweep.tcl                                   |"
puts "+---------------------------------------------------------------+"
set project_name  [lindex $quartus(args) 0]
if { [ string eq "" $project_name] } {
   puts "| tcl:Invalid first argument:                                   |"
   puts "|                                                               |"
   puts "|  quartus_sh -t pcie_seed_sweep.tcl <project>  <revision>      |"
   puts "|                                     <required_fmax> <user_lib>|"
   puts "|                                                               |"
   puts "|     <project>      : Quartus II project name  - required      |"
   puts "|     <revision>     : Quartus II revision name - optional      |"
   puts "|     <required_fmax>: Required Fmax (MHz)      - optional      |"
   puts "|     <clock_name>   : Clock name for TimeQuest - optional      |"
   puts "|     <user_lib>     : User library             - optional      |"
   puts "|                                                               |"
   puts "+---------------------------------------------------------------+"
   if { [ string eq "quartus_sh" $quartus(nameofexecutable) ] } {
      puts "oaw_set_icon_type_internal {e}"
      puts "oaw_add_header_internal {{Status : FAIL}}"
      puts "oaw_add_row_internal {{Invalid project name first argument }}"
      exit 0
   } else {
      return -1
   }
}
puts "| Quartus project                 : $project_name"

# Required Fmax
set RequiredFmax  [lindex $quartus(args) 2]
if { [ string eq "" $RequiredFmax] } {
   set RequiredFmax 125
}

# Search for the name PCIeClockNameContent in the Fmax Summary panel
set PCIeClockNameContent  [lindex $quartus(args) 3]
if { [ string eq "" $PCIeClockNameContent] } {
   set PCIeClockNameContent "*|serdes|*"
} elseif { [ string eq "TCL_IGNORE_ARG_CLOCK_NAME_CONTENT" $PCIeClockNameContent] } {
   set PCIeClockNameContent "*|serdes|*"
} else {
   set PCIeClockNameContent "*$PCIeClockNameContent*"
}

# User Library
set USER_LIBRARIES     [lindex $quartus(args) 4]

#--------------------------------------------------------------#
#
# Global variables section
#
# $MaxSeed set the maximum number of seed to run
# when $MaxSeed = -1; infinite loop keep running sweep
set MaxSeed 5
puts "| Maximum number of seeds         : $MaxSeed"

# $QtEffort
#     0 : Fast compilation
#     1 : Medium compilation
#     2 : Long compilation
set QtEffort 0
puts "| Quartus II Compilation effort   : $QtEffort"


# Preserve initial Seed
# When set use the SEED in the existing QSF as a starting seed
# else start from SEED=0
set PreserveInitialSeed 1

#--------------------------------------------------------------#
#
# Open Quartus II project
#
if { [ project_exists $project_name ]  } {
   project_open $project_name
   # set user library
   if { ![ string eq "" $USER_LIBRARIES] } {
      if { ![ string eq "NO_LIB" $USER_LIBRARIES] } {
         puts "| Updating user library : $USER_LIBRARIES"
         set_global_assignment -name USER_LIBRARIES "$USER_LIBRARIES"
      }
   }
   puts "+---------------------------------------------------------------+"
} else {
   puts "| tcl:Unable to open Quartus II project $project_name"
   puts "+---------------------------------------------------------------+"
   if { [ string eq "quartus_sh" $quartus(nameofexecutable) ] } {
      exit 0
      } else {
         return -1
      }
}

#--------------------------------------------------------------#
#
# Quartus II compilation seed sweeping
#
set QtSeed 0
set QtLoop 1
set ActualFmax 0
set rpt_ext ".pcie_sweep.rpt"
set PcieRpt $project_name$rpt_ext
set GetFmax 0
set fileId [ open $PcieRpt "w" ]

puts $fileId " Copyright (C) 1991-2008 Altera Corporation"
puts $fileId " Your use of Altera Corporation's design tools, logic functions "
puts $fileId " and other software and tools, and its AMPP partner logic "
puts $fileId " functions, and any output files from any of the foregoing "
puts $fileId " (including device programming or simulation files), and any "
puts $fileId " associated documentation or information are expressly subject "
puts $fileId " to the terms and conditions of the Altera Program License "
puts $fileId " Subscription Agreement, Altera MegaCore Function License "
puts $fileId " Agreement, or other applicable license agreement, including, "
puts $fileId " without limitation, that your use is for the sole purpose of "
puts $fileId " programming logic devices manufactured by Altera and sold by "
puts $fileId " Altera or its authorized distributors.  Please refer to the "
puts $fileId " applicable agreement for further details."
puts $fileId " "
puts $fileId " "
puts $fileId " "

puts $fileId "+---------------------------------------------------------------+"
puts $fileId "; Seed sweep summary                                            ;"
puts $fileId "+---------------------------------------------------------------+"
puts $fileId "; Quartus project $project_name                                  ;"

if {$MaxSeed == -1 } {
   set QtEffort 2
}

set OriSeed [ get_global_assignment -name SEED ]
if { $PreserveInitialSeed == 0 } {
   set OriSeed 0
}

while { $QtLoop > 0 } {
   #--------------------------------------------------------------#
   #
   # Update project assignments
   #
   set SEEDQSF [ expr $OriSeed + $QtSeed ]
   set_global_assignment -name SEED $SEEDQSF
   set_global_assignment -name USE_TIMEQUEST_TIMING_ANALYZER ON
   set_global_assignment -name SMART_RECOMPILE ON
   set_global_assignment -name STRATIXII_OPTIMIZATION_TECHNIQUE SPEED

   if { $QtEffort == 1 } {
      set_global_assignment -name FITTER_EFFORT "AUTO FIT"
      set_global_assignment -name PHYSICAL_SYNTHESIS_EFFORT NORMAL
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
      set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
      set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
      set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA ON
      set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
      if {$QtSeed == 0 } {
         puts $fileId "+---------------------------------------------------------------+"
         puts $fileId "; FITTER_EFFORT  AUTO FIT                                       ;"
         puts $fileId "; PHYSICAL_SYNTHESIS_EFFORT NORMAL                              ;"
      }
   } elseif { $QtEffort == 2 } {
      set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
      set_global_assignment -name PHYSICAL_SYNTHESIS_EFFORT EXTRA
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_ASYNCHRONOUS_SIGNAL_PIPELINING ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA ON
      set_global_assignment -name PHYSICAL_SYNTHESIS_MAP_LOGIC_TO_MEMORY_FOR_AREA ON
      set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
      set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
      set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
      set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
      if {$QtSeed == 0 } {
         puts $fileId "+---------------------------------------------------------------+"
         puts $fileId "; FITTER_EFFORT  STANDARD FIT                                   ;"
         puts $fileId "; PHYSICAL_SYNTHESIS_EFFORT EXTRA                               ;"
      }
   } else {
      set_global_assignment -name FITTER_EFFORT "FAST FIT"
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC OFF
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION OFF
      set_global_assignment -name PHYSICAL_SYNTHESIS_ASYNCHRONOUS_SIGNAL_PIPELINING OFF
      set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING OFF
      set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA OFF
      set_global_assignment -name PHYSICAL_SYNTHESIS_MAP_LOGIC_TO_MEMORY_FOR_AREA OFF
      if {$QtSeed == 0 } {
         puts $fileId "+---------------------------------------------------------------+"
         puts $fileId "; FITTER_EFFORT  FAST FIT                                       ;"
         puts $fileId "; PHYSICAL_SYNTHESIS_EFFORT OFF                                 ;"
      }
   }

   #--------------------------------------------------------------#
   #
   # Run Quartus II full compilation
   #
   if { [ catch { execute_flow -compile } result ] } {
      puts $fileId ";  Error: Quartus II Analysis & Synthesis was unsuccessful      ;"
      puts $fileId "+---------------------------------------------------------------+"
      close $fileId
      puts " TCL:ERROR : Compiling project $project_name"
      if { [ string eq "quartus_sh" $quartus(nameofexecutable) ] } {
         puts "oaw_set_icon_type_internal {e}"
         puts "oaw_add_header_internal {{Status}}"
         puts "oaw_add_row_internal {{TCL:ERROR : Compiling project $project_name}}"
         exit 0
      } else {
         return -1
      }
  }

#--------------------------------------------------------------#
#
# Retrieve Fmax from the TimeQuest Report Panel
#
set check_timings 1
#--------------------------------------------------------------#
#
# Check negative Slack in TimeQuest Report panel
#
load_report $project_name
set TIMING_FAILURE ""
foreach panel [get_report_panel_names] {
   set id      [get_report_panel_id $panel]
   set row_cnt [get_number_of_rows -id $id]
   if {[string match "*Setup Summary" $panel] == 1 && $check_timings ==1} {
      for { set r 1 } {$r<$row_cnt} {incr r} {
         set c0 [get_report_panel_data -id $id -row $r -col 0]
         set c1 [get_report_panel_data -id $id -row $r -col 1]
         if { $c1<0 } {
            set TIMING_FAILURE "Setup Summary panel : clock $c0 --> $c1"
            set check_timings 0
         }
      }
   }
   if {[string match "*Hold Summary" $panel] == 1 && $check_timings==1} {
      for { set r 1 } {$r<$row_cnt} {incr r} {
         set c0 [get_report_panel_data -id $id -row $r -col 0]
         set c1 [get_report_panel_data -id $id -row $r -col 1]
         if { $c1<0 } {
            set TIMING_FAILURE "Hold Summary panel : clock $c0 --> $c1"
            set check_timings 0
         }
      }
   }
   if {[string match "*Recovery Summary" $panel] == 1 && $check_timings==1} {
      for { set r 1 } {$r<$row_cnt} {incr r} {
         set c0 [get_report_panel_data -id $id -row $r -col 0]
         set c1 [get_report_panel_data -id $id -row $r -col 1]
         if { $c1<0 } {
            set TIMING_FAILURE "Recovery Summary panel : clock $c0 --> $c1"
            set check_timings 0
         }
      }
   }
   if {[string match "*Removal Summary" $panel] == 1 && $check_timings==1} {
      for { set r 1 } {$r<$row_cnt} {incr r} {
         set c0 [get_report_panel_data -id $id -row $r -col 0]
         set c1 [get_report_panel_data -id $id -row $r -col 1]
         if { $c1<0 } {
            set TIMING_FAILURE "Removal Summary panel : clock $c0 --> $c1"
            set check_timings 0
         }
      }
   }
}

unload_report $project_name

   #--------------------------------------------------------------#
   #
   # Check if achieved required Fmax
   #
   if { $check_timings == 1 } {
      set GetFmax 1
      set QtLoop 0
   }

   if { $check_timings==1 } {
      # return the seed sweeping loop
      set QtLoop 0
   } else {
      set MaxSeedEffort $MaxSeed
      if { $QtEffort==0 } {
         set MaxSeedEffort 1
      }
      puts "   Info: TimeQuest timings are not met "
      set QtSeed [expr $QtSeed + 1]
      if { $MaxSeed==-1 || $MaxSeedEffort>$QtSeed  }  {
         puts "   Info: starting next iteration "
      } elseif { $QtEffort ==0 } {
         set QtEffort 0
         set QtSeed 0
      } elseif { $QtEffort==1 } {
         set QtEffort 2
         set QtSeed 0
      } else {
         # tried all seeds, all qt effort, return the seed sweeping loop
         set QtLoop 0
      }
   }
}

if {$GetFmax == 1} {
   puts $fileId "; Passed SDC Timing requirements                                ;"
   puts $fileId "+---------------------------------------------------------------+"
   puts "oaw_set_icon_type_internal {c}"
   puts "oaw_add_header_internal {{Status : PASSED}}"
   puts "oaw_add_row_internal {{Check report file $PcieRpt}}"
} else {
   puts $fileId "; Failed SDC Timing requirements                                ;"
   puts $fileId "; $TIMING_FAILURE                                               ;"
   puts $fileId "+---------------------------------------------------------------+"
   puts "oaw_set_icon_type_internal {w}"
   puts "oaw_add_header_internal {{Status : FAIL}}"
   puts "oaw_add_row_internal {{$TIMING_FAILURE}}"
   puts "oaw_add_row_internal {{Check report file $PcieRpt}}"
}
close $fileId
project_close

#--------------------------------------------------------------#
#
# Result Display
#
puts "+---------------------------------------------------------------+"
puts " "
puts " PCI Express QII seed sweep compilation report $PcieRpt "
puts " "
set fsize [ file size $PcieRpt ]
set fp [ open $PcieRpt r ]
set data [read $fp $fsize]
puts $data
close $fp
puts " "
puts " "
return 0
