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
use Proc::Simple;

## List of modules used ---------------------------------------------------------
use CGI;
use lib qw(PACKAGENAME);

BEGIN {
  $ENV{PATH} = "$ENV{PATH}:_____BLASTALL_____bin/";  # where my blastall binary is
  $ENV{BLASTDIR} = '_____BLASTALL_____bin/';  # where my blastall  binary is
  $ENV{BLASTDATADIR} = '_____BLASTALL_____data/' ; # where my -d are
} 

## create objects and variables
my $cgi = new CGI;
my $dir = $cgi->param('dir');
my $uploadDir = '_____UPLOAD_____';

my $inFile = $uploadDir.$dir.'/inputFile';
my $outFile = $uploadDir.$dir.'/blastOutput';

my $program = $cgi->param('program');
my $email = $cgi->param('email');
my $dbtype = $cgi->param('dbtype');
my $evalue = $cgi->param('evalue'); 

## CHANGE database dir
my $databaseDir = '_____GENOME_DATA_____'.$dbtype.'/';
my $para = $cgi->param('para');

## create command
my $command = '_____BLASTALL_____bin/blastall '
	.' -p '.$program
	.' -i '.$inFile
	.' -o '.$outFile
	.' -e '.$evalue
	.$para;

my $list;

my $file = $uploadDir.$dir.'/selected';

open(FILE, "$file");
my @genome = <FILE>;
close(FILE);

foreach my $g (@genome){
	chomp $g;
	$list .= $databaseDir.$g.' ';
}

$command .= ' -d  "'.$list.'" ';

## Run the blastall program
eval {
	my $process = Proc::Simple->new();
	$process->start($command);
	$process->wait();
};
displayErrorPage($@) if($@);

## To continue to Phylogenetic profile table
my $webaddress = '/cgi-bin/cgcv/getProfile.cgi?dir='.$dir.'&dbtype='.$dbtype.'&evalue='.$evalue;

## send mail
if($email){
	my $sendmail = '_____SENDMAIL_____ -t';
	my $from = '_____SUPPORT_EMAIL_____';
	my $send_from = "From: 'CGCV Team' <".$from.">\n";
	my $to = $email."\n";
	my $send_to = "To: ".$to;
	my $subject = "Subject: Bookmark URL from CGCV Tool\n";
	my $content = "Dear User,\n\n"
	. "Thank you for using Comparative Gene Cluster Viewer (CGCV) tool.\n"
	. "Please use the URL link below to access your results,\n "
	. "_____URI_____".$webaddress."\n"
	. "\nRegards,\nCGB staff\n\nP.S. This link is valid for _____LIFETIME_____ days from today.\n"
	. "Please do not reply to this email. This is an automated email. If there is any problem, email to biohelp\@cgb.indiana.edu";

	if(!open(SENDMAIL, "|$sendmail")){
		displayErrorPage("Unable to send email");
	}
	print SENDMAIL $send_from;
	print SENDMAIL $send_to;
	print SENDMAIL $subject;
	print SENDMAIL $content;
	close(SENDMAIL);
}

print $cgi->header;
print '
<fieldset>
<p class="bodypara">
Job finished, This page will refresh in a few seconds<br>
Alternatively, click on the link 
<a href="'.$webaddress.'">
here
</a>
to proceed.
</p>
</fieldset>';

print $cgi->end_html();

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

exit;
1;

