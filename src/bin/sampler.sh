#!/bin/bash
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
#          FILE:  sampler.sh
# 
#         USAGE:  ./sampler.sh 
# 
#   DESCRIPTION:  Shell script that runs sets up a Sample data-set of Prokaryotes
# 				  and Eukaryotes
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Vivek Krishankumar, biohelp@cgb.indiana.edu 
#       COMPANY:  The Center for Genomics and Bioinformatics
#       VERSION:  1.0
#       CREATED:  11/17/08 10:52:37 EST
#      REVISION:  ---
#===============================================================================

cd sampler
/usr/bin/nohup perl INSTALL-prokaryotes.pl > prokaryotes-install.out 2> prokaryotes-install.err < /dev/null &
/usr/bin/nohup perl INSTALL-eukaryotes.pl > eukaryotes-instal.out 2> eukaryotes-install.err < /dev/null &

echo "cd $PWD" > update-prokaryotes.sh
echo "/usr/bin/nohup perl UPDATE-prokaryotes.pl > prokaryotes-update.out 2> prokaryotes-update.err < /dev/null &" >> update-prokaryotes.sh

echo "cd $PWD" > udpate-eukaryotes.sh
echo "/usr/bin/nohup perl UPDATE-eukaryotes.pl > eukaryotes-update.out 2> eukaryotes-update.err < /dev/null &" >> update-eukaryotes.sh

chmod +x *.sh

printf "Please add the following lines to your crontab\n"
printf "0 0 * * * $PWD/update-prokaryotes.sh\n\n"
printf "0 0 * * * $PWD/update-eukaryotes.sh\n\n"

echo "Thank you!"
