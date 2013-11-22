#!/usr/bin/perl

#------------------------------------------------------------------------------ 
# VHDL inst
#	by Jeremy Webb
#	
#	Rev 1.1, November 3, 2004
#
#	This utility is intended to make instantiation in VHDL easier using
#	a good editor, such as VI.
#	
#	As long as you set the top line to correctly point to your perl binary,
#	and place this script in a directory in your path, you can invoke it from VI.
#	Simply use the !! command and call this script with the filename you wish
#	to instantiate.  
#		!! vhdl_inst adder.vhd
#	The script will retrieve the module definition from the file you specify and
#	provide the instantiation for you in the current file at the cursor position.
#
#	For instance, if adder.vhd contains the following definition:
#	
#		entity adder is
#		        port (
#		              a : in std_logic;
#		              b : in std_logic;
#		              sum : out std_logic;
#		              carry : out std_logic
#		              );
#		end adder;
#
#       Note that the closing ); can be placed either on the next line after the 
#       last port or on the same line as the last port in the entity declaration.
#       However, I would suggest that you don't append the ); on the end of last
#       line, otherwise you will end up with the two of them. One at the end of 
#       the last line, and another on the beginning of the next line.
#
#	Then this is what the script will insert in your editor for you:
#
#		unpack : unpack_pci_data
#                       port map (
#                       	  a => a,
#	                          b => b,
#	                          sum => sum,
#	                          carry => carry
#	                          );
#
#	The keyword "entity" must be left justified in the vhdl file you are 
#	instantiating to work.
#
#	Revision History:
#		1.0	10/24/2004	Initial release
#		1.1     11/2/2004       Re-wrote for VHDL.
#
#	Please report bugs, errors, etc.
#------------------------------------------------------------------------------

#	Retrieve command line argument
#
use strict;
my $file = $ARGV[0];

#	Read in the target file into an array of lines
open(inF, $file) or dienice ("file open failed");
my @data = <inF>;
close(inF);

#	Strip newlines
foreach my $i (@data) {
	chomp($i);
	$i =~ s/--.*//;		#strip any trailing -- comments
}

#	initialize counters
my $lines = scalar(@data);		#number of lines in file
my $line = 0;
my $name;
my $entfound = -1;

#	find 'entity' left justified in file
for ($line = 0; $line < $lines; $line++) {
	if ($data[$line] =~ m/^entity\s*(\w+)\s*is/) {
		$entfound = $line;
		$name = $1;
		$line = $lines;	#break out of loop
	}
}

# find 'end $file', so that when we're searching for ports we don't include local signals.
my $entendfound = 0;
for ($line = 0; $line < $lines; $line++) {
	if ($data[$line] =~ m/^end\s*(entity)?\s*$name/) {
		$entendfound = $line;
		$line = $lines;	#break out of loop
	}
}

#	if we didn't find 'entity' then quit
if ($entfound == -1) {
	print("Unable to instantiate-no occurance of 'entity' left justified in file.\n");
	exit;
}

#find opening paren for port list
$entendfound = $entendfound + 1;
my $gfound = -1;
my $pfound = -1;

for ($line = $entfound; $line < $entendfound; $line++) { #start looking from where we found module
        if ($data[$line] =~ m/generic\s*\(/) {
		$gfound = $line;
	}
        if ($data[$line] =~ m/port\s*\(/) {
		$pfound = $line;
                $data[$line] =~ s/.*\(//;	#consume up to first paren
		$line = $entendfound;			#break out of loop
	}
}

#	if couldn't find '(', exit
if ($pfound == -1) {
	print("Unable to instantiate-no occurance of '(' after module keyword.\n");
	exit;
}

#collect generic names
my @generics;
if ($gfound!=-1) {
	for ($line = $gfound; $line < $pfound; $line++) {
		if ($data[$line] =~ /\s+(\w+)\s+:/) {
			push @generics, $1;
		}
	}
}

#collect port names
my @ports;

for ($line = $pfound; $line < $entendfound; $line++) {
	#   next if not $data[$line] =~ /:.*;/;
	if ($data[$line] =~ /\s+(\w+)\s+:/)
	{
		push @ports, $1;
	}
}

#print out instantiation
#$file =~ s/\.vhd$//;			#strip .vhd from filename
#print "$file : $file\n";
print "i_$name : $name\n";

if ($gfound!=-1) {
	print "generic map (";
	my @genericlines;
	my $maxlength=0;
	foreach (@generics) {
		if (length > $maxlength) {
			$maxlength = length
		}
	}
	my $padspaces;
	foreach my $i (@generics) {
		$padspaces = $maxlength-length($i);
		push @genericlines, "$i "." "x$padspaces."=> $i";
	}
	my $out= join ",\n\t", @genericlines;

	print ("\n\t$out\n)\n");
}

print "port map (";
my @portlines;
my $maxlength=0;
foreach (@ports) {
	if (length > $maxlength) {
		$maxlength = length
	}
}
my $padspaces;
foreach my $i (@ports) {
	$padspaces = $maxlength-length($i);
	push @portlines, "$i "." "x$padspaces."=> $i";
}

my $out= join ",\n\t", @portlines;

print ("\n\t$out\n);\n\n");

exit;

#------------------------------------------------------------------------------ 
# Generic Error and Exit routine 
#------------------------------------------------------------------------------

sub dienice {
	my($errmsg) = @_;
	print"$errmsg\n";
	exit;
}


