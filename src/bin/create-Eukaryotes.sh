#!/bin/bash
#########################################################
## Copyright 2008 The Trustees of Indiana University
##
## Licensed under the Apache License,  Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,  software
## distributed under the License is distributed on an "AS IS" BASIS, 
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#########################################################

#===============================================================================
#
#          FILE:  create-Eukaryotes.sh
# 
#         USAGE:  ./create-Eukaryotes.sh 
# 
#   DESCRIPTION:  Shell script that runs INSTALL.pl to download the data and
# 				  set up the MySQL tables
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Vivek Krishankumar, vivkrish@indiana.edu 
#       COMPANY:  The Center for Genomics and Bioinformatics
#       VERSION:  1.0
#       CREATED:  11/17/08 10:52:37 EST
#      REVISION:  ---
#===============================================================================

printf "Welcome to the Eukaryote Database Setup for CGCV
This script will download files from Ensembl and set up the necessary MySQL tables
Please be patient. This process takes at least 2-3 days on the whole to download and set up the SQL tables.\n\n"

cd scripts_Eukaryotes
/usr/bin/nohup perl eukINSTALL.pl > eukaryotes-install.out 2> eukaryotes-install.err < /dev/null &

printf "The installer is now running in the background. You can check the status of the installer by inspecting the eukaryotes-install.out log.
You can also track any errors in the installer by inspecting the eukaryotes-install.err log.\n\n"

####
# echo "cd $PWD" > eukaryotes-update.sh
# echo "/usr/bin/nohup perl UPDATE.pl > eukaryotes-update.out 2>eukaryotes-update.err < /dev/null &" >> eukaryotes-update.sh

# chmod +x update.sh

# printf "Please add this line to your crontab\n"
# printf "0 0 * * * $PWD/eukaryotes-update.sh\n\n"
####

printf "Thank you!\n"
