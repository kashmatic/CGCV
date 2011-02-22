#!/usr/bin/perl
#########################################################
## Copyright 2008 The Trustees of Indiana University
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#########################################################

#===============================================================================
#
#         FILE:  UPDATE.pl
#
#        USAGE:  ./UPDATE.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Vivek Krishnakumar , <biohelp@cgb.indiana.edu>
#      COMPANY:  The Center for Genomics and Bioinformatics
#      VERSION:  1.0
#      CREATED:  11/05/08 19:48:06 EST
#     REVISION:  ---
#===============================================================================

use strict;
use Net::FTP;
use DBI;

use My::VarsEuk ();
use vars qw(%euk);

*euk = \%My::VarsEuk::euk;

#---------------------------------------------------------------------------
#  Connect to ENSEMBL and generate thelistings
#---------------------------------------------------------------------------
## Open the FTP connection
my $ftp = Net::FTP->new($euk{ftpLink}, Debug => 0, Passive=>1)
or die "Error: $@";

## Login Credentials. Provide your email ID as anonymous login password
$ftp->login($euk{uname}, $euk{passwd})
or die "Error: ", $ftp->message;

system("rm -rf $euk{dataDir}/tmpListings");
system("mkdir $euk{dataDir}/tmpListings");
chdir("$euk{dataDir}/tmpListings/");

my @eukaryotes = ("Homo_sapiens", "Mus_musculus");

foreach my $eukaryote(@eukaryotes) {
	print "$eukaryote\n";
	my $folder = lc $eukaryote;

	$ftp->cwd($euk{directory}.'fasta/'.$folder.'/dna/');

	my @listing = $ftp->dir
	or die "Error: ", $ftp->message;

	my	$LISTING_file_name = $eukaryote.'.listing';		# output file name

		open  my $LISTING, '>', $LISTING_file_name
		or die  "$0 : failed to open  output file '$LISTING_file_name' : $!\n";

	foreach my $file(@listing) {
		next unless ($file =~ /dna\.chromosome/ && $file =~ /\.fa\.gz$/);
		next if($file =~ /c[0-9]*_\w+/ || $file =~ /dna_rm/ || $file =~ /nonchromo/ || $file =~ /toplevel/ || $file =~ /README/ || $file =~ /Het/ || $file =~ /extra/);
		chomp $file;

		print $LISTING "$file\n";
	}

	$ftp->cwd($euk{directory}.'fasta/'.$folder.'/pep');

	my @aalisting = $ftp->dir
	or die "Error: ", $ftp->message;

	foreach my $file(@aalisting) {
		next if($file =~ /abinitio/ || $file =~ /README/);
		chomp $file;

		print $LISTING "$file\n";
	}

	$ftp->cwd($euk{directory}.'gtf/'.$folder.'/');
	my @gtflisting = $ftp->dir
	or die "Error: ", $ftp->message;

	foreach my $file(@gtflisting) {
		chomp $file;
		print $LISTING "$file\n";
	}

	close  $LISTING
        or warn "$0 : failed to close output file '$LISTING_file_name' : $!\n";
}

print "Listings generated!!\n\n";

#---------------------------------------------------------------------------
#  Compare the downloaded listings with the current listings
#---------------------------------------------------------------------------
opendir(DIR, "$euk{dataDir}/listings");
my @files = readdir(DIR);
closedir(DIR);

system("rm -rf $euk{dataDir}/diff");
system("mkdir $euk{dataDir}/diff");
chdir("$euk{dataDir}/diff");

foreach my $file(@files) {
	next unless ($file =~ /listing$/);
	my ($fname) = $file =~ /(\w+)\.listing/;
    system("diff $euk{dataDir}/listings/$file $euk{dataDir}/tmpListings/$file > $fname\.diff");
	my $filesize = -s "$fname\.diff";
	system("rm $fname\.diff") if($filesize == 0);
}

opendir(DIR, "$euk{dataDir}/diff");
my @dir = readdir(DIR);
closedir(DIR);

my $check = 0;

foreach my $file(@dir) {
	my %diff;
	next unless ($file =~ /diff$/);

	open(FILE, "$file");
	my @file_contents = <FILE>;
	close(FILE);

	my ($folder) = $file =~ /(\w+)\.diff$/;
	my $ct1 = 0;
	my $ct2 = 0;

	foreach my $line(@file_contents) {
		next unless($line =~ /\./);
		chomp $line;

		my ($date) = $line =~ /\d*\s*(\w*\s*\d*)\s*\d*\:\d*/;
		my ($fn) = $line =~ /\d*\:\d*\s*(\S*\.gz)$/;

#		print "$fn, $date\n";
		
		chomp $fn;
		if($line =~ /^</) {
			$ct1++;
			$diff{$ct1}{'olddate'} = $date;
			$diff{$ct1}{'oldfile'} = $fn;
		} elsif($line =~ /^>/) {
			$ct2++;
			$diff{$ct2}{'newdate'} = $date;
			$diff{$ct2}{'newfile'} = $fn;
		}
	}

	$folder = lc ($folder);

	for my $key(sort keys %diff) {
		if($diff{$key}{'olddate'} ne $diff{$key}{'newdate'}) {
			$check = 1;
			my $get = $diff{$key}{'oldfile'};
			print "here\n";
			if($diff{$key}{'oldfile'} ne $diff{$key}{'newfile'}) {
				$get = $diff{$key}{'newfile'};
				if($key =~ /dna/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/dna/$get");
				} elsif($key =~ /pep/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/pep/$get");
				} elsif($key =~ /gtf/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}gtf/$folder/$get");
				}
			} else {
				if($key =~ /dna/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/dna/$get");
				} elsif($key =~ /pep/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/pep/$get");
				} elsif($key =~ /gtf/) {
					system("wget ftp://$euk{ftpLink}$euk{directory}gtf/$folder/$get");
				}
			}
		}
	}
}
#---------------------------------------------------------------------------
#  If updates were found, do the following:
#  1. Rename the files
#  2. Split the AA sequences
#  3. Run FORMATDB on the AA sequences
#  4. Parse the GTF files and generate csv files to import into MySQL
#  5. Update the MySQL tables
#  6. Update the current listings
#---------------------------------------------------------------------------
if($check == 1) {
	# Unzip the files
    system("gunzip *.gz");

	my (@chr_dwnld, @aa_dwnld, @gtf_dwnld); 

	opendir(FILES, "$euk{dataDir}/diff");
	my @diff_files = readdir(FILES);
	closedir(FILES);

	my ($fname, $chrno);
	foreach my $file(@diff_files) {
		next if($file =~ /diff/);

		($fname, $chrno) = $file =~ /^(\S+_\S+)\.\S+\.\S+\.[\S+\.]*dna\.chromosome\.(\S+)\.fa$/ if($file =~ /dna/);
		($fname) = $file =~ /^(\S+\_\S+)\.\S+\.\S+\.[\S+\.]*pep.all.fa$/ if($file =~ /pep/);
		($fname) = $file =~ /^(\S+\_\S+)\.\S+\.\S+\.[\S+\.]*gtf$/ if($file =~ /gtf/);
		$fname =~ /^(\S)\S+\_(\S)\S+$/;

		my $fn = "$1".uc($2);

		$chrno = "MT" if($chrno =~ /MtDNA/ || $chrno =~ /mito/);
		$chrno = 1 if($chrno =~ /I/);
		$chrno = 2 if($chrno =~ /II/);
		$chrno = 3 if($chrno =~ /III/);
		$chrno = 4 if($chrno =~ /IV/);
		$chrno = 5 if($chrno =~ /V/);
	
		if($file =~ /dna/) {
			system("mv $file $euk{dataDir}/genomes/$fn$chrno");
			push(@chr_dwnld, "$fn$chrno");
		}
		if($file =~ /pep/) {
			system("rm $euk{dataDir}/aaseqs/$fn*");
			system("mv $file $euk{dataDir}/aaseqs/$fn");
			push(@aa_dwnld, $fn);
		}
		if($file =~ /gtf/) {
			system("mv $file $euk{dataDir}/gtf_files/$fn");
			push(@gtf_dwnld, $fn);
		}
	}

	#---------------------------------------------------------------------------
	#  Split the aasequence files
	#---------------------------------------------------------------------------

	my @handles;
	foreach my $file(@aa_dwnld) {
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
			
			print $outputfile "$sequence\n";
		}
		close(FILE);

		foreach my $handle(@handles) {
			close($handle) or die;
		}
	}

	#---------------------------------------------------------------------------
	#  Run FormatDB on the aaseqs
	#---------------------------------------------------------------------------

	chdir("$euk{dataDir}/aaseqs/");

	foreach my $file(@handles) {
		print "Formatting $file\n";
		system("formatdb -i $file -p T");
	}

	#---------------------------------------------------------------------------
	#  Parsing the GTF files and creating CSV files for the MySQL tables
	#---------------------------------------------------------------------------

	## Set the working directory
	system("rm -rf $euk{dataDir}/tables");
	system("mkdir $euk{dataDir}/tables");
	chdir("$euk{dataDir}/tables");

	my	$MTABLE_file_name = $euk{dataDir}.'/tables/main.csv';		# output file name

	open  my $MTABLE, '>', $MTABLE_file_name
	or die  "$0 : failed to open output file '$MTABLE_file_name' : $!\n";

	my	$LTABLE_file_name = $euk{dataDir}.'/tables/link.csv';		# output file name

	open  my $LTABLE, '>', $LTABLE_file_name
	or die  "$0 : failed to open output file '$LTABLE_file_name' : $!\n";

	my @eukaryotes = ("Homo_sapiens", "Danio_rerio", "Mus_musculus", "Rattus_norvegicus", "Drosophila_melanogaster", "Caenorhabditis_elegans");

	opendir(DIR, "$euk{dataDir}/genomes") || die("Cannot open directory\n");
	my @files = readdir(DIR);
	closedir(DIR);

	foreach my $eukaryote(@eukaryotes) {
		$eukaryote =~ /^(\S)\S+\_(\S)\S+$/;
		my $taxid = "$1".uc($2);

		print $MTABLE "$taxid,$eukaryote\n";

		foreach my $file(@files) {
			next unless($file =~ /$taxid/);
			my($chrno) = $file =~ /^\S\S(\S+)$/;

			next if($chrno =~ /MT/);

			my $seqlength;

			my	$GENOME_file_name = $euk{dataDir}.'/genomes/'.$file;		# input file name

				open  my $GENOME, '<', $GENOME_file_name
				or die  "$0 : failed to open  input file '$GENOME_file_name' : $!\n";

			while(<$GENOME>) {
				/^>\S+ \S+:\S+ \S+:\S+:\S+:\S+:(\S+):\S+$/;
				$seqlength = $1;
				last;
			}

			close  $GENOME
				or warn "$0 : failed to close input file '$GENOME_file_name' : $!\n";

			print $LTABLE "$taxid,$file,$eukaryote Chromosome $chrno,$seqlength\n";
		}
	}

	close  $LTABLE
	or warn "$0 : failed to close input file '$LTABLE_file_name' : $!\n";

	close  $MTABLE
	or warn "$0 : failed to close input file '$MTABLE_file_name' : $!\n";


	## Read the directory and get a file listing
	opendir(DIR,  "$euk{dataDir}/gtf_files") || die("Cannot open directory\n");
	my @gtffiles = readdir(DIR);
	closedir(DIR);
		
	my	$GDTABLE_file_name = $euk{dataDir}.'/tables/genedetails.csv';		# output file name

	open  my $GDTABLE, '>', $GDTABLE_file_name
	or die  "$0 : failed to open  output file '$GDTABLE_file_name' : $!\n";

	## Iterate through the files
	foreach my $file(@gtffiles) {
		next if($file =~ /\./);

		my	$GTF_file_name = $euk{dataDir}.'/gtf_files/'.$file;		# input file name

		my (%STRAND, %TRANSCRIPT, %PROTEIN, %GENE, %CHR, %GENE_NAME);

		open(INFILE, "$GTF_file_name");
		while(<INFILE>) {
			chomp;
			next if($_ =~ /^MT/ || $_ =~ /^MtDNA/ || $_ =~ /^dmel_mito/ || $_ =~ /^c[0-9]*/ || $_ =~ /Het/ || $_ =~ /^Zv7/ || $_ =~ /^NT/);

			my @column = split(/\t/, $_);

			my $gene_details = $column[8];
			my $feature = $column[2];
			my $start_pos = $column[3];
			my $end_pos = $column[4];
			my $strand = $column[6];
			my ($gene_id, $transcript_id) = $gene_details =~ /gene_id\s+\"(\S+)\"\;\s+transcript_id\s+\"(\S+)\"/;
			my $gene_name; 
			if($gene_details =~ /gene_id\s+\"\S+\"\;\s+transcript_id\s+\"\S+\"\;\s+exon_number\s+\"\S+\"\;\s+gene_name\s+\"(\S+)\"/){
				$gene_name = $1;
			} else {
				$gene_name = $gene_id;
			}
			if($feature eq 'exon') {
				$TRANSCRIPT{$transcript_id} .= ";$start_pos:$end_pos";
				$GENE_NAME{$transcript_id} = $gene_name;
			} elsif($feature eq 'CDS') {
				my ($protein_id) =  $gene_details =~ /protein_id\s+\"(\S+)\"\;$/;
				if(exists $PROTEIN{$transcript_id}){
					my $old_protein = $PROTEIN{$transcript_id};
					if($old_protein ne $protein_id){
						print STDERR "error: one transcript encodes multiple protein\ntranscript_id=$transcript_id\nLine: $_\n";
						exit;
					}
				}
				$PROTEIN{$transcript_id} = $protein_id;
			}

			$STRAND{$gene_id} = $strand;
			$GENE{$gene_id} .= ";$transcript_id:$start_pos:$end_pos";
			$CHR{$gene_id} = $column[0];
		}
		close(INFILE);

		foreach my $gene_id (keys %GENE) {
			my $strand = $STRAND{$gene_id};
			my $chrno = $CHR{$gene_id};

			my @gene_coord = split(/;/, $GENE{$gene_id});
			my @gene_num;

			foreach my $gene_coord (@gene_coord) {
				next unless ($gene_coord =~ /\w/);
				my ($transcript_id, $transcript_start, $transcript_end) = $gene_coord =~ /^(\S+):(\d+):(\d+)/;
				push(@gene_num, $transcript_start);
				push(@gene_num, $transcript_end);
			}

			my @s_gene_num = sort { $a <=> $b } @gene_num;
			my $gene_min = shift @s_gene_num;
			my $gene_max = pop @s_gene_num;
			
			my %UNIQ; #prevent duplciate printing
			foreach my $gene_coord (@gene_coord) {
				next unless ($gene_coord =~ /\w/);
				my ($transcript_id, $transcript_start, $transcript_end) = $gene_coord =~ /^(\S+):(\d+):(\d+)/;
				next unless (exists $PROTEIN{$transcript_id}); #ignore non-protein coding genes
				my $protein_id = $PROTEIN{$transcript_id};
				my $gene_name = $GENE_NAME{$transcript_id};
				my @transcript_coord = split(/;/, $TRANSCRIPT{$transcript_id});
				my @transcript_num;
				foreach my $transcript_coord (@transcript_coord) {
					next unless ($transcript_coord =~ /\w/);
					my ($start, $end) = $transcript_coord =~ /^(\d+):(\d+)/;
					push(@transcript_num, $start);
					push(@transcript_num, $end);
				}
				my @s_transcript_num = sort { $a <=> $b } @transcript_num;
				my $transcript_min = shift @s_transcript_num;
				my $transcript_max = pop @s_transcript_num;
				my $key = "$gene_id\t$transcript_id\t$protein_id";
				next if(exists $UNIQ{$key});
				print $GDTABLE $file.$chrno,",$protein_id,$gene_id,$gene_min,$gene_max,$transcript_id,$transcript_min,$transcript_max,$strand,$gene_name\n";
				$UNIQ{$key} = 1;
			}
		}
	}	## close foreach

	close  $GDTABLE
	or warn "$0 : failed to close output file '$GDTABLE_file_name' : $!\n";

	system("sed -e 's/CEIV/CE4/g' -i genedetails.csv"); 
	system("sed -e 's/CEV/CE5/g' -i genedetails.csv"); 
	system("sed -e 's/CEIII/CE3/g' -i genedetails.csv"); 
	system("sed -e 's/CEII/CE2/g' -i genedetails.csv"); 
	system("sed -e 's/CEI/CE1/g' -i genedetails.csv");

	#---------------------------------------------------------------------------
	#  Create the MySQL tables and update the data
	#---------------------------------------------------------------------------

	my $dsn = "DBI:mysql:host=$euk{host};database=$euk{database}";
	my $dbh = DBI->connect($dsn, $euk{dbuname}, $euk{dbpasswd})
	or die "Cannot connect to server\n";

	my $query = $dbh->prepare($euk{mainTblupdate});
	$query->execute();

	$query = $dbh->prepare($euk{linkTblupdate});
	$query->execute();

	$query = $dbh->prepare($euk{childTblupdate});
	$query->execute();

	$query = $dbh->prepare($euk{aaSeqTblupdate});

	chdir("$euk{dataDir}/aaseqs/");

	foreach my $file(@handles) {
		open(FILE, "$file");

		$/='>';
		while(<FILE>) {
			next unless (/chromosome/);

			s/>$//;
			my ($protein_id) = $_ =~ /(.*) pep/;
			my $sequence = ">$_";
#				print "$protein_id\n$sequence\n";
			$query->execute($protein_id, $sequence);
		}
		close(FILE);
	}

	$dbh->disconnect;

	#---------------------------------------------------------------------------
	#  Update listings
	#---------------------------------------------------------------------------
=comment	
	chdir("$euk{dataDir}/listings/");

	foreach my $eukaryote(@eukaryotes) {
		print "$eukaryote\n";
		my $folder = lc $eukaryote;

		$ftp->cwd($euk{directory}.'fasta/'.$folder.'/dna/');

		my @listing = $ftp->dir
		or die "Error: ", $ftp->message;

		my	$LISTING_file_name = $eukaryote.'.listing';		# output file name

			open  my $LISTING, '>', $LISTING_file_name
			or die  "$0 : failed to open  output file '$LISTING_file_name' : $!\n";

		foreach my $file(@listing) {
			next unless ($file =~ /dna\.chromosome/ && $file =~ /\.fa\.gz$/);
			next if($file =~ /c[0-9]*_\w+/ || $file =~ /dna_rm/ || $file =~ /nonchromo/ || $file =~ /toplevel/ || $file =~ /README/ || $file =~ /Het/ || $file =~ /extra/);
			chomp $file;

			print $LISTING "$file\n";
		}

		$ftp->cwd($euk{directory}.'fasta/'.$folder.'/pep');

		my @aalisting = $ftp->dir
		or die "Error: ", $ftp->message;

		foreach my $file(@aalisting) {
			next if($file =~ /abinitio/ || $file =~ /README/);
			chomp $file;

			print $LISTING "$file\n";
		}

		$ftp->cwd($euk{directory}.'gtf/'.$folder.'/');
		my @gtflisting = $ftp->dir
		or die "Error: ", $ftp->message;

		foreach my $file(@gtflisting) {
			chomp $file;
			print $LISTING "$file\n";
		}

		close  $LISTING
			or warn "$0 : failed to close output file '$LISTING_file_name' : $!\n";
	}
=cut
	print "Listings updated!!\n\n";
} else {
	print STDERR "No updates found! Thank you for using the updater\n\n";	
}

exit;
