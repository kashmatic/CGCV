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
use CGI;
use GD;
use POSIX qw(floor ceil);
use DBI;

use lib qw(PACKAGENAME);
use DB;

my $cgi = new CGI;

## Get the parameters
my $genome = $cgi->param('genome');
my $start = $cgi->param('start');
my $end = $cgi->param('end');
my $dir = $cgi->param('dir');
my $dbtype = $cgi->param('dbtype');
my $evalue = $cgi->param('evalue');
my $imgId = $cgi->param('imgId');


## To get the blast parse file loaded 
my $uploadDir = '_____UPLOAD_____';
my $parsedBlastFile = $uploadDir.$dir.'/parsedBlastOutput';

## Get the lines from parse file
open (FILE, $parsedBlastFile);
my @parsedBlastOutput = <FILE>;
close (FILE);

## Connection to get the gene length and description
my %genomeInfo;

my $array;
eval {
	$array = DB->exec("SELECT seqlength FROM taxid_accno WHERE accno like ?",[$genome]);
};
displayErrorPage("Unable to read database") if ($@);

my $genomeLength;

foreach (@$array){
	$genomeLength = @$_[0];
}


## check the start and end of the genome
$start = 0 if ( $start == 1);

$end = $genomeLength if ( $genomeLength < $end );


## DB connection to get gene details
eval {
	$array = DB->exec("SELECT protaccno, geneid, synonym, start, end, strand, description FROM genedetails WHERE accno like ? AND ( ( start > ? AND end < ? ) OR ( start > ? AND start < ? ) OR ( end > ? AND end < ? ) OR ( start < ? AND end > ? ) ) ORDER BY end", [$genome, $start, $end, $start, $end, $start, $end, $start, $end]);
};
displayErrorPage("Unable to read database") if ($@);


## Load gene details
my %dataInfo;

my $num =0;

foreach (@$array){
	$num++;
	$dataInfo{$num}{"protaccno"}=@$_[0];
	$dataInfo{$num}{"geneid"}=@$_[1];
	$dataInfo{$num}{"syn"}=(@$_[2] eq "NULL")?'':@$_[2];
	$dataInfo{$num}{"start"}=@$_[3];
	$dataInfo{$num}{"end"}=@$_[4];
	$dataInfo{$num}{"strand"}=@$_[5];
	$dataInfo{$num}{"desc"}=@$_[6];
}

my @genes;
my %order;
my $x;

## parse the blast parse file to load into hash
foreach my  $load(@parsedBlastOutput){
	chomp $load;
        my @get = split(',', $load);    ## Split each line

	$x = 0;
	next if ($get[6] > $evalue);
        if ($get[0] eq $genome) {       ## search for the genome
                my @loc = split(/\.\.\./,$get[3]);
                if (
                        (
                                ($loc[2]>$start) && ($loc[3]<$end)      ## hit start more than start
                        )                                       ## hit end less than end
                        ||
                        (
                                ($loc[2]>$start) && ($loc[2]<$end)      ## hit start more than start
                        )                                       ## hit start less than end
                        ||
                        ( ($loc[3]>$start) && ($loc[3]<$end) )  ## hit end more than start, less than end
                        ||
                        ( ($start>$loc[2]) && ($end<$loc[3]) )  ## start more than hit start,
                )                                       ## end less than hit end
                {
                        if ($loc[2] < $loc[3]){
                                $genomeInfo{$get[1]}{$get[2]}{"start"}=$loc[2];
                                $genomeInfo{$get[1]}{$get[2]}{"end"}=$loc[3];
                                $genomeInfo{$get[1]}{$get[2]}{"strand"}='+';
                        } else {
                                $genomeInfo{$get[1]}{$get[2]}{"start"}=$loc[3];
                                $genomeInfo{$get[1]}{$get[2]}{"end"}=$loc[2];
                                $genomeInfo{$get[1]}{$get[2]}{"strand"}='-';
                        }
			$genomeInfo{$get[1]}{$get[2]}{"qstart"}=$loc[0];
			$genomeInfo{$get[1]}{$get[2]}{"qend"}=$loc[1];
			$genomeInfo{$get[1]}{$get[2]}{"hit"}=$get[5];
                        $genomeInfo{$get[1]}{$get[2]}{"id"} = $get[1];
			$genomeInfo{$get[1]}{$get[2]}{"evalue"} = $get[6];
			
			push (@genes, $get[1] );

                        $order{$get[1]} = $get[4]%64;	## 64 is number of colors available
                }
        }
}

my $length = $end - $start;

## -- ## -- ## -- ## -- ## -- ## -- ## -- ## -- ## -- ## -- ## -- ## -- 
print "Content-type: image/png\n\n";


## fixed parameters ---------------------------------------------------
my $width = 990;
my $height = 160;	

my $padding= 20;	## padding left and right
my $top_padding = 20;	## padding on top
my $genome_bar = 30;	## thickness of genome 
my $gene_bar = 15;	## thickness of gene
my $arrow_tip = 15;	## shape of the arrow
##----------------------------------------------------------------

## basic colors  --------------------------------------------------------
my $image = new GD::Image($width, $height);
my $white = $image->colorAllocate(225,255,255);
my $black = $image->colorAllocate(0,0,0);
my $red = $image->colorAllocate(225,0,0);
my $blue = $image->colorAllocate(0,0, 225);
my $teal = $image->colorAllocate(0,128,128);
my $lavender = $image->colorAllocate(230,230,250);

## colors taken from http://en.wikipedia.org/wiki/Web_colors
my @color;
push(@color, $image->colorAllocate(220, 20, 60));	## crimson
push(@color, $image->colorAllocate(139, 0, 139));	## dark magenta
push(@color, $image->colorAllocate(128, 128, 0));	## olive
push(@color, $image->colorAllocate(47, 79, 79));	## dark slate gray
push(@color, $image->colorAllocate(0, 0, 139));		## dark blue
push(@color, $image->colorAllocate(244, 164, 96)); 	## SandyBrown
push(@color, $image->colorAllocate(178, 34, 34));	## FireBrick
push(@color, $image->colorAllocate(169, 169, 169)); 	## DarkGray
push(@color, $image->colorAllocate(255, 99, 71)); 	## Tomato
push(@color, $image->colorAllocate(128, 0, 128)); 	## Purple
push(@color, $image->colorAllocate(46, 139, 87)); 	## SeaGreen
push(@color, $image->colorAllocate(205, 133, 63)); 	## Peru
push(@color, $image->colorAllocate(176, 196, 222)); 	## LightSteelBlue
push(@color, $image->colorAllocate(250, 128, 114)); 	## Salmon
push(@color, $image->colorAllocate(240, 230, 140)); 	## Khaki
push(@color, $image->colorAllocate(135, 206, 235)); 	## SkyBlue
push(@color, $image->colorAllocate(128, 0, 0));		## Maroon
push(@color, $image->colorAllocate(255, 0, 255)); 	## Fuchsia
push(@color, $image->colorAllocate(25, 25, 112)); 	## MidnightBlue
push(@color, $image->colorAllocate(192, 192, 192)); 	## Silver
push(@color, $image->colorAllocate(255, 215, 0)); 	## Gold
push(@color, $image->colorAllocate(0, 100, 0)); 	## DarkGreen
push(@color, $image->colorAllocate(95, 158, 160)); 	## CadetBlue
push(@color, $image->colorAllocate(216, 191, 216)); 	## Thistle
push(@color, $image->colorAllocate(255, 165, 0)); 	## Orange
push(@color, $image->colorAllocate(70, 130, 180)); 	## SteelBlue
push(@color, $image->colorAllocate(211, 211, 211)); 	## LightGrey
push(@color, $image->colorAllocate(210, 105, 30)); 	## Chocolate
push(@color, $image->colorAllocate(0, 206, 209)); 	## DarkTurquoise
push(@color, $image->colorAllocate(189, 183, 107)); 	## DarkKhaki
push(@color, $image->colorAllocate(0, 139, 139)); 	## DarkCyan
push(@color, $image->colorAllocate(210, 180, 140)); 	## Tan
push(@color, $image->colorAllocate(148, 0, 211)); 	## DarkViolet
push(@color, $image->colorAllocate(205, 92, 92)); 	## IndianRed
push(@color, $image->colorAllocate(138, 43, 226)); 	## BlueViolet
push(@color, $image->colorAllocate(85, 107, 47)); 	## DarkOliveGreen
push(@color, $image->colorAllocate(220, 220, 220)); 	## Gainsboro
push(@color, $image->colorAllocate(188, 143, 143)); 	## RosyBrown
push(@color, $image->colorAllocate(100, 149, 237)); 	## CornflowerBlue
push(@color, $image->colorAllocate(255, 0, 255)); 	## Magenta
push(@color, $image->colorAllocate(255, 182, 193)); 	## LightPink
push(@color, $image->colorAllocate(0, 191, 255)); 	## DeepSkyBlue
push(@color, $image->colorAllocate(107, 142, 35)); 	## OliveDrab
push(@color, $image->colorAllocate(72, 61, 139)); 	## DarkSlateBlue
push(@color, $image->colorAllocate(218, 165, 32)); 	## Goldenrod
push(@color, $image->colorAllocate(255, 20, 147)); 	## DeepPink
push(@color, $image->colorAllocate(64, 224, 208)); 	## Turquoise
push(@color, $image->colorAllocate(34, 139, 34)); 	## ForestGreen
push(@color, $image->colorAllocate(165, 42, 42)); 	## Brown
push(@color, $image->colorAllocate(119, 136, 153)); 	## LightSlateGray
push(@color, $image->colorAllocate(238, 130, 238)); 	## Violet
push(@color, $image->colorAllocate(173, 216, 230)); 	## LightBlue
push(@color, $image->colorAllocate(154, 205, 50)); 	## YellowGreen
push(@color, $image->colorAllocate(160, 82, 45)); 	## Sienna
push(@color, $image->colorAllocate(106, 90, 205)); 	## SlateBlue
push(@color, $image->colorAllocate(143, 188, 143)); 	## DarkSeaGreen
push(@color, $image->colorAllocate(75, 0, 130)); 	## Indigo
push(@color, $image->colorAllocate(233, 150, 122)); 	## DarkSalmon
push(@color, $image->colorAllocate(30, 144, 255)); 	## DodgerBlue
push(@color, $image->colorAllocate(255, 160, 122)); 	## LightSalmon
push(@color, $image->colorAllocate(128, 128, 128)); 	## Gray
push(@color, $image->colorAllocate(255, 105, 180)); 	## HotPink
push(@color, $image->colorAllocate(32, 178, 170)); 	## LightSeaGreen
push(@color, $image->colorAllocate(95, 158, 160)); 	## CadetBlue

$image->transparent($white);

## this helps to get the different width ----------------------------
$image->filledRectangle($padding,$top_padding+5,$width-$padding,$genome_bar, $black);

$image->string(gdTinyFont,$padding-15,0,'Genome',$red);

## write the line and value of start ----------------------------
if ( $start == 0 ){
	$image->string(gdMediumBoldFont, $padding-5, 5, "1", $black);
} else {
	$image->string(gdMediumBoldFont, $padding-5, 5, $start, $black);
}

$image->line( 	$padding, 20,
		$padding, $genome_bar,
		$black
		);

## wrtie the line and value of end
$image->string(gdMediumBoldFont, $width-$padding-30, 5, $end, $black);
$image->line(   $width-$padding, 20,
		$width-$padding, $genome_bar,
		$black
		);

##-----------------------------------------------------------------

## Drawing genes -------------------------------

## get each gene
my $i = 80;

my $posi = 80;
$image->string(gdTinyFont,5,$posi+10,'Query Sequences',$red);
my $gap;

## create imagemap for each query
my $mapfile = $uploadDir.$dir."/imageMap".$cgi->param('genome');
open(MAP, ">", $mapfile) or displayErrorPage("Unable to open mapFile");

## print query 
my $geneLine = 3;
print_query(\%genomeInfo);

#---------------------------------------------------

## Drawing the genes of the given genome

$posi = 50;
$image->string(gdTinyFont,5,$posi-13,'Annotated Genes',$red);
print_gene(\%dataInfo);
close (MAP);

#------------------------------------------------------------------

## printing lines 
## Number of divisions and smaller divisions
my $division = 10;
my $smalldiv = 10;

## get the position for each division
my $pos = (($width-($padding*2))/$division);
my $smallpos = $pos/$smalldiv;
## get teh value for each diviion
my $div_value = floor($length/$division);

my $val;
for (my $i = 1; $i < $division; $i ++ ){
	## increase value every iteration
	$val += $div_value;
	## calculate the postion
	my $linepos = ($pos*$i)+$padding;
	## print the line
	$image->line(   $linepos, 20, $linepos, $genome_bar, $black );
	## print the value
	$image->string(gdMediumBoldFont, $linepos-10, 5, $val+$start,$black);
}
##---------------------------------------------------------------------
	

## print the image
print $image->png;

exit;
1;

#########################################################################
## subroutine to print gene

sub print_gene {
	my %dataInfo = %{(shift)};
	my %nextLine;

	my $band = 42;
	my $layer = 6;
	my $nextLayer = $band/$layer;
	my $bar = $layer-2; ##$gene_bar;
	my $gap = 1;
	my $tag = 0;
	my $font;

	my $position = $posi;

	## Count the number of gff genes to determine the number of lines and its thickness
	my $count = keys %dataInfo;
	if ( ($count <= 1000) && ($count > 500)) {
		$band = 40;
		$layer = 5;
		$nextLayer = $band/$layer;	## 8 
		$bar = $nextLayer - 2;		## 6
		$gap = 1;
	} elsif ( ($count <= 500) && ($count > 100)) {
		$band = 40;
		$layer = 4;
		$nextLayer = $band/$layer;	## 10
		$bar = $nextLayer - 3;		## 7
		$gap = 2;
	} elsif ($count < 100){
		$band = 42;
		$layer = 3;
		$nextLayer = $band/$layer;	## 14
		$bar = $nextLayer - 5;		## 10
		$gap = 3;
		$tag = 1;
		if ($count < 20){
			$tag=2;
		}
	}


	for my $v ( sort keys %dataInfo) {

		## Get the start, end and strand of the query
		my $hs = $dataInfo{$v}{"start"};
		my $hsend = floor((($hs-$start)/$length)*($width-(2*$padding))) + $padding;

		my $he = $dataInfo{$v}{"end"};
		my $heend = $width - floor((($end-$he)/$length)*($width-(2*$padding)))-$padding;

		my $a = $dataInfo{$v}{"strand"};

		my $poly = new GD::Polygon;

		## Determine the width of the arrow tip
		my $dist = $heend - $hsend;
		my $moveTip = 0.50 * ($heend - $hsend);
		if ( $moveTip > $arrow_tip ){
			$moveTip = $arrow_tip;
		}

		## Display the map information if there are only 100 gff genes in the image.
		if ($count < 100){
			my $x = $position+$bar;
			
			my $seqInfoLink = '/cgi-bin/cgcv/getSequence.cgi?gene='.$v.'&genome='.$genome.'&protaccno='.$dataInfo{$v}{"protaccno"}.'&geneid='.$dataInfo{$v}{"geneid"}.'&dir='.$dir;
			
			print MAP '<AREA Shape="rect" Coords="',
				$hsend,',',$position,',',
				$heend,',',$x,
				'" Href="/cgi-bin/cgcv/getSequence.cgi?gene=',
				$v,
				'&genome=',
				$genome,		
				'&protaccno=',
				$dataInfo{$v}{"protaccno"},
				'&geneid=',
				$dataInfo{$v}{"geneid"},
				'&dir=',
				$dir,
				'" onmouseover="return overlib(\'GI: '.$dataInfo{$v}{"geneid"}.'<br>Genomic Position: ('.$hs.', '.$he.')<br>Click <a href=\\\''.$seqInfoLink.'\\\'>HERE</a> to view Gene details.\', STICKY, CAPTION, \''.$dataInfo{$v}{"desc"}.'   \', CENTER, ADAPTIVE_WIDTH);" onmouseout="return nd();"',
				'>',
				"\n";
		}

		## To display GFF information
		if ($tag){
			if ($tag == 2){
			$image->string(gdTinyFont, 
				$hsend, 
				$position-6, 
				$dataInfo{$v}{"syn"}." GI:".$dataInfo{$v}{"geneid"}."",
				$black);
			} else {
				$image->string(gdTinyFont, $hsend, $position-6, $dataInfo{$v}{"syn"},$black);
			}
		}
		
		## Draw the arrows, polygon w.r.t strand
		if ($a eq "+"){
			my $x = $heend - $moveTip;
			$poly->addPt(   $hsend, $position+$gap);
			$poly->addPt(   $x,     $position+$gap);
			$poly->addPt(   $x,     $position);
			$poly->addPt(   $heend, $position+($bar/2));
			$poly->addPt(   $x,     $position+$bar);
			$poly->addPt(   $x,     $position+$bar-$gap);
			$poly->addPt(   $hsend, $position+$bar-$gap);

			$image->filledPolygon($poly,$teal);
		} elsif ($a eq "-"){
			my $y = $hsend + $moveTip;
			$poly->addPt(   $hsend, $position+($bar/2));
			$poly->addPt(   $y,     $position);
			$poly->addPt(   $y,     $position+$gap);
			$poly->addPt(   $heend, $position+$gap);
			$poly->addPt(   $heend, $position+$bar-$gap);
			$poly->addPt(   $y,     $position+$bar-$gap);
			$poly->addPt(   $y,     $position+$bar);

			$image->filledPolygon($poly,$teal);
		}

		## delete the drawn gene
		delete $dataInfo{$v};
		$position += $nextLayer;
		if ($position == ($posi+$band) ){ $position = $posi;}
	}
}

########################################################################################
# subroutine to print query

sub print_query {
	my %genomeInfo = %{(shift)};

	## get the space for each gene
	my $position = $posi+20;
	$gap = 5;
	my $bar = $gene_bar;
	my %nextInfo;

	## Create an array of 0s
	my @array;
	for (my $i=0; $i < $width; $i++){
		$array[$i] = 0;
	}

	for my $k ( keys %genomeInfo) {

		## foreach hit start and hit end
		for my $v ( keys %{$genomeInfo{$k}}) {

			## Get the start, end and strand of the query
			my $hs = $genomeInfo{$k}{$v}{"start"};
			my $hsend = floor((($hs-$start)/$length)*($width-(2*$padding))) + $padding;

			my $he = $genomeInfo{$k}{$v}{"end"};
			my $heend = $width - floor((($end-$he)/$length)*($width-(2*$padding))) - $padding;

			my $a = $genomeInfo{$k}{$v}{"strand"};

			## Get the start and end of the query
			my $mystart = ($hsend < 1 )? 1:$hsend;
			my $myend = ($heend > $width)? $width-1:$heend;

			## Create a small array out of the original 'array' representing the query.
			my @checkArray = @array;
			@checkArray = splice(@checkArray,$mystart,$myend-$mystart);

			## Check if there are any 1s in the given array which represent the query.
			## If copy this query to another hash, termed remaining queries
			if (grep(/1/,@checkArray)){
				$nextInfo{$k}{$v}{"start"}=$genomeInfo{$k}{$v}{"start"};
				$nextInfo{$k}{$v}{"end"}=$genomeInfo{$k}{$v}{"end"};
				$nextInfo{$k}{$v}{"strand"}=$genomeInfo{$k}{$v}{"strand"};
				$nextInfo{$k}{$v}{"qstart"}=$genomeInfo{$k}{$v}{"qstart"};
				$nextInfo{$k}{$v}{"qend"}=$genomeInfo{$k}{$v}{"qend"};
				$nextInfo{$k}{$v}{"hit"}=$genomeInfo{$k}{$v}{"hit"};
				$nextInfo{$k}{$v}{"evalue"}=$genomeInfo{$k}{$v}{"evalue"};
				next;
			}

			## Enter 1 into the array of 0s which actually mean there is a query here.
			my @swap;
			my $p = $mystart; 
			my $len = $myend - $mystart + 1; 
			my $i = 0;
			while($i < $len){       push(@swap,1);$i++;}
			splice(@array,$p,$len,@swap);

			## Create the polygon object
			my $poly = new GD::Polygon;

			## Determine the width of the arrow tip
			my $dist = $heend - $hsend;
			my $moveTip = 0.50 * ($myend - $mystart);
			if ( $moveTip > $arrow_tip ){
				$moveTip = $arrow_tip;
			}

			my $x = $position+$bar;
			$k =~ s/ /-/g;

			## Create link to display the blast alignment
			my $blastAlnLink = '/cgi-bin/cgcv/blastAlignment.cgi?query='.$k.'&hit='.$genomeInfo{$k}{$v}{"hit"}.'&start='.$genomeInfo{$k}{$v}{"qstart"}.'&end='.$genomeInfo{$k}{$v}{"qend"}.'&dir='.$dir.'&dbtype='.$dbtype;

			## Write the map information into the file
			print MAP '<AREA Shape="rect" Coords="',
				$hsend,',',$position,',',
				$heend,',',$x,
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

			## Display the name of the query
			$image->string(gdTinyFont, $hsend, $position-6, substr($k,0,$dist/5), $black);
			
			## Draw the arrows, polygon w.r.t strand
			if ($a eq "+"){
				my $x = $heend - $moveTip;
				$poly->addPt(   $hsend, $position+$gap);
				$poly->addPt(   $x,     $position+$gap);
				$poly->addPt(   $x,     $position);
				$poly->addPt(   $heend, $position+($bar/2));
				$poly->addPt(   $x,     $position+$bar);
				$poly->addPt(   $x,     $position+$bar-$gap);
				$poly->addPt(   $hsend, $position+$bar-$gap);

				$image->filledPolygon($poly,$color[$order{$k}]);
			} elsif ($a eq "-"){
				my $y = $hsend + $moveTip;
				$poly->addPt(   $hsend, $position+($bar/2));
				$poly->addPt(   $y,     $position);
				$poly->addPt(   $y,     $position+$gap);
				$poly->addPt(   $heend, $position+$gap);
				$poly->addPt(   $heend, $position+$bar-$gap);
				$poly->addPt(   $y,     $position+$bar-$gap);
				$poly->addPt(   $y,     $position+$bar);

				$image->filledPolygon($poly,$color[$order{$k}]);
			}
			## delete the just drawn query
			delete $genomeInfo{$k}{$v};
		}
	}

	## count the number of keys in the remaining query
	my @key = keys %nextInfo;
	my $y = $#key;

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

1;
exit;
