#!/usr/bin/env tclsh

package require Tcl 8.6
package require cmdline 1.5
package require term::ansi::send 0.1
package require term::ansi::code::attr 0.1

set version 0.0.1
set homepage {https://www.github.com/nat-418/hogs}

proc parse {cmd all} {
	set fmt [list %-42s %-6s %-16s %-6s]
	set result [exec {*}$cmd]
	set header_len 0
	set netid_len 7
	set addr_len 7
	set port_len 4
	set name_len 7
	set PID_len  3
	set i 0
	set result [lsort [lmap line [split $result \n] {
		# skip header line
		incr i
		if {$i eq 1} {
			set header_len [llength $line]
			continue
		}

		# parse ss output
		if {$header_len eq 7} {
			set netid {}
			lassign $line _ _ _ local _ process
		} elseif {$header_len eq 8} {
			lassign $line netid _ _ _ local _ process
		} else {
			puts stderr {Error: cannot parse output.}
			exit 1
		}
		set sepidx [string last : $local]
		set addr [string range $local 0 [expr $sepidx - 1]]
		set port [string range $local [expr $sepidx + 1] end]
		lassign [split $process ,] name PID _
		set name [lindex [split $name \"] 1]
		set PID [lindex [split $PID =] end]

		if {$all || $name ne {} && $PID ne {}} {
			# measure for final formatting
			set this_netid_len [string length $netid]
			set this_addr_len [string length $addr]
			set this_port_len [string length $port]
			set this_name_len [string length $name]
			set this_PID_len [string length $PID]
			if {$this_netid_len > $netid_len} {set addr_len $netid_len}
			if {$this_addr_len > $addr_len} {set addr_len $this_addr_len}
			if {$this_port_len > $port_len} {set port_len $this_port_len}
			if {$this_name_len > $name_len} {set name_len $this_name_len}
			if {$this_PID_len > $PID_len} {set PID_len $this_PID_len}
			# build result list
			if {$netid eq {}} {
			  set line [list $addr $port $name $PID]
		        } else {
			  set line [list $netid $addr $port $name $PID]
			}
		} else {
			# These will be discarded later
			set line {}
		}

	}]]

	set result [lsearch -all -inline -not -exact $result {}]
	if {[llength $result] eq 0} {exit 0}

	if {$header_len eq 7} {
		set fmt "%-${addr_len}s  %-${port_len}s  %-${name_len}s  %-${PID_len}s"
	        set headers [format $fmt Address Port Process PID]
	} elseif {$header_len eq 8} {
		set fmt "%-${netid_len}s  %-${addr_len}s  %-${port_len}s  %-${name_len}s  %-${PID_len}s"
	        set headers [format $fmt Network Address Port Process PID]
	} else {
		puts stderr {Error: cannot format output.}
		exit 1
	}

	# print result
	set toTTY [dict exists [fconfigure stdout] -mode]
	if $toTTY {
		::term::ansi::send::sda_fgyellow
		::term::ansi::send::sda_italic
		puts stdout $headers
		::term::ansi::send::sda_reset
	}
	foreach line $result {
		puts stdout [format $fmt {*}$line]
	}
}

proc cli {} {
	global argv homepage version
	set options {
		{a.secret        {Show all results, see PERMISSIONS}}
		{all             {Show all results, see PERMISSIONS}}
		{4.secret        {Show IPv4 addresses}}
		{ipv4            {Show IPv4 addresses}}
		{6.secret        {Show IPv6 addresses}}
		{ipv6            {Show IPv6 addresses}}
		{t.secret        {Show TCP network}}
		{tcp             {Show TCP network}}
		{u.secret        {Show UDP network}}
		{udp             {Show UDP network}}
		{i.arg.secret {} {Lookup a given IP address}}
		{ip.arg       {} {Lookup a given IP address}}
		{p.arg.secret {} {Lookup a given port number}}
		{port.arg     {} {Lookup a given port number}}
		{v.secret        {Print version number}}
		{version         {Print version number}}
	}
	set usage "v$version - Find the processes hogging your ports."
	append usage "\n\nUSAGE: hogs \[options]\n\nOPTIONS:"

	try {
	    array set params [::cmdline::getoptions argv $options $usage]
	} trap {CMDLINE USAGE} {msg o} {
	    puts stderr [regsub -all <> $msg {}]
	    puts stderr {PERMISSIONS:}
	    puts stderr { Usually, an empty process name or PID means that the user does not have}
	    puts stderr { sufficient permissions to access that information. The most common cause}
	    puts stderr { of this is when a process is spawned by root or init. By default, hogs}
	    puts stderr { does not show results with an empty process name or PID.}
	    puts stderr "\nTo report bugs or view source code, see $homepage."
	    exit 1
	}

	set cmd {ss -lpn}

	if {$params(tcp) eq {}} {set params(tcp) $params(t)}
	if {$params(udp) eq {}} {set params(udp) $params(u)}
	switch "$params(tcp) $params(udp)" {
		{1 0} {append cmd t}
		{0 1} {append cmd u}
		default {append cmd tu}
	}

	if {$params(ipv4) eq {}} {set params(ipv4) $params(4)}
	if {$params(ipv6) eq {}} {set params(ipv6) $params(6)}
	switch "$params(ipv4) $params(ipv6)" {
		{1 0} {append cmd 4}
		{0 1} {append cmd 6}
	}


	if {$params(ip) eq {}} {set params(ip) $params(i)}
	if {$params(ip) ne {}} {
		lappend cmd "src $params(ip)"
	}

	if {$params(port) eq {}} {set params(port) $params(p)}
	if {$params(port) ne {}} {
		lappend cmd "sport = :$params(port)"
	}
	
	if {$params(version) || $params(v)} {
		puts stdout $version
		exit 0
	}

	parse $cmd [expr {$params(all) || $params(a)}]
}

if {[catch {exec ss}]} {
	puts stderr {Error: ss not available.}
	exit 0
}

cli

