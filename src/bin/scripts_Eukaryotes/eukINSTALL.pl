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
#         FILE:  eukINSTALL.pl
#
#        USAGE:  ./eukINSTALL.pl
#
#  DESCRIPTION:  Program that downloads and sets up the database for 6
#                Eukaryotic organisms from ENSEMBL FTP
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
use Proc::Simple;

use My::Vars ();
use vars qw(%euk);

*euk = \%My::Vars::euk;
my $usage = "Usage: $0 sampler|full-install";
my $mode = shift or die "\n\nError: installation mode not specified!\n$usage\n\n";
($mode eq "sampler") ? "" : (($mode ne "full-install") ? "" : die $usage);

my $currdir = `pwd`;
chomp $currdir;

system("date");

print
"Welcome to the Downloader. This will download all the sequences pertaining to selected Eukaryotes from Ensembl\n\n";

## Change to the appropriate directory
system("mkdir $euk{dataDir}") if (!-d $euk{dataDir});
chdir("$euk{dataDir}");

###############################################################################
# Connect to the Ensembl FTP site and generate the file listing.

print "Connecting to Ensembl FTP...\n";
my $ftp;
print
"Logging in with the following credentials.\n\nUsername: $euk{uname}\nPassword: $euk{passwd}\n\n";

###############################################################################

## Create the necessary directories to store the downloaded files
system("rm -rf $euk{dataDir}/genomes/");
system("rm -rf $euk{dataDir}/aaseqs/");
system("rm -rf $euk{dataDir}/gtf_files/");

system("mkdir $euk{dataDir}/genomes/");
system("mkdir $euk{dataDir}/aaseqs/");
system("mkdir $euk{dataDir}/gtf_files/");

my @organisms = (
    "Homo_sapiens",            "Danio_rerio",
    "Mus_musculus",            "Rattus_norvegicus",
    "Drosophila_melanogaster", "Caenorhabditis_elegans"
);

my @eukaryotes = ($mode eq "sampler") ? @organisms[0,2] : @organisms;
foreach my $eukaryote (@eukaryotes) {
    print "$eukaryote - Commencing download of files...\n\n";

    my $folder = lc $eukaryote;

    $eukaryote =~ /(\S)\S+\_(\S)\S+/;
    my $fname = "$1" . uc($2);

    #---------------------------------------------------------------------------
    #  Chromosomes
    #---------------------------------------------------------------------------
    &ftp_connect();

    $ftp->cwd($euk{directory} . 'fasta/' . $folder . '/dna') or die "Error: ", $ftp->message;
    print "Chromosomes\n";

    my @listing = $ftp->ls("*.fa.gz")
      or die "Error: ", $ftp->message;
    $ftp->close;

    foreach my $file (@listing) {
        next unless ($file =~ /dna\.chromosome/ && $file =~ /\.fa\.gz$/);
        next
          if ( $file =~ /c[0-9]*_\w+/
            or $file =~ /dna_rm/
            or $file =~ /nonchromo/
            or $file =~ /toplevel/
            or $file =~ /README/
            or $file =~ /Het/
            or $file =~ /extra/
            or $file =~ /MT/
            or $file =~ /mito/
            or $file =~ /MtDNA/
            or $file =~ /HG\d+/
            or $file =~ /HS\S+/);

        print "$file\n";

        #$ftp->get($file) or die "Error: ", $ftp->message;
        system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/dna/$file --quiet");
    }
    print "\n";

    #---------------------------------------------------------------------------
    #  AA sequences
    #---------------------------------------------------------------------------
    &ftp_connect();

    $ftp->cwd($euk{directory} . 'fasta/' . $folder . '/pep/') or die "Error: ", $ftp->message;
    print "AA sequences\n";

    my @aalisting = $ftp->ls("*.fa.gz")
      or die "Error: ", $ftp->message;
    $ftp->close;

    foreach my $file (@aalisting) {
        next if ($file =~ /abinitio/ or $file =~ /README/);

        print "$file\n";

        #$ftp->get($file) or die "Error: ", $ftp->message;
        system("wget ftp://$euk{ftpLink}$euk{directory}fasta/$folder/pep/$file --quiet");
    }
    print "\n";

    #---------------------------------------------------------------------------
    #  GTF files
    #---------------------------------------------------------------------------
    &ftp_connect();

    $ftp->cwd($euk{directory} . 'gtf/' . $folder . '/') or die "Error: ", $ftp->message;
    print "GTF File\n";

    my @gtflisting = $ftp->ls("*.gtf.gz")
      or die "Error: ", $ftp->message;
    $ftp->close;

    foreach my $file (@gtflisting) {
        print "$file\n";

        #$ftp->get($file) or die "Error: ", $ftp->message;
        system("wget ftp://$euk{ftpLink}$euk{directory}gtf/$folder/$file --quiet");
    }
    print "\n";

    print "Unzipping files...";
    system("gunzip *.gz");
    print "Done!\n\n";

    print "Moving the files to the corresponding directories...\n\n";

    opendir(DIR, "$euk{dataDir}");
    my @files = readdir(DIR);
    closedir(DIR);
    foreach my $file (@files) {
        next unless ($file =~ /^$eukaryote/);
        print $file, "\n";

        my ($chrno) = $file =~ /^\S+_\S+\.\S+\.\S+\.[\S+\.]*dna\.chromosome\.(\S+)\.fa$/
          if ($file =~ /dna/);
        $chrno = 1 if ($chrno =~ /I/);
        $chrno = 2 if ($chrno =~ /II/);
        $chrno = 3 if ($chrno =~ /III/);
        $chrno = 4 if ($chrno =~ /IV/);
        $chrno = 5 if ($chrno =~ /V/);

        system("mv $euk{dataDir}/$file $euk{dataDir}/genomes/$fname$chrno") if ($file =~ /dna/);
        system("mv $euk{dataDir}/$file $euk{dataDir}/aaseqs/$fname")        if ($file =~ /pep/);
        system("mv $euk{dataDir}/$file $euk{dataDir}/gtf_files/$fname")     if ($file =~ /gtf/);
    }
    print "\n";
}
print "Done!!\n\n";

#---------------------------------------------------------------------------
#  Generate the listings
#---------------------------------------------------------------------------
&ftp_connect();

system("rm -rf $euk{dataDir}/listings");
system("mkdir $euk{dataDir}/listings");
chdir("$euk{dataDir}/listings/");

foreach my $eukaryote (@eukaryotes) {
    print "$eukaryote\n";
    my $folder = lc $eukaryote;

    $ftp->cwd($euk{directory} . 'fasta/' . $folder . '/dna/') or die "Error: ", $ftp->message;

    my @listing = $ftp->dir
      or die "Error: ", $ftp->message;

    my $LISTING_file_name = $eukaryote . '.listing';    # output file name
    open my $LISTING, '>', $LISTING_file_name
      or die "$0 : failed to open  output file '$LISTING_file_name' : $!\n";

    foreach my $file (@listing) {
        next unless ($file =~ /dna\.chromosome/ && $file =~ /\.fa\.gz$/);
        next
          if ( $file =~ /c[0-9]*_\w+/
            or $file =~ /dna_rm/
            or $file =~ /nonchromo/
            or $file =~ /toplevel/
            or $file =~ /README/
            or $file =~ /Het/
            or $file =~ /extra/
            or $file =~ /MT/
            or $file =~ /mito/
            or $file =~ /MtDNA/
            or $file =~ /HG\d+/
            or $file =~ /HS\S+/);

        chomp $file;
        print $LISTING "$file\n";
    }

    $ftp->cwd($euk{directory} . 'fasta/' . $folder . '/pep') or die "Error: ", $ftp->message;

    my @aalisting = $ftp->dir
      or die "Error: ", $ftp->message;

    foreach my $file (@aalisting) {
        next if ($file =~ /abinitio/ or $file =~ /README/);

        chomp $file;

        print $LISTING "$file\n";
    }

    $ftp->cwd($euk{directory} . 'gtf/' . $folder . '/') or die "Error: ", $ftp->message;
    my @gtflisting = $ftp->dir
      or die "Error: ", $ftp->message;

    foreach my $file (@gtflisting) {
        chomp $file;

        print $LISTING "$file\n";
    }

    close $LISTING
      or warn "$0 : failed to close output file '$LISTING_file_name' : $!\n";
}

$ftp->quit;    ## Close the FTP connection
print "Listings generated!!\n\n";

#---------------------------------------------------------------------------
#  Split the aasequence files
#---------------------------------------------------------------------------

system("cd $currdir");
system("perl splitaaseqs.pl");

#---------------------------------------------------------------------------
#  Run FormatDB on the aaseqs
#---------------------------------------------------------------------------

system("rm *.pin *.psq *.phr *.log");

opendir(DIR, "$euk{dataDir}/aaseqs/");
my @files = readdir(DIR);
closedir(DIR);

foreach my $file (@files) {
    next if ($file =~ /^\./);
    print "Formatting $file\n";

    #system("formatdb -i $file -p T");
}

#---------------------------------------------------------------------------
#  Parsing the GTF files and creating CSV files for the MySQL tables
#---------------------------------------------------------------------------

## Set the working directory
system("rm -rf $euk{dataDir}/tables");
system("mkdir $euk{dataDir}/tables");
chdir("$euk{dataDir}/tables");

print "\n\nParsing GTF files and creating CSV formatted files to populate MySQL database\n";

my $MTABLE_file_name = $euk{dataDir} . '/tables/main.csv';    # output file name

open my $MTABLE, '>', $MTABLE_file_name
  or die "$0 : failed to open output file '$MTABLE_file_name' : $!\n";

my $LTABLE_file_name = $euk{dataDir} . '/tables/link.csv';    # output file name

open my $LTABLE, '>', $LTABLE_file_name
  or die "$0 : failed to open output file '$LTABLE_file_name' : $!\n";

opendir(DIR, "$euk{dataDir}/genomes") or die("Cannot open directory\n");
my @files = readdir(DIR);
closedir(DIR);

foreach my $eukaryote (@eukaryotes) {
    $eukaryote =~ /^(\S)\S+\_(\S)\S+$/;
    my $taxid = "$1" . uc($2);

    print $MTABLE "$taxid,$eukaryote\n";

    foreach my $file (@files) {
        next unless ($file =~ /$taxid/);
        my ($chrno) = $file =~ /^\S\S(\S+)$/;

        next if ($chrno =~ /MT/ or $chrno =~ /MtDNA/);

        my $seqlength;

        my $GENOME_file_name = $euk{dataDir} . '/genomes/' . $file;    # input file name

        open my $GENOME, '<', $GENOME_file_name
          or die "$0 : failed to open  input file '$GENOME_file_name' : $!\n";

        while (<$GENOME>) {
            /^>\S+ \S+\:\S+ \S+\:\S+\:\S+\:\S+\:(\S+)\:\S+$/;
            $seqlength = $1;
            last;
        }

        close $GENOME
          or warn "$0 : failed to close input file '$GENOME_file_name' : $!\n";

        print $LTABLE "$taxid,$file,$eukaryote Chromosome $chrno,$seqlength\n";
    }
}

close $LTABLE
  or warn "$0 : failed to close input file '$LTABLE_file_name' : $!\n";

close $MTABLE
  or warn "$0 : failed to close input file '$MTABLE_file_name' : $!\n";

## Read the directory and get a file listing
opendir(DIR, "$euk{dataDir}/gtf_files") or die("Cannot open directory\n");
my @gtffiles = readdir(DIR);
closedir(DIR);

my $GDTABLE_file_name = $euk{dataDir} . '/tables/genedetails.csv';    # output file name

open my $GDTABLE, '>', $GDTABLE_file_name
  or die "$0 : failed to open  output file '$GDTABLE_file_name' : $!\n";

## Iterate through the files
foreach my $file (@gtffiles) {
    next if ($file =~ /\./);

    my $GTF_file_name = $euk{dataDir} . '/gtf_files/' . $file;        # input file name

    my (%STRAND, %TRANSCRIPT, %PROTEIN, %GENE, %CHR, %GENE_NAME);

    open(INFILE, "$GTF_file_name");
    while (<INFILE>) {
        chomp;
        next
          if ( $_ =~ /^MT/
            or $_ =~ /^MtDNA/
            or $_ =~ /^dmel_mito/
            or $_ =~ /^c[0-9]*/
            or $_ =~ /Het/
            or $_ =~ /^Zv7/
            or $_ =~ /^NT/);

        my @column = split(/\t/, $_);

        my $gene_details = $column[8];
        my $feature      = $column[2];
        my $start_pos    = $column[3];
        my $end_pos      = $column[4];
        my $strand       = $column[6];
        my ($gene_id, $transcript_id) =
          $gene_details =~ /gene_id\s+\"(\S+)\"\;\s+transcript_id\s+\"(\S+)\"/;
        my $gene_name;

        if ($gene_details =~
/gene_id\s+\"\S+\"\;\s+transcript_id\s+\"\S+\"\;\s+exon_number\s+\"\S+\"\;\s+gene_name\s+\"(\S+)\"/
          )
        {
            $gene_name = $1;
        }
        else {
            $gene_name = $gene_id;
        }
        if ($feature eq 'exon') {
            $TRANSCRIPT{$transcript_id} .= ";$start_pos:$end_pos";
            $GENE_NAME{$transcript_id} = $gene_name;
        }
        elsif ($feature eq 'CDS') {
            my ($protein_id) = $gene_details =~ /protein_id\s+\"(\S+)\"\;$/;
            if (exists $PROTEIN{$transcript_id}) {
                my $old_protein = $PROTEIN{$transcript_id};
                if ($old_protein ne $protein_id) {
                    print STDERR
"error: one transcript encodes multiple protein\ntranscript_id=$transcript_id\nLine: $_\n";
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
        my $chrno  = $CHR{$gene_id};

        my @gene_coord = split(/;/, $GENE{$gene_id});
        my @gene_num;

        foreach my $gene_coord (@gene_coord) {
            next unless ($gene_coord =~ /\w/);
            my ($transcript_id, $transcript_start, $transcript_end) =
              $gene_coord =~ /^(\S+):(\d+):(\d+)/;
            push(@gene_num, $transcript_start);
            push(@gene_num, $transcript_end);
        }

        my @s_gene_num = sort { $a <=> $b } @gene_num;
        my $gene_min   = shift @s_gene_num;
        my $gene_max   = pop @s_gene_num;

        my %UNIQ;    #prevent duplciate printing
        foreach my $gene_coord (@gene_coord) {
            next unless ($gene_coord =~ /\w/);
            my ($transcript_id, $transcript_start, $transcript_end) =
              $gene_coord =~ /^(\S+):(\d+):(\d+)/;
            next unless (exists $PROTEIN{$transcript_id});    #ignore non-protein coding genes
            my $protein_id       = $PROTEIN{$transcript_id};
            my $gene_name        = $GENE_NAME{$transcript_id};
            my @transcript_coord = split(/;/, $TRANSCRIPT{$transcript_id});
            my @transcript_num;
            foreach my $transcript_coord (@transcript_coord) {
                next unless ($transcript_coord =~ /\w/);
                my ($start, $end) = $transcript_coord =~ /^(\d+):(\d+)/;
                push(@transcript_num, $start);
                push(@transcript_num, $end);
            }
            my @s_transcript_num = sort { $a <=> $b } @transcript_num;
            my $transcript_min   = shift @s_transcript_num;
            my $transcript_max   = pop @s_transcript_num;
            my $key              = "$gene_id\t$transcript_id\t$protein_id";
            next if (exists $UNIQ{$key});
            print $GDTABLE $file . $chrno,
",$protein_id,$gene_id,$gene_min,$gene_max,$transcript_id,$transcript_min,$transcript_max,$strand,$gene_name\n";
            $UNIQ{$key} = 1;
        }
    }
}    ## close foreach

close $GDTABLE
  or warn "$0 : failed to close output file '$GDTABLE_file_name' : $!\n";

system("sed -e 's/CEV/CE5/g' -i genedetails.csv");
system("sed -e 's/CEIV/CE4/g' -i genedetails.csv");
system("sed -e 's/CEIII/CE3/g' -i genedetails.csv");
system("sed -e 's/CEII/CE2/g' -i genedetails.csv");
system("sed -e 's/CEI/CE1/g' -i genedetails.csv");

#---------------------------------------------------------------------------
#  Create the MySQL tables and update the data
#---------------------------------------------------------------------------

print "\n\nSetting up the MySQL database and inserting the data\n";

my $dsn = "DBI:mysql:host=$euk{host};database=$euk{database}";
my $dbh = DBI->connect($dsn, $euk{dbuname}, $euk{dbpasswd})
  or die "Cannot connect to server\n";

my $query = $dbh->prepare($euk{mainTbldrop});
$query->execute();

$query = $dbh->prepare($euk{linkTbldrop});
$query->execute();

$query = $dbh->prepare($euk{childTbldrop});
$query->execute();

$query = $dbh->prepare($euk{mainTblcreate});
$query->execute();

$query = $dbh->prepare($euk{linkTblcreate});
$query->execute();

$query = $dbh->prepare($euk{childTblcreate});
$query->execute();

$query = $dbh->prepare($euk{mainTblLoad});
$query->execute();

$query = $dbh->prepare($euk{linkTblLoad});
$query->execute();

$query = $dbh->prepare($euk{childTblLoad});
$query->execute();

$query = $dbh->prepare($euk{aaSeqTbldrop});
$query->execute();

$query = $dbh->prepare($euk{aaSeqTblcreate});
$query->execute();

$query = $dbh->prepare($euk{aaSeqTblinsert});

opendir(DIR, "$euk{dataDir}/aaseqs/");
my @dir = readdir(DIR);
closedir(DIR);

chdir("$euk{dataDir}/aaseqs/");

foreach my $file (@dir) {
    print "$file\n";
    open(FILE, "$file");

    $/ = '>';
    while (<FILE>) {
        next unless (/chromosome/);

        s/>$//;
        my ($protein_id) = $_ =~ /(.*) pep/;
        my $sequence = ">$_";

        #		print "$protein_id\n$sequence\n";
        $query->execute($protein_id, $sequence);
    }
    close(FILE);
}

$dbh->disconnect;

print "\n\nAll done!\n";

system("date");

exit;

sub ftp_connect {
    ## Open the FTP connection
    $ftp = Net::FTP->new($euk{ftpLink}, Debug => 0, Passive => 1, Timeout => 600)
        or die "Error: $@";

    ## Login Credentials. Provide your email ID as anonymous login password
    $ftp->login($euk{uname}, $euk{passwd})
        or die "Error: ", $ftp->message;
}
