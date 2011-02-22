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
#         FILE:  INSTALL.pl
#
#        USAGE:  ./INSTALL.pl 
#
#  DESCRIPTION: This program connects to the GenBank FTP site to download all
#               the NT sequences, AA sequences, Genomes and GFF Files relevant
#               to the Microbial community, Generates the current files listing
#               Parses the GFF Files to generate tables, Formats all the seqs
#               using formatdb, edits the NT sequence FASTA preambles to include
#               the GI number, creates the MySQL tables and loads data into them
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Vivek Krishnakumar, <biohelp@cgb.indiana.edu>
#      COMPANY:  The Center for Genomics and Bioinformatics
#      VERSION:  1.0
#      CREATED:  10/17/08 11:57:32 EDT
#     REVISION:  ---
#===============================================================================

use strict;
#---------------------------------------------------------------------------
#  Load the required modules
#---------------------------------------------------------------------------
use Net::FTP;
use DBI;
use My::VarsBact ();
use vars qw(%bact);

*bact = \%My::VarsBact::bact;

print "Welcome to the Downloader. This will download all the sequences pertaining to Bacteria from GenBank.\n";

# Change to the appropriate directory
system "mkdir $bact{dataDir}";
chdir "$bact{dataDir}";

#---------------------------------------------------------------------------
#  Connect to the GenBank FTP site and generate the file listing
#---------------------------------------------------------------------------
# Open the FTP connection
my $ftp = Net::FTP->new($bact{ftpLink}, Debug => 0, Passive=>1, Timeout=>600)
or die "Error: $@";

# Login Credentials. Provide your email ID as anonymous login password
$ftp->login($bact{uname}, $bact{passwd})
or die "Error: ", $ftp->message;

# Change to the 'genomes' directory
$ftp->cwd($bact{directory})
or die "Error: ", $ftp->message;

# Save the Directory listing of the 'Bacteria' directory to an array
#my @directories = $ftp->ls
#or die "Error: ", $ftp->message;

# Sample set of organisms
my @directories = ("Caulobacter_crescentus",  "Jannaschia_CCS1",  "Maricaulis_maris_MCS10",  "Rhizobium_etli_CFN_42",  "Silicibacter_TM1040");

#---------------------------------------------------------------------------
#  Create the necessary directories to store the downloaded files
#---------------------------------------------------------------------------

system "rm -rf $bact{dataDir}/aaseqs/";
system "rm -rf $bact{dataDir}/genomes/";
system "rm -rf $bact{dataDir}/geneseqs/";
system "rm -rf $bact{dataDir}/gff_files/";
system "rm -rf $bact{dataDir}/listings";

system "mkdir $bact{dataDir}/aaseqs/";
system "mkdir $bact{dataDir}/genomes/";
system "mkdir $bact{dataDir}/geneseqs/";
system "mkdir $bact{dataDir}/gff_files/";
system "mkdir $bact{dataDir}/listings";

#---------------------------------------------------------------------------
#  Begin the download of files from the FTP &
#  Generate the file listings
#---------------------------------------------------------------------------

print "Commencing download of files and Generating listings...";

foreach my $dir(@directories) {
	next if ($dir =~ /README/ || $dir =~ /accessions/);

	$ftp->cwd($dir)
	or die "Error: ", $ftp->message;

	my @fna_listing = $ftp->ls('*.fna');
	my @gff_listing = $ftp->ls('*.gff');
	my @aaseq_listing = $ftp->ls('*.faa');
	my @seq_listing = $ftp->ls('*.ffn');

	my @currdir = $ftp->dir;
	
	my	$LISTING_file_name = $bact{dataDir}.'/listings/'.$dir.'.listing';		# output file name
	open  my $LISTING, '>', $LISTING_file_name
	or die  "$0 : failed to open  output file '$LISTING_file_name' : $!\n";

	foreach my $file(@fna_listing) {
		my ($f1, $f2, $f3) = 0;
		
		$ftp->get($file)
		or warn "Error: Could not retrieve file", $ftp->message;

		my ($fname) = $file =~ /^(\w+)\.fna$/;

		if (grep {$_ eq "$fname\.gff"} @gff_listing) {
			$ftp->get("$fname\.gff")
			or warn "Error: Could not retrieve file", $ftp->message;
			$f1 = 1;
		}

		if (grep {$_ eq "$fname\.faa"} @aaseq_listing) {
			$ftp->get("$fname\.faa")
			or warn "Error: Could not retrieve file", $ftp->message;
			$f2 = 1;
		}

		if (grep {$_ eq "$fname\.ffn"} @seq_listing) {
			$ftp->get("$fname\.ffn")
			or warn "Error: Could not retrieve file", $ftp->message;
			$f3 = 1;
		}

		foreach my $f(@currdir) {
			if( $f =~ /$fname/ ) {
				next unless($f =~ /gff/ || $f =~ /ffn/ || $f =~ /fna/ || $f =~ /faa/);

				chomp $f;
				print $LISTING "$f\n";
			}
		}
		
		system "mv $bact{dataDir}/$file $bact{dataDir}/genomes/$fname";
		system "mv $bact{dataDir}/$fname\.gff $bact{dataDir}/gff_files/$fname" if ( $f1 == 1 );
		system "mv $bact{dataDir}/$fname\.faa $bact{dataDir}/aaseqs/$fname" if ( $f2 == 1 );
		system "mv $bact{dataDir}/$fname\.ffn $bact{dataDir}/geneseqs/$fname" if ( $f3 == 1 );
	}
	close  $LISTING
	or warn "$0 : failed to close output file '$LISTING_file_name' : $!\n";
	$ftp->cwd("../");
}
$ftp->quit; ## Close the FTP connection

print "Done!\n";
#---------------------------------------------------------------------------
#  Run FormatDB on the downloaded sequences
#---------------------------------------------------------------------------

my @dirs = ("genomes", "aaseqs", "geneseqs");
print "Running formatDB on the downloaded files...\n";
foreach my $directory(@dirs) {
	next if( $directory =~ /gene/ );
	chdir "$bact{dataDir}/$directory";

	opendir DIR, "$bact{dataDir}/$directory";
	my @files = readdir DIR;
	closedir DIR;

	print "Formatting $directory....";
	foreach my $file(@files) {
		next if ($file =~ /\./ || $file =~ /backup/);
		system "formatdb -i $file -p F" if($directory =~ /gen/);
		system "formatdb -i $file -p T" if($directory =~ /aaseqs/);
	}
	print "Done!\n";
}

#---------------------------------------------------------------------------
#  Parse the GFF files and generate the data for the MySQL tables
#---------------------------------------------------------------------------

# Set the working directory
system("rm -rf $bact{dataDir}/tables");
system("mkdir $bact{dataDir}/tables");
chdir("$bact{dataDir}/tables");

# Read the directory and get a file listing
opendir(DIR, "$bact{dataDir}/gff_files") || die("Cannot open directory\n");
my @gff_files = readdir(DIR);
closedir(DIR);

open(MAIN, ">main.tab");
open(CHILD, ">child.tab");

print "Parsing the GFF files and generating the data for the MySQL tables...";
# Iterate through the files
foreach my $file(@gff_files) {
	# Open the file
	open(GFF, "$bact{dataDir}/gff_files/$file");
	my @gff = <GFF>;
	close(GFF);
	
	my ($pass, $track) = 0;
	
	my @coords;
	my($printInMain) = "";

	# Iterate through the file, line by line
	foreach my $line(@gff) {
		next unless ($line =~ /^$file/);

		$line =~ s/%20/\ /g;
		$line =~ s/%23/\#/g;
		$line =~ s/%27/\'/g;
		$line =~ s/%28/\(/g;
		$line =~ s/%29/\)/g;
		$line =~ s/%2B/\+/g;
		$line =~ s/%2C/\,/g;
		$line =~ s/%2F/\//g;
		$line =~ s/%3B/\;/g;
		$line =~ s/%3D/\=/g;
		$line =~ s/%5B/\[/g;
		$line =~ s/%5D/\]/g;
		$line =~ s/%5F/\_/g;
		$line =~ s/%7C/\|/g;

		my @Line = split /\t/, $line; # Split the line at tab spaces(\t)

		if ($Line[2]=~ /source/ && $Line[8] =~ /organism/) {	## Pick the line which has the word 'source' in it. From this line, we extract the organism name
			chomp $Line[8];
			my @split = split /;/, $Line[8];
		
			next if($split[0] =~ m/phage/i && $track > 0);

			chomp $Line[4];
			push @coords, $Line[4];

			if($track == 0) {
				my($orgname, $chromosome, $tax_id, $strain, $subStrain, $plasmid, $subSp) = "";

				foreach my $part(@split) {
					($orgname) = $part =~ /organism=(.*)/ if($part =~ /organism=/);
					($chromosome) = $part =~ /chromosome=(.*)/ if($part =~ /chromosome=/);
					($tax_id) = $part =~ /db_xref=taxon:(.*)/ if($part =~ /taxon:/);
					($strain) = $part =~ /strain=(.*)/ if($part =~ /^strain=/);
					($plasmid) = $part =~ /plasmid=(.*)/ if($part =~ /plasmid=/);
					($subStrain) = $part =~ /sub_strain=(.*)/ if($part =~ /^sub_strain=/);
					($subSp) = $part =~ /sub_species=(.*)/ if($part =~ /sub_species=/);
				}

				chomp $orgname;
				my $ORGNAME = "$orgname";

				if($subSp ne "") {
					$ORGNAME .= " subsp. $subSp";	
				}
				if($strain ne "") {
					unless($orgname =~ /$strain/) {
						$ORGNAME .= " str. $strain";
					}
				}
				if($subStrain ne "") {
					unless($orgname =~ /$subStrain/) {
						$ORGNAME .= " substr. $subStrain";
					}
				}

				if($Line[8] =~ /chromosome=/) {
					$printInMain = "$tax_id\t$file\t$ORGNAME chromosome $chromosome\t";
				} elsif($Line[8] =~ /plasmid=/) {
					$printInMain = "$tax_id\t$file\t$ORGNAME plasmid $plasmid\t";
				} else {
					$printInMain = "$tax_id\t$file\t$ORGNAME\t";
				}	
			}
			$track++;
		} # endif SOURCE

		if ($Line[2] =~ /CDS/) {	# Pick the line which has the word 'CDS' in it. From this line, we extract the locus and gene product.
			$pass++;
			if($pass == 1) {
				print MAIN $printInMain,"$coords[-1]\n";
			}

			chomp $Line[8];
			my @split = split /;/, $Line[8];

			my ($locus, $gi, $product, $geneid, $prot_accno);
			foreach my $part(@split) {
				($locus) = $part =~ /locus_tag=(.*)/ if($part =~ /locus_tag/);
				($gi) = $part =~ /db_xref=GI:(.*)/ if($part =~ /db_xref=GI:/);
				if($part =~ /note=/) {
					($product) = $part =~ /note=(.*)/;
				} elsif($part =~ /product=/) {
					($product) = $part =~ /product=(.*)/;
				}
				($geneid) = $part =~ /ID=.*:(.*)\:.*/ if($part =~ /ID=/);
				($prot_accno) = $part =~ /protein_id=(.*)/ if($part =~ /protein_id/); 
				$prot_accno =~ s/\.[0-9]//g;
			}

			# Print to output file (print only the appropriate columns)
			print CHILD "$file\t$prot_accno\t$gi\t$locus\t$geneid\t$Line[3]\t$Line[4]\t$Line[6]\t$product\n";
		} # endif CDS
	} # close foreach GFF file contents
}	# close foreach all GFF files

close MAIN;
close CHILD;

print "Done!\n";

#---------------------------------------------------------------------------
#  Create the MySQL Tables
#---------------------------------------------------------------------------

print "Connect to MySQL and create the necessary tables....";
my $dsn = "DBI:mysql:host=$bact{host};database=$bact{database}";
my $dbh = DBI->connect($dsn, $bact{dbuname}, $bact{dbpasswd})
or die "Cannot connect to server\n";

# If exists, drop and create the taxid_accno table
my $query = $dbh->prepare($bact{mainTbldrop});
$query->execute();

$query = $dbh->prepare($bact{mainTblcreate});
$query->execute();

# If exists, drop and create the genedetails table
$query = $dbh->prepare($bact{childTbldrop});
$query->execute();

$query = $dbh->prepare($bact{childTblcreate});
$query->execute();
print "Done!\n";

#---------------------------------------------------------------------------
#  Update the tables with parsed GFF data
#---------------------------------------------------------------------------

print "Updating the tables...";

# Update the taxid_accno table
$query = $dbh->prepare($bact{mainTblLoad});
$query->execute();

# Update the genedetails table
$query = $dbh->prepare($bact{childTblLoad});
$query->execute();
print "Done!\n";

#---------------------------------------------------------------------------
#  Modify the FASTA preambles of all NT sequences
#---------------------------------------------------------------------------
$query = $dbh->prepare($bact{getgeneids});

chdir "$bact{dataDir}/geneseqs";
system "rm -rf backup";
system "mkdir backup";

opendir DIR, "$bact{dataDir}/geneseqs";
my @gseq_files = readdir DIR;
closedir DIR;

print "Modifying FASTA preambles of all NT sequences and running FormatDB....";
foreach my $file(@gseq_files) {
	next if( $file =~ /nin/ || $file =~ /nhr/ || $file =~ /nsq/ || $file =~ /log/ || $file =~ /\./ || $file =~ /backup/ );

	open FILE, "$file";
	my @file = <FILE>;
	close FILE;
	
	my ($start,$end,$header);
	open OUTFILE, ">$file.mod";

	foreach my $line(@file) {
		chomp $line;
		if( $line =~ /^>/ ) {
			$query->execute($file);
			if( $line =~ /:c/ ) {
				($end, $start) = $line =~ /^>.*\|.*\|:c(.*)-(.*)$/;
			} else {
				($start, $end) = $line =~ /^>.*\|.*\|:(.*)-(.*)$/;
			}
			($header) = $line =~ /^>(.*)/;
			while(my @row = $query->fetchrow_array()) {
				my $End = $row[2] + 3;
				my $Start = $row[1] - 3;
				if( ($start == $row[1] && $end == $End) || ($start == $Start && $end == $row[2]) ) {
					print OUTFILE ">gi\|$row[0]\|$header\n";
					last;
				}
			}
		} else {
			print OUTFILE "$line\n";
		}
	}
	close OUTFILE;
	system "mv $file backup/";
	system "mv $file\.mod $file";
	
	system "formatdb -i $file -p F";
}
print "Done!\n";

#---------------------------------------------------------------------------
#  Create and update the table with NT sequences
#---------------------------------------------------------------------------

print "Create and update the NT sequences MySQL table...";
$query = $dbh->prepare($bact{ntSeqTbldrop});
$query->execute();

$query = $dbh->prepare($bact{ntSeqTblcreate});
$query->execute();

$query = $dbh->prepare($bact{ntSeqTblinsert});

chdir "$bact{dataDir}/geneseqs";

opendir DIR, "$bact{dataDir}/geneseqs";
my @dir = readdir DIR;
closedir DIR;

foreach my $file(@dir) {
	next if( $file =~ /nhr/ || $file =~ /nin/ || $file =~ /nsq/ || $file =~ /log/ || $file =~ /\./ || $file =~ /backup/ );

	open FILE, "$file";
	my @file = <FILE>;
	close FILE;

	my $track = 0;
	my ($geneid, $sequence);
	foreach my $line(@file) {
		if( $track == 1 && $line =~ /^>/ ) {
			$query->execute($geneid, $sequence);
			$track = 0;
		}
		chomp $line;
		($geneid) = $line =~ /^>.*\|(.*)\|.*\|.*\|/ if( $line =~ /^>/ );
		$track = 1 if( $line =~ /^>/ );
		$sequence = "" if( $line =~ /^>/ );
		$sequence .= "$line\n";
	}
	$query->execute($geneid, $sequence);
}
print "Done!\n";

#---------------------------------------------------------------------------
#  Create and update the table with AA sequences
#---------------------------------------------------------------------------

print "Create and update the AA sequences MySQL table...";
$query = $dbh->prepare($bact{aaSeqTbldrop});
$query->execute();

$query = $dbh->prepare($bact{aaSeqTblcreate});
$query->execute();

$query = $dbh->prepare($bact{aaSeqTblinsert});

chdir "$bact{dataDir}/aaseqs";

opendir DIR, "$bact{dataDir}/aaseqs";
@dir = readdir DIR;
closedir DIR;

foreach my $file(@dir) {
	next if( $file =~ /phr/ || $file =~ /pin/ || $file =~ /psq/ || $file =~ /log/ || $file =~ /\./ );

	open FILE, "$file";
	my @file = <FILE>;
	close FILE;

	my $track = 0;
	my ($protaccno, $sequence);
	foreach my $line(@file) {
		if( $track == 1 && $line =~ /^>/ ) {
			$query->execute($protaccno, $sequence);
			$track = 0;
		}
		($protaccno) = $line =~ /^>.*\|.*\|.*\|(.*)\.[0-9]\|/ if( $line =~ /^>/ );
		$track = 1 if( $line =~ /^>/ );
		$sequence = "" if( $line =~ /^>/ );
		$sequence .= $line;
	}
	$query->execute($protaccno, $sequence);
}
print "Done!\n";

$dbh->disconnect;

print "Thank you for using the installer!\n";

exit;

