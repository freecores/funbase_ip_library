# This is a Tcl script to create Quartus projects for both example designs in PCI Express
# The script will create both QSF and QPF files
#
load_package ::quartus::flow

set debug 0
set quartus_version 6.1
set stratix2gx 0
set stratix2gxl 0
set stratix2   0
set stratix3   0
set stratix4   0
set hardcopy4   0
set stratix4es   0
set arria2   0
set cyclone4   0
set stratixgx  0
set cyclone2   0
set hardcopy2   0
set clk250 0
set clk125 0
set clk62  0
set simpledma 1
set rate_matcher 1
set gen2 0
set rp 0
if { $argc != 11 } {
   puts "ERROR: $argv0 requires input arguments:"
   puts "          family         - a supported Altera device family"
   puts "                          \"Stratix GX\""
   puts "                          \"Stratix II\""
   puts "                          \"Stratix II GX\""
   puts "                          \"Stratix III\""
   puts "                          \"Stratix IV\""
   puts "                          \"HardCopy IV\""
   puts "                          \"Arria II\""
   puts "                          \"HardCopy II\""
   puts "                          \"Cyclone II\" (double quote the family name)"
   puts "          variation name - the name of this instance of the core"
   puts "          language       - verilog or vhdl (lower case only)"
   puts "          lanes          - # of lanes (1, 4, 8)"
   puts "          tlp clk freq   - frequency of backend except for x8 (62.5, 125)"
   puts "          lib            - path to the pci_express_compiler library"
   puts "          simple dma     - 1 - for simple DMA, 0 - for chained DMA"
   puts "          RM FIFO        - 1 - implement Rate Match FIFO, 0 - Disable Rate Matcher"
   puts "          Gen 2          - 1 - Gen2 capable, 0 - Gen1 only"
   exit
}
set family   [lindex $argv 0]
if {[string compare $family "Stratix II GX"] == 0} {
   set stratix2gx 1
} elseif {[string compare -nocase $family "Stratix II GX Lite"] == 0} {
   set stratix2gxl  1
  # modifying family to Arria GX
    set family "Arria GX"
} elseif {[string compare -nocase $family "Arria GX"] == 0} {
   set stratix2gxl  1
} elseif {[string compare -nocase $family "Stratix GX"] == 0} {
   set stratixgx  1
} elseif {[string match -nocase "Cyclone II*" $family] > 0} {
   set cyclone2   1
} elseif {[string match -nocase "Stratix II" $family] > 0} {
   set stratix2   1
} elseif {[string match -nocase "Stratix III" $family] > 0} {
   set stratix3   1
} elseif {[string match -nocase "Stratix IV ES" $family] > 0} {
   set stratix4es   1
   set family "Stratix IV"
} elseif {[string match -nocase "Stratix IV" $family] > 0} {
   set stratix4   1
} elseif {[string match -nocase "Hardcopy IV" $family] > 0} {
   set hardcopy4   1
} elseif {[string match -nocase "Arria II" $family] > 0} {
   set arria2   1
} elseif {[string match -nocase "Cyclone IV GX" $family] > 0} {
   set cyclone4   1
} elseif {[string match -nocase "HardCopy II" $family] > 0} {
   set hardcopy2   1
} else {
   puts "WARN: Illegal Device Family =>  Using Default family Stratix II"
   set stratix2   1
}
set var      [lindex $argv 1]
set language [lindex $argv 2]
set lanes    [lindex $argv 3]
set tlpclk   [lindex $argv 4]
set simpledma [lindex $argv 6]
set rate_matcher [lindex $argv 7]
set gen2 [lindex $argv 8]
set rp [lindex $argv 9]
set ast64b [lindex $argv 10]

if {$lanes == 8} {
   set clk250 1
} elseif {$tlpclk == 125} {
   set clk125 1
} elseif {$tlpclk == 62.5} {
   set clk62  1
}
set lib      [lindex $argv 5]
if {[string compare $language "verilog"] == 0} {
   set ext v
   set file_type VERILOG_FILE
} else {
   set ext vhd
   set file_type VHDL_FILE
}
# Create New Quartus Project
if { $rp == 0 }  {
    if { $simpledma == 1 } {
	project_new $var\_example_top -overwrite
    } else {
	project_new $var\_example_chaining_top -overwrite
    }
} else {
    project_new $var\_example_rp_top -overwrite
}

# Set Quartus Global Project Assignments
set_global_assignment -name FAMILY \"$family\"
if { $rp == 0 }  {
    if { $simpledma == 1 } {
	set_global_assignment -name TOP_LEVEL_ENTITY $var\_example_top
    } else {
	set_global_assignment -name TOP_LEVEL_ENTITY $var\_example_chaining_top
    }
} else {
    set_global_assignment -name TOP_LEVEL_ENTITY $var\_example_rp_top
}
set_global_assignment -name USER_LIBRARIES $lib\;../..\;../common/incremental_compile_module
# Compilation Switches Based on Family, Link Width, Clock Freq
# SGX, CII or CIII and SIIGX Lite x1 and x4 at 125Mhz
# SII, SIII, SIIGX x8
if {($stratixgx || $cyclone2 || $stratix2gxl) ||   
    (($stratix2 || $stratix2gx || $gen2 || $ast64b ) && ($lanes == 8)) ||
    (($lanes == 4) && ($gen2))} {
   set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
   set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
   set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
}
if {0} {
   set_global_assignment -name PHYSICAL_SYNTHESIS_ASYNCHRONOUS_SIGNAL_PIPELINING ON
}
if {$stratix2gx || $stratix2gxl || 
    $stratix2 } {
    set_instance_assignment -name GLOBAL_SIGNAL \"GLOBAL_CLOCK\" -to \*coreclk\*
    set_global_assignment -name STRATIXII_OPTIMIZATION_TECHNIQUE SPEED
}
if {$stratixgx} {
   set_global_assignment -name STRATIX_OPTIMIZATION_TECHNIQUE SPEED
}
if {$cyclone2} {
   set_global_assignment -name CYCLONEII_OPTIMIZATION_TECHNIQUE SPEED
}

if {$hardcopy2} {
   set_global_assignment -name OPTIMIZE_FAST_CORNER_TIMING ON
}

if {($stratix4 || $stratix4es || $hardcopy4) && 
    ((($lanes == 8) && ($gen2 || $ast64b)) || (($lanes == 4) && ($gen2)))
} {
   set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
   set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 2
    # For S4GX ES silicon fix
    if {$stratix4es} {
	set_instance_assignment -name GLOBAL_SIGNAL \"GLOBAL_CLOCK\" -to \*wire_central_clk_div\*_coreclkout
    }
  
}

# Turn on multi-corner fitter constraint for A2 and TGX
if {($stratix4 || $stratix4es || $arria2 || $hardcopy4)} {
    set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
}

# Force Auto device to pick bigger device
if {$arria2} {
    set_global_assignment -name DEVICE EP2AGX125EF35C4
}

if {$cyclone4} {
    set_global_assignment -name DEVICE EP4CGX22CF19C6
}

if {$hardcopy4} {
    set_global_assignment -name DEVICE HC4GX15LF780
}

# pull in IO timing constaint tcl script
if [ file exists $var\_example_top.tcl ] {
    source $var\_example_top.tcl
}


# turn on Clock latency for TAN
set_global_assignment -name ENABLE_CLOCK_LATENCY ON
set_global_assignment -name ENABLE_RECOVERY_REMOVAL_ANALYSIS ON
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"

# set reference to common SDC file
set_global_assignment -name SDC_FILE ../../$var\.sdc\n

project_close


# Print the created QSF file
if {$debug} {
   set file [open ./$var\_example_top.qsf]
   puts "\nDEBUG:: The created QSF file:"
   while {[gets $file line] >= 0} {
      puts $line
   }
   close $file
   puts "stratix2    = $stratix2"
   puts "stratix2gx  = $stratix2gx"
   puts "stratix2gxl = $stratix2gxl"
   puts "stratixgx   = $stratixgx"
   puts "cyclone2    = $cyclone2"
   puts "clk250 = $clk250"
   puts "clk125 = $clk125"
   puts "clk62  = $clk62"
}
