#!/bin/bash
set -euxo pipefail

bioprojectID=$1
geneOrDisease=$2
workingDir=$3
email='jlever@bcgsc.ca'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR

mkdir -p $workingDir
cd $workingDir

rm -f sra.txt *.snps snp.txt
rm -rf snp_flanks jobs out acc

sh $DIR/Bioproject2SRAData.sh $bioprojectID sra.txt

bash $DIR/prototype.sh clinvar_20170905.vcf.gz $geneOrDisease 5
cat *.snps > snp.txt
rm -fr PSST
git clone https://github.com/jakelever/PSST.git
PSSTROOT=$PWD/PSST

# the -s option is not important here, just an arbitrary name
bash $PSSTROOT/psst_1.sh -s ERR1630014 -n snp.txt -d snp_flanks -e $email -t 1 -p 1

mkdir jobs out acc

while read -u 3 sra;
do
	acc=$(echo -e "$sra" | cut -f 1)
        #meta=$(echo $sra | cut -f 2-)
	cp -r snp_flanks out/$acc
	echo -e "$sra" > out/$acc/meta.txt
	echo "#!/bin/bash" > jobs/$acc
	echo "esearch -db sra -query $acc | esummary | xtract -pattern DocumentSummary -ACC @acc -block DocumentSummary -element \"&ACC\" | cut -f 5 > acc/$acc" >> jobs/$acc
	echo "bash $PSSTROOT/psst_2.sh -s acc/$acc -n snp.txt -d out/$acc -e $email -t 1 -p 1" >> jobs/$acc
	bash jobs/$acc
done 3< sra.txt

