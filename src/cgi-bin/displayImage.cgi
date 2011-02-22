#!/usr/bin/perl -w
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

## perl modules required
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use POSIX qw(floor);
use DBI;
use Apache::Session::File;

use lib qw(PACKAGENAME);
use DB;

## create a CGI object
my $cgi = new CGI;

my $contents;

## get the parameters
my $uploadDir = '_____UPLOAD_____';
my $createdDir = $cgi->param('dir');
my $parseFile = $uploadDir.$createdDir."/parsedBlastOutput";
my @genome = $cgi->param("genome");
my $evalue = $cgi->param('evalue');
my $dbtype = $cgi->param("dbtype");

## Get information from the parsed blast output file
open (FILE, $parseFile);
my @load = <FILE>;
close FILE;

my $id = $cgi->cookie(-name=>"MS");
tie my %session, 'Apache::Session::File', $id, {Directory => "/tmp/", LockDirectory => "/tmp/" };

if (!$id){
	my $cookie = $cgi->cookie(-name=>"MS", -value=>$session{_session_id},-expires=>'+1y',-path=>'/session');
}

if ($cgi->param()){
	if($cgi->param("genome") =~ /-/){
		$session{"genome"} = $cgi->param("genome");
	} else {
		$session{"genome"} = join('-',$cgi->param("genome"));
	}
	$session{"rowstart"} = $cgi->param("rowstart");
	$session{"noRows"} = $cgi->param("noRows");
}

my $tableDisplay;

my $rowstart = $session{"rowstart"} || 0;
my $noRows = $session{"noRows"} || 5;

## get the first row of the table of images
$tableDisplay .= '
	<table class="tab" width="100%" border="0px" id="movingTable" >

	<!-- Display image information -->
	<tr>
		<td colspan="2" style="border-bottom:1px solid black;">
		<form action="displayImage.cgi" enctype="multipart/form-data" name="displayForm" method="POST">
		Display
		<select id="noRows" onchange="getSelected(this.id,'.$rowstart.',this.options[this.selectedIndex].value)" style="width:50px">
	';

@genome = split(/-/, $session{"genome"});

## display number of images per page
my $i;
for($i = 5; $i <= 10; $i=$i+5){
	$tableDisplay .= '<option value="'.$i.'" ';
	$tableDisplay .= 'selected' if ($i == $noRows);
	$tableDisplay .= '>'.$i.'</option>';
}

$tableDisplay .= '</select> per page. </td>
	<td colspan="4" style="border-bottom:1px solid black;">
	Select Page ';

## display the page 
$tableDisplay .= '<select id="rows" onchange="getSelected(this.id,this.options[this.selectedIndex].value,'.$noRows.')" style="width:50px">';

my $j;
for($i = 0, $j=1; $i < scalar(@genome); $i=$i+$noRows, $j++){
	$tableDisplay .= '<option value="'.$i.'" ';
	$tableDisplay .= 'selected' if ($i == $rowstart);
	$tableDisplay .= '>'.$j ;
	$tableDisplay .= '</option>';
}

## hidden attributes to reload the page
$tableDisplay .= '</select> of '. --$j.'
	<input type="hidden" name="dir" value="'.$createdDir.'">
	<input type="hidden" name="dbtype" value="'.$dbtype.'">
	<input type="hidden" name="evalue" value="'.$evalue.'">
	<input type="hidden" name="genome" value="'.$session{"genome"}.'">
	<input type="hidden" id="noofrows" name="noRows" value="">
	<input type="hidden" id="rowstart" name="rowstart" value="">
	</form></td>
	</tr>';



my @color = ("#FFFFF0","white");

my @genomeList;
my @listOfLength;
my @genomelist = @genome;
for ($i = 0; $i < scalar(@genomelist); $i++){
	next if (($i < $rowstart) || ($i >= ($rowstart+$noRows)));
	my $genome = $genomelist[$i];
	push(@genomeList,$genome);
	my $array;
	eval {
		$array = DB->exec("SELECT orgname, seqlength FROM taxid_accno WHERE accno=?", [$genome]);
	};
	displayErrorPage("Unable to read database") if ($@);
	
	my $description;
	my $length;

	foreach (@$array){
		$description = @$_[0];
		$length = @$_[1];
	}
	
	push(@listOfLength,$length);
	my $setcolor = $i%2;

	my $click="this.id, '$length', '$evalue', '$i'";

	$tableDisplay.='

	<!-- first row, description, mouseover information -->
	<tr bgcolor="'.$color[$setcolor].'" height="50px">
	
		<!-- description -->
		<td align="left" colspan="2" width="500px">
			<span class="bodypara" style="margin-left:50px;font-style:italic;font-weight:bold">
			'.$description.'
			</span>
		</td>
		<td onClick="moveRow(this, -3)" align="right" style="vertical-align:top">
			<img src="/cgcv/img/moveDown.png" width="15" height="15">
			<br>
			<span style="font-size:9px">move up</span>
		</td>

		<td onClick="moveRow(this, 3)" align="left" style="vertical-align:top">
			<img src="/cgcv/img/moveUp.png" width="15" height="15">
			<br>
			<span style="font-size:9px">down</span>
		</td>
		<!-- Information -->
		<td style="vertical-align:center; padding:1px">
			<div id="'.$genome.'" style="width:350px; color:black; font-size:10px">Mouse over Annotated genes or Query sequences for information. <br>Click to retrieve detailed info</div>
		</td>
		<td>
		<input type="button" value="refresh" id="refresh'.$i.'" onClick="getValue('.$click.')">
		</td>
	</tr>

	<!-- Second row- left, zoom out, zoom in, evalue, start-end, right -->

	<tr bgcolor="'.$color[$setcolor].'">
		<!-- left -->
		<td align="right" width="40px" style="vertical-align:top">
			<input type="button" id="left'.$i.'" onClick="getValue('.$click.')"
				value ="<"
				style="width:20px; height:30px"
			>
		</td>

		<!-- evalue -->
		<td align="center" style="vertical-align:top">
			<input type="text" 
				id="filterEvalue'.$i.'" 
				value="'.$evalue.'" 
				size="5"
				onClick = "emptySpace(id)"
			>
			<input type="button" value="Filter" 
				id="filter'.$i.'"
				onClick="getValue(this.id, \''.$length.'\', \'filterEvalue'.$i.'\', \''.$i.'\' )"
			>
			(e-value)
		</td>


		<!-- zoom out -->
		<td align="right" style="vertical-align:top">
			<input type="button" value="out" id="out'.$i.'" onClick="getValue('.$click.')">
			<br>
			<span style="font-size:9px">zoom</span>	
		</td>


		<!-- minus -->
		<td align="left" style="vertical-align:top">
			<input type="button" value="in" id="in'.$i.'" onClick="getValue('.$click.')">
			<br>
			<span style="font-size:9px">zoom</span>
		</td>
		

		<!-- start-end -->
		<td align="center" style="vertical-align:top">
			<input type="text" id="start'.$i.'pos" value="start" size="7" onClick="emptySpace(id)">
			<input type="text" id="end'.$i.'pos" value="end" size="7" onClick="emptySpace(id)">
			<input type="button" id="pos'.$i.'" value="Get" onClick="getValue('.$click.')" >
		</td>

		<!-- right -->
	        <td  align="center" style="vertical-align:top">
			<input type="button" id="right'.$i.'" onClick="getValue('.$click.')"
				value =">"
				style="width:20px; height:30px"
			>
			<span style="font-size:8px; color:white"></span>
		</td>
	</tr>

	<tr bgcolor="'.$color[$setcolor].'">

	<input type="hidden" id="start'.$i.'" value="1">
	<input type="hidden" id="end'.$i.'" value="'.$length.'">
	<input type="hidden" id="dir" value="'.$createdDir.'">
	<input type="hidden" id="genome'.$i.'" value="'.$genome.'">
	<input type="hidden" id="dbtype" value="'.$dbtype.'">
	<input type="hidden" id="evalue" value="'.$evalue.'">

	<!-- image -->
	<td colspan="6" style="border-bottom:1px solid black; border-top:1px solid black;">
		<img src="/cgi-bin/cgcv/image.cgi?start=1
			&end='.$length.'
			&dir='.$createdDir.'
			&genome='.$genome.'
			&evalue='.$evalue.'
			&dbtype='.$dbtype.'
			&imgId='.$i.'" 
			id="image'.$i.'" 
			usemap="#imageMap'.$genome.'"
			onLoad="getCoords('."\'$genome\'".','."\'$createdDir\'".')"
			border=none
			><br>
		<map id="imageMap'.$genome.'" name="imageMap'.$genome.'">';

	system("perl imageCoords.cgi -g $genome -s 1 -e $length -d $createdDir -D $dbtype -E $evalue -I $i");

	my $filecontents = `cat $uploadDir$createdDir/imageMap$genome`;

	$tableDisplay .= $filecontents;
	$tableDisplay .='</map>
		<input type="hidden" id="myImage'.$i.'" value="refresh'.$i.',start'.$i.',image'.$i.',end'.$i.',genome'.$i.','.$length.','.$evalue.'" > 
	</td>

	</tr>';
}


$tableDisplay .= '
	</table>
	<br>
	';

my $display = $tableDisplay;
my @length = @listOfLength;

$contents .= $display;

$i = @length;
my $script = '
        // Function to read the values
        function getValue(id, length, evalue, imgId){

		var start = "start"+imgId;
		var image = "image"+imgId;
		var end = "end"+imgId;
		var genome = "genome"+imgId;

/*
		document.getElementById(document.getElementById(genome).value).innerHTML="Mouse over Annotated genes or Query sequences for information. <br>Click to retrieve detailed info";
*/

                var start_val = document.getElementById(start).value;
                var end_val = document.getElementById(end).value;
                var turn = Math.floor( ( parseInt(end_val) - parseInt(start_val) ) / 3 ) ;


		//Refresh
		if (id.match("refresh")) {
			start_val = 1;
			end_val = length;
		}

		//just zoom
		else if (id.match("show")){
			var stemp = start_val;
			var etemp = end_val;
			if( start_val < 1) {
				stemp = stemp - 1;
				start_val = 1;
				end_val = parseInt(end_val) - stemp;
			} else if(end_val > length){
				etemp = length - etemp;
				end_val = length;
				start_val = parseInt(start_val) + etemp;
			}		
		}
	
		// move right
                else if (id.match("right")) {
                        var temp = end_val;
                        end_val = parseInt(end_val) + turn;
                        if (end_val > length){
                                turn = length - temp;
                                end_val = length;
                                start_val = parseInt(start_val) + turn;
                        } else {
                                start_val = parseInt(start_val) + turn;
                        }
                        if (start_val < 1) start_val = 1;

                } 
		// move left
		else if (id.match("left")) {
                        var temp = start_val;
                        start_val = parseInt(start_val) - turn;
                        if (start_val < 1) {
                                turn = temp - 1;
                                start_val = 1;
                                end_val = parseInt(end_val) - turn;
                        } else {
                                end_val = parseInt(end_val) - turn;
                        }
                        if (end_val > length) end_val = length;
                        
                } 
                // zoom out 
                else if (id.match("out")) {
                        start_val = parseInt(start_val) - turn;
                        if (start_val < 1) start_val = 1;
                        end_val = parseInt(end_val) + turn;
                        if (end_val > length) end_val = length;
                } 
                // zoom in 
                else if (id.match("in")) {
                        if (turn < 333) exit;
                        start_val = parseInt(start_val) + turn;
                        end_val = parseInt(end_val) - turn;
                } 
		// start and end position
                else if (id.match("pos")){
                        var start_pos = document.getElementById(start+"pos").value;
                        var end_pos = document.getElementById(end+"pos").value;
                        var number = /^[0-9]+$/;
                        if (!number.test(start_pos) || start_pos < 1 || parseInt(length) < parseInt(end_pos) || parseInt(start_pos) > parseInt(end_pos)){
				document.getElementById(document.getElementById(genome).value).innerHTML="Error: Incorrect values entered";
				exit;		
			}
                        start_val = start_pos;
                        end_val = end_pos;
                }
		else if(id.match("filter")){
			var regExp = /^[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?$/;
			var filterEvalue = document.getElementById(evalue).value;
			var result = filterEvalue.match(regExp);
			if (result != null){
				evalue = filterEvalue; 
			}else {
				evalue = '.$evalue.';
			}		
                }

                var dir = document.getElementById("dir").value;
                var gen = document.getElementById(genome).value;
                var dbtype = document.getElementById("dbtype").value;

                var url="/cgi-bin/cgcv/image.cgi";
                url = url+"?start="+start_val;
                url = url+"&end="+end_val;
                url = url+"&dir="+dir;
                url = url+"&genome="+gen;
                url = url+"&dbtype="+dbtype;
                url = url+"&evalue="+evalue;
		url = url+"&imgId="+imgId;
                url = url+"&sid="+Math.random();
                document.getElementById(image).src = url;
                document.getElementById(start).value = start_val;
                document.getElementById(end).value = end_val;
        }

        function setValue() {
                ELEMENT = "imageMap";
        ';

        for (my $y=0; $y < $i; $y++) {
        $script .= '
                document.getElementById("start'.$y.'").value = 1;
                document.getElementById("end'.$y.'").value = '.$length[$y].';
        ';
        }

	$script .= '
	}';



# HTML page
print $cgi->header;

my $template = HTML::Template->new(
        filename => "templates/image.tmpl");
$template->param (TITLE => "View");

$template -> param (CONTENT => $contents );
$template -> param (SCRIPT => $script);

print $template->output;
print $cgi->end_html();
# end HTMl page

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


exit 0;




