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
#          FILE:  create-bacteria.sh
# 
#         USAGE:  ./create-bacteria.sh 
# 
#   DESCRIPTION:  Shell script that runs prokINSTALL.pl to download the data and
# 				  set up the MySQL tables for the Prokaryotes
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

cd scripts_Prokaryotes
/usr/bin/nohup perl prokINSTALL.pl > bacteria-install.out 2> bacteria-install.err < /dev/null &

echo "cd $PWD" > prokaryotes-update.sh
echo "/usr/bin/nohup perl prokUPDATE.pl > bacteria-update.out 2>bacteria-update.err < /dev/null &" >> prokaryotes-update.sh

chmod +x prokaryotes-update.sh

printf "Please add this line to your crontab\n"
printf "0 0 * * * $PWD/prokaryotes-update.sh\n\n"

echo "Thank you!"
