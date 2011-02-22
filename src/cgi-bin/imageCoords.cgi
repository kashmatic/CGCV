#! /usr/bin/perl 
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

#################################################################################
##
## Author  => Kashi V Revanna
## Company => The Center for Genomics and Bioinformatics
## Contact => biohelp@cgb.indiana.edu
## Written => 14th Nov 2008
##
##################################################################################

use strict;
use warnings;

## Modules
use GD;
use POSIX qw(floor ceil);
use DBI;
use Getopt::Std;

use lib qw(PACKAGENAME);
use DB;

my %options;
getopt( "g:s:e:d:D:E:I:", \%options );
## Get the parameters
my $genome = $options{g};
my $start  = $options{s};
my $end    = $options{e};
my $dir    = $options{d};
my $dbtype = $options{D};
my $evalue = $options{E};
my $imgId  = $options{I};

## To get the blast parse file loaded
my $uploadDir = '_____UPLOAD_____';
my $parsedBlastFile = $uploadDir . $dir . '/parsedBlastOutput';

## Get the lines from parse file
open( FILE, $parsedBlastFile );
my @parsedBlastOutput = <FILE>;
close(FILE);

## Connection to get the gene length and description
my %genomeInfo;

my $array;
eval {
    $array =
      DB->exec( "SELECT seqlength FROM taxid_accno WHERE accno like ?",[$genome] );
};
displayErrorPage("Unable to read database") if ($@);

my $genomeLength;

foreach (@$array) {
    $genomeLength = @$_[0];
}

## check the start and end of the genome
$start = 0 if ( $start == 1);

$end = $genomeLength if ( $genomeLength < $end );


## DB connection to get gene details
eval {
    $array = DB->exec(
"SELECT protaccno, geneid, synonym, start, end, strand, description FROM genedetails WHERE accno like ? AND ( ( start > ? AND end < ? ) OR ( start > ? AND start < ? ) OR ( end > ? AND end < ? ) OR ( start < ? AND end > ? ) ) ORDER BY end",
        [ $genome, $start, $end, $start, $end, $start, $end, $start, $end ]
    );
};

## Load gene details
my %dataInfo;

my $num = 0;

foreach (@$array) {
    $num++;
    $dataInfo{$num}{"protaccno"} = @$_[0];
    $dataInfo{$num}{"geneid"}    = @$_[1];
    $dataInfo{$num}{"syn"}       = ( @$_[2] eq "NULL" ) ? '' : @$_[2];
    $dataInfo{$num}{"start"}     = @$_[3];
    $dataInfo{$num}{"end"}       = @$_[4];
    $dataInfo{$num}{"strand"}    = @$_[5];
    $dataInfo{$num}{"desc"}      = @$_[6];
}

my @genes;
my %order;
my $test;
my $x;

## parse the blast parse file to load into hash
foreach my $load (@parsedBlastOutput) {
    chomp $load;
    my @get = split( ',', $load );    ## Split each line

    $x = 0;
    next if ( $get[6] > $evalue );
    if ( $get[0] eq $genome ) {       ## search for the genome
        my @loc = split( /\.\.\./, $get[3] );
        $test .= "<"
          . $loc[0] . "-- "
          . $loc[1] . "-- "
          . $loc[2] . "-- "
          . $loc[3] . "> ";
        if (
            (
                   ( $loc[2] > $start )
                && ( $loc[3] < $end )    ## hit start more than start
            )                            ## hit end less than end
            || (
                   ( $loc[2] > $start )
                && ( $loc[2] < $end )    ## hit start more than start
            )                            ## hit start less than end
            || (   ( $loc[3] > $start )
                && ( $loc[3] < $end )
            )    ## hit end more than start, less than end
            || (   ( $start > $loc[2] )
                && ( $end < $loc[3] ) )    ## start more than hit start,
          )                                ## end less than hit end
        {
            if ( $loc[2] < $loc[3] ) {
                $genomeInfo{ $get[1] }{ $get[2] }{"start"}  = $loc[2];
                $genomeInfo{ $get[1] }{ $get[2] }{"end"}    = $loc[3];
                $genomeInfo{ $get[1] }{ $get[2] }{"strand"} = '+';
            }
            else {
                $genomeInfo{ $get[1] }{ $get[2] }{"start"}  = $loc[3];
                $genomeInfo{ $get[1] }{ $get[2] }{"end"}    = $loc[2];
                $genomeInfo{ $get[1] }{ $get[2] }{"strand"} = '-';
            }
            $genomeInfo{ $get[1] }{ $get[2] }{"qstart"} = $loc[0];
            $genomeInfo{ $get[1] }{ $get[2] }{"qend"}   = $loc[1];
            $genomeInfo{ $get[1] }{ $get[2] }{"hit"}    = $get[5];
            $genomeInfo{ $get[1] }{ $get[2] }{"id"}     = $get[1];
            $genomeInfo{ $get[1] }{ $get[2] }{"evalue"} = $get[6];

            push( @genes, $get[1] );

            $order{ $get[1] } =
              $get[4] % 64;    ## 64 is number of colors available
        }
    }
}

my $length = $end - $start;


## fixed parameters ---------------------------------------------------
my $width  = 990;
my $height = 160;

my $padding     = 20;    ## padding left and right
my $top_padding = 20;    ## padding on top
my $genome_bar  = 30;    ## thickness of genome
my $gene_bar    = 15;    ## thickness of gene
my $arrow_tip   = 15;    ## shape of the arrow
##----------------------------------------------------------------


## get each gene
my $i = 80;

my $posi = 80;

#$image->string(gdTinyFont,5,$posi+10,'Query Sequences',$black);
my $gap;

## create imagemap for each query
my $mapfile = "$uploadDir$dir/imageMap$genome";
open( MAP, ">", $mapfile ) or warn("Unable to open mapFile");

## print query
my $geneLine = 3;
print_query( \%genomeInfo );

close(MAP);

exit;
1;

########################################################################################
# subroutine to print query

sub print_query {
    my %genomeInfo = %{ (shift) };

    ## get the space for each gene
    my $position = $posi + 20;
    $gap = 5;
    my $bar = $gene_bar;
    my %nextInfo;

	## Create an array of 0s
    my @array;
    for ( my $i = 0 ; $i < $width ; $i++ ) {
        $array[$i] = 0;
    }

    for my $k ( keys %genomeInfo ) {

        ## foreach hit start and hit end
        for my $v ( keys %{ $genomeInfo{$k} } ) {

		## Get the start, end and strand of the query
            my $hs    = $genomeInfo{$k}{$v}{"start"};
            my $hsend = floor(( ( $hs - $start ) / $length ) * ( $width - ( 2 * $padding ) ) ) + $padding;

            my $he    = $genomeInfo{$k}{$v}{"end"};
            my $heend =
              $width - floor(
                ( ( $end - $he ) / $length ) * ( $width - ( 2 * $padding ) ) ) -
              $padding;

            my $a = $genomeInfo{$k}{$v}{"strand"};

		## Get the start and end of the query
            my $mystart = ( $hsend < 1 )      ? 1          : $hsend;
            my $myend   = ( $heend > $width ) ? $width - 1 : $heend;

		## Create a small array out of the original 'array' representing the query.
		my @checkArray = @array;
		@checkArray = splice(@checkArray,$mystart,$myend-$mystart);

		## Check if there are any 1s in the given array which represent the query.
		## If copy this query to another hash, termed remaining queries
		if (grep(/1/,@checkArray)){
                $nextInfo{$k}{$v}{"start"}  = $genomeInfo{$k}{$v}{"start"};
                $nextInfo{$k}{$v}{"end"}    = $genomeInfo{$k}{$v}{"end"};
                $nextInfo{$k}{$v}{"strand"} = $genomeInfo{$k}{$v}{"strand"};
                $nextInfo{$k}{$v}{"qstart"} = $genomeInfo{$k}{$v}{"qstart"};
                $nextInfo{$k}{$v}{"qend"}   = $genomeInfo{$k}{$v}{"qend"};
                $nextInfo{$k}{$v}{"hit"}    = $genomeInfo{$k}{$v}{"hit"};
                $nextInfo{$k}{$v}{"evalue"} = $genomeInfo{$k}{$v}{"evalue"};
                next;
            }

		## Enter 1 into the array of 0s which actually mean there is a query here.
            my @swap;
            my $p   = $mystart;
            my $len = $myend - $mystart + 1;
            my $i = 0;
            while ( $i < $len ) { push( @swap, 1 ); $i++; }
            splice( @array, $p, $len, @swap );

		## Create the polygon object
            my $poly = new GD::Polygon;

		## Determine the width of the arrow tip
            my $dist = $heend - $hsend;
            my $moveTip = 0.50 * ( $myend - $mystart );
            if ( $moveTip > $arrow_tip ) {
                $moveTip = $arrow_tip;
            }

            my $x = $position + $bar;
            $k =~ s/ /-/g;

		## Create link to display the blast alignment
            my $blastAlnLink =
                '/cgi-bin/cgcv/blastAlignment.cgi?query=' . $k . '&hit='
              . $genomeInfo{$k}{$v}{"hit"}
              . '&start='
              . $genomeInfo{$k}{$v}{"qstart"} . '&end='
              . $genomeInfo{$k}{$v}{"qend"} . '&dir='
              . $dir
              . '&dbtype='
              . $dbtype;

		## Write the map information into the file
            print MAP '<AREA Shape="rect" Coords="', $hsend, ',', $position,
              ',', $heend, ',', $x,

              '" Href="/cgi-bin/cgcv/blastAlignment.cgi?query=',
	      $k,
	      '&hit=',
	      $genomeInfo{$k}{$v}{"hit"},
	      '&start=',
	      $genomeInfo{$k}{$v}{"qstart"},
	      '&end=',
              $genomeInfo{$k}{$v}{"qend"},
	      '&dir=',
	      $dir,
	      '&dbtype=',
	      $dbtype,
              '" onmouseover="return overlib(\'E value: ',$genomeInfo{$k}{$v}{"evalue"}, '<br>Genomic Position: (',$hs, ', ', $he,')<br>Click <a href=\\\'javascript:showZoom(', $imgId, ', ', $hs, ', ', $he,', ', $genomeLength, ', ', $genomeInfo{$k}{$v}{"evalue"},')\\\'>HERE</a> to zoom into the neighborhood. <br> Click <a href=\\\'',$blastAlnLink,'\\\'>HERE</a> to view the alignment.\', CAPTION, \'', $k, '  \', CENTER, ADAPTIVE_WIDTH,STICKY);" onmouseout="return nd();"',
              '>',
	       "\n";

		## delete the just drawn query
            delete $genomeInfo{$k}{$v};
        }
    }
    
		## count the number of keys in the remaining query
    my @key = keys %nextInfo;
    my $y   = $#key;

	## Count the number of lines that can be drawn 
	## if there are any queries remaining, call the same subroutine
	$geneLine--;
	if( ($geneLine > 0) && ($y >= 0) ){ $posi+=20; print_query(\%nextInfo);}
                       
}

sub displayErrorPage{
        ## Display error webpage  if the upload file is not a BLAST output file
        my $cgi = new CGI;
        my $content = '
      <h4>Error</h4>
      <p class="bodypara">Sorry, We have encountered an error. 
      Please contact the CGCV Developer Team at 
      <a href="mailto:Qunfeng.Dong@unt.edu">
      Qunfeng.Dong@unt.edu
      </a> with the message you have received below and a brief description of what led you to this problem. 
      We will be glad to make BOV better and better. <br>
      <br>
      Thank you, <br>
      <strong>CGCV Team.</strong>
      <br>
      </p>

      <p class="bodypara">
      Message:<br>
    ';
  
        $content .= '<span style="color:red;" class="bodypara">';
        $content .= shift;
        $content .= '</span>
    </p>';

  print $cgi->header;
        my $template =  HTML::Template->new(filename => "templates/main.tmpl");

  $template->param(TITLE => "ERROR");
        $template->param(CONTENT => $content);
        
  print $template->output;
        print $cgi->end_html();
        exit;
}