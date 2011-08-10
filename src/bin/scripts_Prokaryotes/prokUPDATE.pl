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
#         FILE:  prokUPDATE.pl
#
#        USAGE:  ./prokUPDATE.pl
#
#  DESCRIPTION:  Program that connects with the GenBank FTP site and looks
#  				 for updates. If updates are found, the files are downloaded,
#  				 formatted using formatdb and all the MySQL tables are updated.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Vivek Krishnakumar <biohelp@cgb.indiana.edu>
#      COMPANY:  The Center for Genomics and Bioinformatics
#      VERSION:  1.0
#      CREATED:  09/25/08 11:58:43 EDT
#     REVISION:  ---
#===============================================================================

use strict;

#---------------------------------------------------------------------------
#  Load the required modules
#---------------------------------------------------------------------------
use Net::FTP;
use DBI;
use My::Vars ();
use vars qw(%bact);

*bact = \%My::Vars::bact;
my $usage = "Usage: $0 sampler|full-install";
my $mode = shift or die "\n\nError: installation mode not specified!\n$usage\n\n";
($mode eq "sampler") ? "" : (($mode eq "full-install") ? "" : die $usage);

print "Welcome to the updater! Please be patient while updates are being checked...\n";

system "rm -rf $bact{dataDir}/tmpListings";
system "mkdir $bact{dataDir}/tmpListings";
chdir "$bact{dataDir}/tmpListings";

#---------------------------------------------------------------------------
#  Connect to the GenBank FTP site and generate the file listing.
#---------------------------------------------------------------------------
# Open the FTP connection
my $ftp = Net::FTP->new($bact{ftpLink}, Debug => 0, Timeout => 800, Passive => 1)
  or die "Error: $@";

# Login Credentials
$ftp->login($bact{uname}, $bact{passwd})
  or die "Error: ", $ftp->message;

print "Connected and logged in to $bact{ftpLink}\n";
print "Generating current listings...";

# Change to the 'genomes' directory
$ftp->cwd($bact{directory})
  or die "Error: ", $ftp->message;

# Save the Directory listing of the 'Bacteria' directory to an array
my @directories =
  ($mode eq /sampler/)
  ? (
    "Caulobacter_crescentus", "Jannaschia_CCS1",
    "Maricaulis_maris_MCS10", "Rhizobium_etli_CFN_42",
    "Silicibacter_TM1040"
  )
  : $ftp->ls
  or die "Error: ", $ftp->message;

foreach my $dir (@directories) {
    next if ($dir =~ /README/ || $dir =~ /accessions/);

    $ftp->cwd($dir)
      or die "Error: ", $ftp->message;

    my @dir_listing  = $ftp->dir         or die "Error: ", $ftp->message;
    my @file_listing = $ftp->ls('*.fna') or die "Error: ", $ftp->message;

    open LISTING, ">$dir\.listing";
    foreach my $file (@file_listing) {
        my ($fname) = $file =~ /^(\w+)\.fna$/;
        foreach my $line (@dir_listing) {
            chomp $line;
            print LISTING $line, "\n" if ($line =~ /$fname\.fna/);
            print LISTING $line, "\n" if ($line =~ /$fname\.faa/);
            print LISTING $line, "\n" if ($line =~ /$fname\.ffn/);
            print LISTING $line, "\n" if ($line =~ /$fname\.gff/);
        }
    }
    close LISTING;
    $ftp->cwd("../") or die "Error: ", $ftp->message;
}
print "Done!\n";

$ftp->quit;    # Close the FTP connection

#---------------------------------------------------------------------------
#  Compare the downloaded listings with the current listings
#---------------------------------------------------------------------------

print "Comparing the current listings with the Downloaded listings.....";

my @origFileListings = <$bact{dataDir}/listings/*.listing>;
my @newFileListings  = <$bact{dataDir}/tmpListings/*.listing>;

foreach (@origFileListings) {
    chomp;
    s/^$bact{dataDir}\/listings\///gs;
    s/\.listing$//gs;
}
foreach (@newFileListings) {
    chomp;
    s/^$bact{dataDir}\/tmpListings\///gs;
    s/\.listing$//gs;
}

my %hashOrigListings = map  { $_, 1 } @origFileListings;
my @newFiles         = grep { !$hashOrigListings{$_} } @newFileListings;
my @oldFiles         = grep { $hashOrigListings{$_} } @newFileListings;

my %hashOldFiles = map { $_, 1 } @oldFiles;
my @deletedFiles = grep { !$hashOldFiles{$_} } @origFileListings;

print "Done!\n";

#---------------------------------------------------------------------------
#  Check for updates in existing files by comparing the listings (@oldFiles)
#---------------------------------------------------------------------------

system "rm -rf $bact{dataDir}/diff";
system "mkdir $bact{dataDir}/diff";
chdir "$bact{dataDir}/diff";

my $check = 0;

print "Looking for updated files and dowloading the data.....\n";

my @diffFiles;
foreach my $file (@oldFiles) {
    system
"diff $bact{dataDir}/listings/$file\.listing $bact{dataDir}/tmpListings/$file\.listing > $file\.diff";
    my $filesize = -s "$file\.diff";
    if ($filesize == 0) {
        system "rm $file\.diff";
    }
    else {
        system "rm $file\.diff";

        system
"diff -y -W 150 $bact{dataDir}/listings/$file\.listing $bact{dataDir}/tmpListings/$file\.listing > $file\.diff";
        push @diffFiles, "$file\.diff";
    }
}

my (@downloaded, @origDwnld, @newDwnld, @delOrgs);
my @foldernames;

foreach my $file (@diffFiles) {
    my %timestamp = ();

    open FILE, "<$file";
    my @file_contents = <FILE>;
    close FILE;

    my ($fname) = $file =~ /(.*)\.diff$/;
    push @foldernames, $fname;
    my $fn;

    foreach my $line (@file_contents) {
        next unless ($line =~ /\|/ || $line =~ />/ || $line =~ /</);
        chomp $line;

        if ($line =~ /\|/) {
            my @diffLine = split /\|/, $line;
            $diffLine[0] =~ s/\s+$//gs;
            $diffLine[1] =~ s/^\s+//gs;

            my @first  = split /\s+/, $diffLine[0];
            my @second = split /\s+/, $diffLine[1];

            $timestamp{ $first[8] }{oldDDMMMYY}  = "$first[6]\-$first[5]\-$first[7]";
            $timestamp{ $second[8] }{newDDMMMYY} = "$second[6]\-$second[5]\-$second[7]";
        }
        elsif ($line =~ />/) {
            my @diffLine = split />/, $line;
            $diffLine[1] =~ s/^\s+//gs;

            my @second = split /\s+/, $diffLine[1];
            push @newFiles, "$fname/$second[8]";
        }
        elsif ($line =~ /</) {
            my @diffLine = split /</, $line;
            $diffLine[0] =~ s/\s+$//gs;

            my @first = split /\s+/, $diffLine[0];
            push @deletedFiles, "$fname/$first[8]";
        }
    }

    for my $key (sort keys %timestamp) {
        if ($timestamp{$key}{oldDDMMMYY} ne $timestamp{$key}{newDDMMMYY}) {
            $check = 1;
            system
"printf \"Fetching ftp://$bact{ftpLink}/$bact{directory}/$fname/$key ...\" ; wget ftp://$bact{ftpLink}/$bact{directory}/$fname/$key --quiet --passive-ftp ; echo ...Done!";
            my ($Fn) = $key =~ /^(\S+)\.\S+$/;

            if (grep { $_ eq $Fn } @downloaded) {
            }
            else {
                push @downloaded, $Fn;
            }

            if (grep { $_ eq $fname } @origDwnld) {
            }
            else {
                push @origDwnld, $fname;
            }

            system "mv $key $bact{dataDir}/aaseqs/$Fn"    if ($key =~ /faa$/);
            system "mv $key $bact{dataDir}/genomes/$Fn"   if ($key =~ /fna$/);
            system "mv $key $bact{dataDir}/geneseqs/$Fn"  if ($key =~ /ffn$/);
            system "mv $key $bact{dataDir}/gff_files/$Fn" if ($key =~ /gff$/);
        }
    }
}
print "Done!\n";

#---------------------------------------------------------------------------
#  Download all files corresponding to the newly added organisms (@newFiles)
#---------------------------------------------------------------------------

if (scalar @newFiles > 0) {
    $check = 1;
    print "New organisms found. Downloading files pertaining to the new organisms...\n";

    foreach my $dir (@newFiles) {
        if ($dir =~ /\//) {
            my ($DIR, $file) = $dir =~ /^(\S+)\/(\S+\.\S+)$/;
            if (grep { $_ eq $DIR } @foldernames) {
            }
            else {
                push @foldernames, $DIR;
            }

            my ($fname) = $file =~ /^(\S+)\.\S+$/;

            if (grep { $_ eq $fname } @downloaded) {
            }
            else {
                push @downloaded, $fname;
            }

            system
"printf \"Fetching ftp://$bact{ftpLink}/$bact{directory}/$dir ...\" ; wget ftp://$bact{ftpLink}/$bact{directory}/$dir --quiet --passive-ftp; echo ...Done!";

            system "mv $file $bact{dataDir}/genomes/$fname"   if ($file =~ /fna/);
            system "mv $file $bact{dataDir}/gff_files/$fname" if ($file =~ /gff/);
            system "mv $file $bact{dataDir}/aaseqs/$fname"    if ($file =~ /faa/);
            system "mv $file $bact{dataDir}/geneseqs/$fname"  if ($file =~ /ffn/);
        }
        else {
            if (grep { $_ eq $dir } @foldernames) {
            }
            else {
                push @foldernames, $dir;
            }

            if (grep { $_ eq $dir } @newDwnld) {
            }
            else {
                push @newDwnld, $dir;
            }

            open NEWLISTING, "<$bact{dataDir}/tmpListings/$dir\.listing";
            while (<NEWLISTING>) {
                chomp;

                my @column = split /\s+/;
                my $file   = $column[8];

                my ($fname) = $file =~ /^(\S+)\.\S+$/;

                if (grep { $_ eq $fname } @downloaded) {
                }
                else {
                    push @downloaded, $fname;
                }

                system
"printf \"Fetching ftp://$bact{ftpLink}/$bact{directory}/$dir/$file...\" ; wget ftp://$bact{ftpLink}/$bact{directory}/$dir/$file --quiet --passive-ftp; echo ...Done!";

                system "mv $file $bact{dataDir}/genomes/$fname"   if ($file =~ /fna/);
                system "mv $file $bact{dataDir}/gff_files/$fname" if ($file =~ /gff/);
                system "mv $file $bact{dataDir}/aaseqs/$fname"    if ($file =~ /faa/);
                system "mv $file $bact{dataDir}/geneseqs/$fname"  if ($file =~ /ffn/);
            }
            close NEWLISTING;
        }
    }
    print "Done!\n";
}

#---------------------------------------------------------------------------------------------
#  Remove all files and MySQL Table entries corresponding to deleted organisms (@deletedFiles)
#---------------------------------------------------------------------------------------------

if (scalar @deletedFiles > 0) {
    print "Removing the deleted organisms from the Database...";

    my @del;
    foreach my $deleted (@deletedFiles) {
        my $fname;
        if ($deleted =~ /\//) {
            ($fname) = $deleted =~ /^\S+\/(\S+)\.\S+$/;

            if (grep { $_ eq $fname } @del) {
            }
            else {
                push @del, $fname;
            }
        }
        else {
            if (grep { $_ eq $deleted } @delOrgs) {
            }
            else {
                push @delOrgs, $deleted;
            }

            open DELLISTING, "<$bact{dataDir}/tmpListings/$deleted\.listing";
            while (<DELLISTING>) {
                chomp;

                my @column = split /\s+/;
                my $file   = $column[8];

                ($fname) = $file =~ /^(\S+)\.\S+$/;

                if (grep { $_ eq $fname } @del) {
                }
                else {
                    push @del, $fname;
                }
            }
            close DELLISTING;
        }
    }

    my $dsn = "DBI:mysql:host=$bact{host};database=$bact{database}";
    my $dbh = DBI->connect($dsn, $bact{dbuname}, $bact{dbpasswd})
      or die "Cannot connect to server\n";

    foreach my $fname (@del) {
        system
"rm $bact{dataDir}/genomes/$fname* $bact{dataDir}/geneseqs/backup/$fname $bact{dataDir}/geneseqs/$fname* $bact{dataDir}/aaseqs/$fname* $bact{dataDir}/gff_files/$fname";

        my $query = "SELECT protaccno, geneid FROM genedetails WHERE accno LIKE ?";
        my $sth   = $dbh->prepare($query);
        $sth->execute($fname);

        my (@protaccno, @geneid);
        while (my @data = $sth->fetchrow_array) {
            push @protaccno, $data[0];
            push @geneid,    $data[1];
        }
        $sth->finish;

        $query = "DELETE FROM taxid_accno WHERE accno=?";
        $sth   = $dbh->prepare($query);
        $sth->execute($fname);
        $sth->finish;

        $query = "DELETE FROM genedetails WHERE accno=?";
        $sth   = $dbh->prepare($query);
        $sth->execute($fname);
        $sth->finish;

        $query = "DELETE FROM geneseqs WHERE geneid=?";
        $sth   = $dbh->prepare($query);
        foreach my $gid (@geneid) {
            $sth->execute($gid);
        }
        $sth->finish;

        $query = "DELETE FROM aaseqs WHERE aaseqs=?";
        $sth   = $dbh->prepare($query);
        foreach my $paccno (@protaccno) {
            $sth->execute($paccno);
        }
        $sth->finish;
    }
    $dbh->disconnect;
    print "Done!\n";
}

my @dirs = ("genomes", "aaseqs", "geneseqs");

#---------------------------------------------------------------------------
#  If updates were found and new files were downloaded, do the following:
#  	1.	Run formatdb on the downloaded files
#   2.  Parse the GFF files and generate the tables
#   3.  Update the MySQL Tables
#   4.  Modiy the NT sequence preambles to include the GI number
#   5.  Update the NT sequence table
#   6.  Update the AA sequence table
#   7.  Update the current listings and delete the temporary files
#  Else
#  	Do nothing. Exit from the program.
#---------------------------------------------------------------------------

if ($check == 1) {

    #---------------------------------------------------------------------------
    #   1.  Run formatdb on downloaded files
    #---------------------------------------------------------------------------

    print "Updates found!\n\t1. Formatting the downloaded files...";
    foreach my $dir (@dirs) {
        next if ($dir =~ /gene/);
        chdir "$bact{dataDir}/$dir";

        foreach my $file (@downloaded) {
            system "formatdb -i $file"      if ($dir =~ /aaseqs/);
            system "formatdb -i $file -p F" if ($dir =~ /gen/);
        }
    }
    print "Done!\n";

    #---------------------------------------------------------------------------
    #  2.  Parse GFF Files and generate tables
    #---------------------------------------------------------------------------

    # Set the working directory
    chdir "$bact{dataDir}/tables";

    open(MAIN,  ">updatemain.tab");
    open(CHILD, ">updatechild.tab");

    print "\t2. Parsing the GFF files and generating the MySQL Tables...";

    # Iterate through the files
    foreach my $file (@downloaded) {

        # Open the file
        open(GFF, "$bact{dataDir}/gff_files/$file");
        my @gff = <GFF>;
        close(GFF);

        my ($pass, $track) = 0;

        my @coords;
        my ($printInMain) = "";

        # Iterate through the file, line by line
        foreach my $line (@gff) {
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

            my @Line = split /\t/, $line;    # Split the line at tab spaces(\t)

            if ($Line[2] =~ /source/ && $Line[8] =~ /organism/)
            { ## Pick the line which has the word 'source' in it. From this line, we extract the organism name
                chomp $Line[8];
                my @split = split /;/, $Line[8];

                next if ($split[0] =~ m/phage/i && $track > 0);

                chomp $Line[4];
                push @coords, $Line[4];

                if ($track == 0) {
                    my ($orgname, $chromosome, $tax_id, $strain, $subStrain, $plasmid, $subSp) = "";

                    foreach my $part (@split) {
                        ($orgname)    = $part =~ /organism=(.*)/      if ($part =~ /organism=/);
                        ($chromosome) = $part =~ /chromosome=(.*)/    if ($part =~ /chromosome=/);
                        ($tax_id)     = $part =~ /db_xref=taxon:(.*)/ if ($part =~ /taxon:/);
                        ($strain)     = $part =~ /strain=(.*)/        if ($part =~ /^strain=/);
                        ($plasmid)    = $part =~ /plasmid=(.*)/       if ($part =~ /plasmid=/);
                        ($subStrain)  = $part =~ /sub_strain=(.*)/    if ($part =~ /^sub_strain=/);
                        ($subSp)      = $part =~ /sub_species=(.*)/   if ($part =~ /sub_species=/);
                    }

                    chomp $orgname;
                    my $ORGNAME = "$orgname";

                    if ($subSp ne "") {
                        $ORGNAME .= " subsp. $subSp";
                    }
                    if ($strain ne "") {
                        unless ($orgname =~ /$strain/) {
                            $ORGNAME .= " str. $strain";
                        }
                    }
                    if ($subStrain ne "") {
                        unless ($orgname =~ /$subStrain/) {
                            $ORGNAME .= " substr. $subStrain";
                        }
                    }

                    if ($Line[8] =~ /chromosome=/) {
                        $printInMain = "$tax_id\t$file\t$ORGNAME chromosome $chromosome\t";
                    }
                    elsif ($Line[8] =~ /plasmid=/) {
                        $printInMain = "$tax_id\t$file\t$ORGNAME plasmid $plasmid\t";
                    }
                    else {
                        $printInMain = "$tax_id\t$file\t$ORGNAME\t";
                    }
                }
                $track++;
            }    # endif SOURCE

            if ($Line[2] =~ /CDS/)
            { # Pick the line which has the word 'CDS' in it. From this line, we extract the locus and gene product.
                $pass++;
                if ($pass == 1) {
                    print MAIN $printInMain, "$coords[-1]\n";
                }

                chomp $Line[8];
                my @split = split /;/, $Line[8];

                my ($locus, $gi, $product, $geneid, $prot_accno);
                foreach my $part (@split) {
                    ($locus) = $part =~ /locus_tag=(.*)/  if ($part =~ /locus_tag/);
                    ($gi)    = $part =~ /db_xref=GI:(.*)/ if ($part =~ /db_xref=GI:/);
                    if ($part =~ /note=/) {
                        ($product) = $part =~ /note=(.*)/;
                    }
                    elsif ($part =~ /product=/) {
                        ($product) = $part =~ /product=(.*)/;
                    }
                    ($geneid)     = $part =~ /ID=.*:(.*)\:.*/  if ($part =~ /ID=/);
                    ($prot_accno) = $part =~ /protein_id=(.*)/ if ($part =~ /protein_id/);
                    $prot_accno =~ s/\.[0-9]//g;
                }

                # Print to output file (print only the appropriate columns)
                print CHILD
"$file\t$prot_accno\t$gi\t$locus\t$geneid\t$Line[3]\t$Line[4]\t$Line[6]\t$product\n";
            }    # endif CDS
        }    # close foreach GFF file contents
    }    # close foreach all GFF files

    close MAIN;
    close CHILD;

    print "Done!\n";

    #---------------------------------------------------------------------------
    #    3.  Update the MySQL Tables
    #---------------------------------------------------------------------------

    my $dsn = "DBI:mysql:host=$bact{host};database=$bact{database}";
    my $dbh = DBI->connect($dsn, $bact{dbuname}, $bact{dbpasswd})
      or die "Cannot connect to server\n";

    print "\t3. Updating the MySQL tables...";

    my $query = $dbh->prepare($bact{mainTblupdate});
    $query->execute();

    $query = $dbh->prepare($bact{childTblupdate});
    $query->execute();

    print "Done!\n";

    #---------------------------------------------------------------------------
    #    4.  Modify the NT sequence preambles
    #---------------------------------------------------------------------------

    $query = $dbh->prepare($bact{getgeneids});

    chdir "$bact{dataDir}/geneseqs";

    print "\t4. Modifying the NT sequence preambles...";

    foreach my $file (@downloaded) {
        open FILE, "<$file";
        my @file = <FILE>;
        close FILE;

        my ($start, $end, $header);
        open OUTFILE, ">$file.mod";

        foreach my $line (@file) {
            chomp $line;
            if ($line =~ /^>/) {
                $query->execute($file);
                if ($line =~ /:c/) {
                    ($end, $start) = $line =~ /^>.*\|.*\|:c(.*)-(.*)$/;
                }
                else {
                    ($start, $end) = $line =~ /^>.*\|.*\|:(.*)-(.*)$/;
                }
                ($header) = $line =~ /^>(.*)/;
                while (my @row = $query->fetchrow_array()) {
                    my $End   = $row[2] + 3;
                    my $Start = $row[1] - 3;
                    if (   ($start == $row[1] && $end == $End)
                        || ($start == $Start && $end == $row[2]))
                    {
                        print OUTFILE ">gi\|$row[0]\|$header\n";
                        last;
                    }
                }
            }
            else {
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
    #   5.  Update NT sequence tables
    #---------------------------------------------------------------------------

    $query = $dbh->prepare($bact{ntSeqTblupdate});

    print "\t5. Update the NT sequence MySQL table...";

    chdir "$bact{dataDir}/geneseqs";

    foreach my $file (@downloaded) {
        open FILE, "$file";
        my @file = <FILE>;
        close FILE;

        my $track = 0;
        my ($geneid, $sequence);
        foreach my $line (@file) {
            if ($track == 1 && $line =~ /^>/) {
                $query->execute($sequence, $geneid);
                $track = 0;
            }
            chomp $line;
            ($geneid) = $line =~ /^>.*\|(.*)\|.*\|.*\|/ if ($line =~ /^>/);
            $track    = 1  if ($line =~ /^>/);
            $sequence = "" if ($line =~ /^>/);
            $sequence .= "$line\n";
        }
        $query->execute($sequence, $geneid);
    }
    print "Done!\n";

    #---------------------------------------------------------------------------
    #   6.  Update AA sequence table
    #---------------------------------------------------------------------------

    $query = $dbh->prepare($bact{aaSeqTblupdate});

    print "\t6. Update the AA sequence MySQL table...";

    chdir "$bact{dataDir}/aaseqs";

    foreach my $file (@downloaded) {
        open FILE, "$file";
        my @file = <FILE>;
        close FILE;

        my $track = 0;
        my ($protaccno, $sequence);
        foreach my $line (@file) {
            if ($track == 1 && $line =~ /^>/) {
                $query->execute($sequence, $protaccno);
                $track = 0;
            }
            ($protaccno) = $line =~ /^>.*\|.*\|.*\|(.*)\.[0-9]\|/ if ($line =~ /^>/);
            $track    = 1  if ($line =~ /^>/);
            $sequence = "" if ($line =~ /^>/);
            $sequence .= $line;
        }
        $query->execute($sequence, $protaccno);
    }

    $dbh->disconnect;

    print "Done!\n";

    #---------------------------------------------------------------------------
    #   7.  Update current listings and delete temporary files
    #---------------------------------------------------------------------------

    print "\t7. Update the current listings and delete temporary files...";

    foreach my $folder (@foldernames) {
        system "cp $bact{dataDir}/tmpListings/$folder.listing $bact{dataDir}/listings/.";
    }

    foreach my $folder (@deletedFiles) {
        if ($folder =~ /\//) {
            $folder =~ s/^(\S+)\/\S+\.\S+$/$1/gs;
        }
        system "rm $bact{dataDir}/listings/$folder.listing";
    }

    open DBSTATUS, ">$bact{dataDir}/dbstatus/updateReport";

    my $content = '<p class="bodypara">Update Status: </p>
	<p class="bodypara">Organisms with updated sequence information</p>
	';
    $content .= '<ul class="bodypara">
	';
    if (scalar @origDwnld > 0) {
        foreach my $org (@origDwnld) {
            $content .= '<li><span style="font-style:italic">' . $org . '</span></li>';
        }
    }
    else {
        $content .= '<li>NULL</li>
		';
    }
    $content .= "\n</ul>";

    $content .= '
	<p class="bodypara">New organisms added to the repository</p>
	';
    $content .= '<ul class="bodypara">
	';
    if (scalar @newDwnld > 0) {
        foreach my $org (@newDwnld) {
            $content .= '<li><span style="font-style:italic">' . $org . '</span></li>';
        }
    }
    else {
        $content .= '<li>NULL</li>
		';
    }
    $content .= "\n</ul>";

    $content .= '
	<p class="bodypara">Organisms removed from the repository</p>
	';
    $content .= '<ul class="bodypara">
	';
    if (scalar @delOrgs > 0) {
        foreach my $org (@delOrgs) {
            $content .= '<li><span style="font-style:italic">' . $org . '</span></li>';
        }
    }
    else {
        $content .= '<li>NULL</li>
		';
    }
    $content .= "\n</ul>";

    print DBSTATUS $content;

    close DBSTATUS;

    #	system "rm -rf $bact{dataDir}/tmpListings/*";

    print "Done!\n";
    print "Update complete.\nThank you for using the updater.\n";
}
else {
    print "No updates found!\nThank you for using the updater.\n";
}
exit;
