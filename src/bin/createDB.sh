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
#          FILE:  createDB.sh
#
#         USAGE:  ./createDB.sh
#
#   DESCRIPTION:  Shell script that runs prokINSTALL.pl to download the data and
# 				  set up the MySQL tables for the Prokaryotes
#
#       OPTIONS:     -h      Show this message
#                    -o      Choose the organism type to setup
#                    -m      Choose the installation mode.
#                            sampler:      Install only 2 organisms and related datasets
#                            full-install: Install all Prokaryotes available via GenBank or 6 Eukaryotes available on Ensembl
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Vivek Krishankumar, biohelp@cgb.indiana.edu
#       COMPANY:  The Center for Genomics and Bioinformatics
#       VERSION:  1.0
#       CREATED:  11/17/08 10:52:37 EST
#      REVISION:  ---
#===============================================================================
usage()
{
cat << EOF
usage: $0 -o [Prokaryotes|Eukaryotes] -m [sampler|full-install]

OPTIONS:
   -o      Choose the organism type to setup
   -m      Choose the installation mode.
           full-install: Set up CGCV to work with all Prokaryotes (from GenBank) and/or 6 Eukaryotes (from Ensembl)
           sampler     : Set up CGCV to work with 5 Prokaryotes and/or 2 Eukaryotes
EOF
}

NO_ARGS=0
E_OPTERROR=85

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  usage
  exit $E_OPTERROR          # Exit and explain usage.
fi

while getopts "o:m:h" Options
do
    case $Options in
        o)  if [[ "$OPTARG" = "Prokaryotes" ]] || [[ "$OPTARG" = "Eukaryotes" ]]; then
                ORGANISM=${OPTARG}
            else
                usage
                exit 1
            fi;;
        m)  if [[ "$OPTARG" = "sampler" ]] || [[ "$OPTARG" = "full-install" ]]; then
                MODE=${OPTARG}
            else
                usage
                exit 1
            fi;;
        h)  usage
            exit 1;;
        ?)  usage
            exit;;
    esac
done

if [[ -z $ORGANISM ]] || [[ -z $MODE ]]; then
    usage
    exit
fi

org=`echo $ORGANISM | tr '[A-Z]' '[a-z]'`
if [[ $org = "prokaryotes" ]]; then
    SCRIPT=${org:0:4}"INSTALL.pl"
else
    SCRIPT=${org:0:3}"INSTALL.pl"
fi

printf "Welcome to the $ORGANISM Database Setup ($MODE) for CGCV
This script will download files from GenBank/Ensembl and set up the necessary MySQL tables
Please be patient. This process takes a few days to download and set up the SQL tables.\n\n"

cd scripts_$ORGANISM
/usr/bin/nohup perl $SCRIPT $MODE > $org-install.out 2> $org-install.err < /dev/null &

printf "The installer is now running in the background. You can check its status by inspecting the file \033[1m$org-install.out\033[0m.
You can also track any errors by inspecting the file \033[1m$org-install.err\033[0m.\n\n"

if [[ ${org:0:4} = "prok" ]]; then
    echo "cd $PWD" > $org-update.sh
    echo "/usr/bin/nohup perl ${org:0:4}UPDATE.pl $MODE > $org-update.out 2>$org-update.err < /dev/null &" >> $org-update.sh

    chmod +x $org-update.sh

    printf "Please add this line to your crontab\n"
    printf "0 0 * * * $PWD/$org-update.sh\n\n"

    echo "This will set up a nightly cronjob (to be executed at 12:00am) to check for updates, if any, and simultaneously download them."
fi
echo "Thank you for using CGCV!"
