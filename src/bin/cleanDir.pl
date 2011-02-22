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
#################################################################################

## obtain the list of directories
open (COMMAND, "ls _____UPLOAD_____ |");
my @dir = <COMMAND>;
close(COMMAND);

## Set the timescale
my $sec = 60;
my $min = 60;
my $hr = 24;
my $days = _____LIFETIME_____;

## lifetime of directories
my $life = $sec*$min*$hr*$days;

## search and delete the directories
foreach(@dir){
	if(substr($_,0,10) < (time()-$life)){
		my $c = 'rm -rf _____UPLOAD_____'.$_;
		system($c);
	}
}

exit;
1;

