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

package Error;

use HTML::Template;
use strict;

BEGIN
{
	use Exporter ();
	our @ISA       = qw(Exporter);
	our @EXPORT = qw(displayErrorPage noBLAST);
}

sub displayErrorPage{
        ## Display error webpage  if the upload file is not a BLAST output file
        my $cgi = new CGI;
        my $content = '
			<h4>Error</h4>
			<p class="bodypara">Sorry, We have encountered an error. 
			Please contact the CGCV Developer Team at 
			<a href="mailto:_____SUPPORT_EMAIL_____">
			_____SUPPORT_EMAIL_____
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
	
1;

