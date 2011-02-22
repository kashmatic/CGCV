#!/usr/bin/perl 
#########################################################
### Copyright 2008 The Trustees of Indiana University
###
### Licensed under the Apache License,  Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###      http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing,  software
### distributed under the License is distributed on an "AS IS" BASIS, 
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
##########################################################

#===============================================================================
#
#         FILE:  splitaaseqs.pl
#
#        USAGE:  ./splitaaseqs.pl 
#
#  DESCRIPTION:  Program that splits the AA sequence files into many parts - each
#                part corresponding to a particular chromosome of an organism
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Vivek Krishnakumar , <biohelp@cgb.indiana.edu>
#      COMPANY:  The Center for Genomics and Bioinformatics
#      VERSION:  1.0
#      CREATED:  11/11/08 19:24:38 EST
#     REVISION:  ---
#===============================================================================

use warnings;
use My::Vars ();
use vars qw(%euk);

*euk = \%My::Vars::euk;

opendir(DIR, "$euk{dataDir}/aaseqs");
my @files = readdir(DIR);
closedir(DIR);

system("mkdir $euk{dataDir}/aaseqs/backup");
chdir("$euk{dataDir}/aaseqs");

my @handles;
foreach my $file(@files) {
	next if ($file =~ /\./);
	open(FILE, "$file");
	print "$file\n";

	@handles = ();

	$/='>';
	while(<FILE>) {
		next unless (/chromosome/);

		s/>$//;
		my ($chrno) = $_ =~ /^\S+\s\S+:\S+\s\S+:\S+\:(\S+):\d+:\d+:\S+\sgene:/;
		my $sequence = ">$_";
		my $outputfile = $file.$chrno;

		if(grep{$_ eq $outputfile} @handles) {
		} else {
			open("$outputfile", ">>$outputfile");
			push(@handles, $outputfile);
		}
		
		print $outputfile "$sequence";
	}
	close(FILE);

	foreach my $handle(@handles) {
		close($handle) or die;
	}

	system("mv $file backup/");
}

exit;
