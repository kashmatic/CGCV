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
use Bio::SearchIO;
use Bio::SeqIO;
use DBI;
use POSIX qw(floor ceil);
use Math::Round;

use lib "PACKAGENAME";
use DB;

## Create CGI object
my $cgi = new CGI;

my $uploadDir = '_____UPLOAD_____';
my $createdDir = $cgi->param('dir');

my $script = getScript();
  my $dir = $uploadDir.$createdDir;
  my $inputFile = $dir.'/inputFile';

  ## parse input file using a perl module
  my $readInputFile;
  eval {
    $readInputFile = Bio::SeqIO->new('-file' => $inputFile, '-format' => "Fasta");
  };
  displayErrorPage("Unable to read the input file") if($@);

  ## variable to store input sequence information
  my %storeInputInfo;
  while ( my $seq = $readInputFile->next_seq() ){
    $storeInputInfo{$seq->id}=length($seq->seq);
  }

  ## Hash to create the matrix
  my %tableHash;  ## To store the values to be printed as a table
  my %fileHash; # hash for recording stuff to be put in file
  my @input;  # recording input queries 

  ## To read the blast output file using perl module
  my $blastFile = $dir.'/blastOutput';
  my $readBlastOutput;
  eval {
    $readBlastOutput = Bio::SearchIO->new('-file' => $blastFile,'-format' => "blast");
  };
  displayErrorPage("Unable to read the BLAST output file") if($@);
  
  ## Writing a parsed file to store the BLAST information
  my $parseBlastFile = $dir.'/parsedBlastOutput';
  warn $parseBlastFile;
  open (PARSE, ">",$parseBlastFile) or displayErrorPage("Unable to open parseBlastFile");

  ## Parse the blast output here
  my @db;
  my $parseLines;
  my $num = 0;
  my $alt = 1;
  my %dTotal;
  while (my $result = $readBlastOutput->next_result()) {
    my $i = 0;
    if ($cgi->param('dbtype') eq "aaseqs"){
      $alt = 1;
    }
    while( my $hit = $result->next_hit()) {
      my $something;
      my $startend;
      my $strand;
      my $end;
      ## if blasted against protein sequences
      ## pick up the protein id and get the accession
      if ($cgi->param('dbtype') eq "aaseqs"){
        my $array;
        eval {
          $array = DB->exec("SELECT accno, start,end, strand FROM genedetails where protaccno like ?",[$hit->accession]);
        };
        displayErrorPage("Unable to access gene details using protein accession number") if($@);
        foreach (@$array){
          $something = @$_[0];
          $startend = @$_[1];
          $end = @$_[2];
          $strand = @$_[3];
        }
        push(@db, $something);
      }
      ## if blasted against gene sequences
      ## parse the hit->name to get the geneid
      elsif ($cgi->param('dbtype') eq "geneseqs"){
        my ($key) = $hit->name =~ /^gi\|(.*)\|.*\|.*\|/;
        my $gene_array;
        eval {
          $gene_array = DB->exec("SELECT accno, start FROM genedetails where geneid like ?",[$key]);
        };
        displayErrorPage("Unable to access gene details using gene id") if($@);
        foreach (@$gene_array){
          $something = @$_[0];
          $startend = @$_[1];
        }
        push(@db, $something);
      } 
      ## if blasted against genomes, get the hit accession
      else {
        $something = $hit->accession;
        $startend = 0;
        push(@db, $something);
      }

      if ($cgi->param('dbtype') ne "aaseqs"){
        $alt = 1;
      }
      
      ## keep track of the count
      if (!$tableHash{$something}{$result->query_name}{"count"}){
        $tableHash{$something}{$result->query_name}{"count"} = 0;
      }
      
      ## get each HSP detail to write inside parse
      while (my $hsp = $hit->next_hsp()) {
        next if($hsp->evalue > $cgi->param('evalue'));
        my $starting;
        my $ending;

        if ($cgi->param('dbtype') ne "aaseqs"){
          $starting = $startend + $hsp->start('hit');
          $ending = $startend + $hsp->end('hit');
        } else {
          my $x = ($end - $startend)/$hit->length;
          if($strand eq "+"){
            $starting = $startend + round($hsp->start('hit') * $x);
            $ending = $startend + round($hsp->end('hit') * $x);
          } else {
            $ending = $end - round($hsp->end('hit') * $x);
            $starting = $end - round($hsp->start('hit') * $x);
          }
        }
          
        ## write into the parser file
        print PARSE 
          $something.','.
          $result->query_name.','.
          $alt++.','.
          $hsp->start('query').'...'.
          $hsp->end('query').'...'.
          $starting.'...'.
          $ending.','.
          $num.','.
          $hit->accession.','.
          $hsp->evalue.
          "\n";
        $tableHash{$something}{$result->query_name}{"count"}++;
        $i++;
      }
      my $x = $result->query_name;
    }
    $num++;
  }
  close PARSE;


  ## Connection to database to get the gene length and description
  my $listDb;
  if (scalar(@db) > 1){
          $listDb = join("'OR accno like '",@db);
  } else {
    $listDb = $db[0];
  }

  ## store the information into the Hash
  my $details;
  eval {
    $details = DB->exec("SELECT accno, orgname, seqlength FROM taxid_accno WHERE accno like '$listDb' order by orgname");
  };
  displayErrorPage("Unable to access database") if ($@);

  foreach (@$details){
    $tableHash{@$_[0]}{"description"} = @$_[1];
    $tableHash{@$_[0]}{"length"} = @$_[2];
  }

  ## Get the keys from hash storing blast info
  my %gList;
  while(my $k = each(%tableHash)){
    while(my ($l, $m) = each(%{$tableHash{$k}})){
      if($l =~ /description/){
        $gList{$k} = $m;
      }
    }
  }
  my @genome = sort { $gList{$a} cmp $gList{$b} } keys(%gList);
  #my @genome = sort keys {%tableHash};

  if(scalar (@genome)  < 1 ){
    noBLAST("proForm.cgi");
  }

  ## get keys from hash storing input info
  my @inputId = keys(%storeInputInfo);

  ## Start constructing the table-----------------------
  my $phytable = '<table class="sortable" width="100%" name="sortable" style="border-spacing: 0px;border-collapse: collapse;border-color: black;" border="1px">
      <thead>
      <tr>
      <th class="sorttable_nosort" width="15px">
      <input type="checkbox" id="genomeSelect" onclick="checkAll(document.selectForm.genome,this)"><br>Select all</th>
      <th>Organism Name <br><span style="font-size:8px;color:#000000">[sort]</span></th>
      ';
  
  @inputId = sort { $a cmp $b } (@inputId);

  for (my $i=0; $i < scalar(@inputId); $i++){
    $phytable .= '<th>'.$inputId[$i].'<br><span style="font-size:8px;color:#000000">[sort]</span></th>';
  }
  $phytable .= '</th></tr></thead>';

  foreach my $genome (@genome){
    foreach my $inputId(@inputId){
      if (exists $tableHash{$genome}{$inputId}){
        if($dTotal{$genome}){
          $dTotal{$genome} += 1;
          $dTotal{$genome} += ($tableHash{$genome}{$inputId}{"count"} / 10000);
        } else {
          $dTotal{$genome} = 1;
          $dTotal{$genome} += ($tableHash{$genome}{$inputId}{"count"} / 10000);
        }
      }
    }
  }

  @genome = sort { $dTotal{$b} <=> $dTotal{$a} } keys(%dTotal);

  foreach my $genome (@genome){
    $phytable .= '<tr>
      <td align="center">
      <input type="checkbox" name="genome" value ="'.$genome.'" id="genome">
      </td>
      <td align="left">'
      .$tableHash{$genome}{"description"}
      .'</td>';

    foreach my $inputId (@inputId){
      if (exists $tableHash{$genome}{$inputId}){
        my $x = $tableHash{$genome}{$inputId}{"count"};
        $phytable .= '<td align="center">'.$x.'</td>';
      } else {
        $phytable .= '<td align="center">0</td>';
      }
    }
    $phytable .= '</tr>';
  }


  $phytable .= '</table>';
  #------------------------------------------------------

  ## Contents to be displayed on the page ----------------
  my $contents = '
    <h4>
    Phylogenetic profiling table
    </h4>
    <p class="bodypara" align="justify">
    The following table represents a Phylogenetic profiling of the BLAST output where the numbers in each cell indicate the number of significant hits of a particular query sequence against a genome. A zero(0) in any of the cells indicates the absence of significant hits (filtered by e-value)
    </p>

    <p class="bodypara" align="justify">Select the genomes that you would like to visualize your query sequences against and then click Proceed.
    </p>

    <form method="post" action="displayImage.cgi" enctype="multipart/form-data" name="selectForm" id="selectForm" onSubmit="return checkSelect()">
    <div style="width:1000px;max-height:1000px;overflow:auto">
    '
    .$phytable
    .'
    </div>
    <br>
    <input type="submit" value="Proceed">
    <br>
    <a href="proForm.cgi"><span class="bodypara">Re-Submit</span></a>
    <span id="errorMsg" class="bodypara" style="color:red"></span>
    <input type="hidden" name="dir" value="'.$createdDir.'">
    <input type="hidden" name="dbtype" value="'.$cgi->param("dbtype").'">
    <input type="hidden" name="evalue" value="'.$cgi->param("evalue").'">
    </form>'
    ;

# HTML page
print $cgi->header;
my $template = HTML::Template->new(filename => "templates/main.tmpl");

$template->param (TITLE => "Table");
$template->param (CONTENT => $contents );
$template->param (SCRIPT => $script );

print $template->output;
print $cgi->end_html();
# end HTMl page

exit 0;

#################################################################################
## input - file ( only the filename )
## requires - file_blast file to be present in the tmp/blast directory
## implements
## - creates a table to be displayed on the web page
## - creates a file in /tmp/blast with ',' delimited information

sub parseBlast {
  ## Get the details on upload directory and define the files
  my $createdDir = shift;
  return $contents;
}

##################################################################################
sub getScript {
  my $script = '
    function checkAll(checkname, exby) {
      //alert("check all clicked");
      for (i = 0; i < checkname.length; i++){
        checkname[i].checked = exby.checked? true:false
      } 
    }
    function checkSelect(){
      var check = document.selectForm.genome;
      var checked = 0;
      if(!check.length){
        if(check.checked)
          checked = 1;
      }
      for (var i = 0; i < check.length; i++){
        if(check[i].checked)
        checked+=1;
      }
      if(checked < 1){
        document.getElementById("errorMsg").innerHTML = "Error: Please select one or more genomes from the above list";
        return false;
      }
    }

    ';
  return $script;
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

sub noBLAST{
  ## Display error webpage  if the upload file is not a BLAST output file
  my $form = shift;
  
  my $cgi = new CGI;
  my $content = '
    <h4>Sorry</h4>
    <p class="bodypara">There were \'No Hits Found\' for the given set of query/queries against the selected Genome sequences. Please change the selected genomes or increase the cut-off evalue.
  </p>
  <p class="bodypara">Click <a href="'.$form.'">here</a> to start over.</p> 
  </p>
  ';
  
  print $cgi->header;
  my $template =  HTML::Template->new(filename => "templates/main.tmpl");
  $template->param(TITLE => "ERROR");
  $template->param(CONTENT => $content);
  print $template->output;
  print $cgi->end_html();
  exit;
}

exit;
1;

