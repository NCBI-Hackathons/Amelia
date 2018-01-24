#!/bin/bash

display_usage() { 
echo "Usage: $0 clinvar.vcf.gz [GENE] or [DISEASE] [CLINSIG]";
echo "";
echo "[GENE] = GENE ID ";
echo "[DISEASE] = name of associated disase in clinvar ";
echo "[CLINSIG] = 5 for pathogenic, otherwise report all SNPs";
echo "";
echo " This program takes clinvar database in GRCh37, a gene or disase,";
echo " and weather you want pathogenic or all variants as input and  ";
echo " outputs a list of RSids related to that disease. ";
echo "";
echo " You must list the clinvar.vcf.gz download file must have one of Gene or Disease";
echo "";
echo " The program will automatically check to see if you have the latest";
echo " version of clinvar from the NCBI ftp site and automatically download";
echo " the file if your version does not match file on the ftp site ";
echo "";
}

# if less than two arguments supplied, display usage 
	if [  $# -le 1 ] 
	then 
		display_usage
		exit 1
	fi 
 

ADDRESS="ftp://ftp.ncbi.nlm.nih.gov/"
# SRC_DIR="pub/clinvar/vcf_GRCh37/"
SRC_DIR="pub/clinvar/vcf_GRCh37/archive_1.0/2017/"
command="open -e \"get $SRC_DIR$1.md5 ; exit \" \"$ADDRESS\""
command2="open -e \"get $SRC_DIR$1 ; exit \" \"$ADDRESS\""

file1=`md5 -q $1`
if [ ! -e $1.md5 ]; then
    #lftp -c "$command"
    wget $ADDRESS$SRC_DIR$1.md5
fi
file2=`cut -d* -f1 $1.md5`

if [ ! -e $1 ]; then
    #lftp -c "$command2"
    wget $ADDRESS$SRC_DIR$1
fi

echo "Checking file: $1"

echo "Using MD5 file: $1.md5"
echo $file1
echo $file2

if [ $file1 != $file2 ]
then
  echo "md5 sums mismatch"
  mv $1 $1.old
  # lftp -c "$command2"
  wget $ADDRESS$SRC_DIR$1
else
  echo "checksums OK"
fi


#actual search

if [ "$3" = 5 ]; then 
  zgrep -i $2 $1 | grep CLNSIG=5 | awk '{print $8}' | awk -F  ";" '/1/ {print $1}' | awk -F  "=" '/1/ {print $2}' > $2-$3.snps
  echo "SNPs written to $2-$3.snps"
else
  zgrep -i $2 $1 | awk '{print $8}' | awk -F  ";" '/1/ {print $1}' | awk -F  "=" '/1/ {print $2}' > $2.snps
  echo "SNPs written to $2.snps"
fi

