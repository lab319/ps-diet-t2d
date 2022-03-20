
# -----------------------------------------------------------------------
# 
# below is an example code to run GWAS in the UK Biobank using BOLT-LMM
# 
# paths and some file names were masked
# adjustment needs to be made based on your systems and data 
# 
# -----------------------------------------------------------------------

# /path1  # path to UKB GWAS bgen data
# /path2  # path to where output will be stored
# /path3  # path to where BOLT-LMM was installed
# /path4  # path to where phenotype was at: pheno1 pheno2 pheno3 are phenotypes to be run; other covariates adjusted include cov_ASSESS_CENTER as study center, cov_GENO_ARRAY, cov_SEX, cov_AGE, cov_AGE_SQ, and PC{1:20}, or other covariates as you prefer
# /path5  # path to LDscoresFile
# /path6  # path to geneticMapFile

DIR=/path1 # path to UKB GWAS bgen data
echo $DIR
THREADS=10
for PHENO in pheno1 pheno2 pheno3;do # a list of phenotype such as diagnosoed T2D
	OUT_PREFIX=/path2/Bolt_460K_UKB.$PHENO # path to where output will be stored
	sbatch -p long -t 7-00:00 -c $THREADS -N 1 -o $OUT_PREFIX.bsub.log --job-name $PHENO --mem=85G \
    --wrap="/path3/BOLT-LMM_v2.3.1/bolt \
	--bed="$DIR"/ukb_cal_chr{1:22}_v2.bed \
	--bim="$DIR"/ukb_snp_chr{1:22}_v2.bim \
	--fam="$DIR"/ukb1404_cal_chr1_v2_CURRENT.fixCol6.fam \
	--remove="$DIR"/bolt.in_plink_but_not_imputed.FID_IID.976.txt \
	--remove="$DIR"/../sampleQC/remove.nonWhite.FID_IID.txt \
	--remove="$DIR"/List.of.other.individuals.tobe.excluded.from.gwas.txt \
	--exclude="$DIR"/../snpQC/autosome_maf_lt_0.001.txt \
	--exclude="$DIR"/../snpQC/autosome_missing_gt_0.1.txt \
	--phenoFile=/path4/Phenotypes.txt \
	--phenoCol="$PHENO" \
	--covarFile=/path4/covariates.plinkPCs.tab \
	--covarCol=cov_ASSESS_CENTER \
	--covarCol=cov_GENO_ARRAY \
	--covarMaxLevels=30 \
	--covarCol=cov_SEX \
	--qCovarCol=cov_AGE \
	--qCovarCol=cov_AGE_SQ \
	--qCovarCol=PC{1:20} \
	--LDscoresFile=/path5/LDSCORE.1000G_EUR.tab.gz \
	--geneticMapFile=/path6/genetic_map_hg19.txt.gz \
	--lmmForceNonInf \
	--numThreads="$THREADS" \
	--statsFile="$OUT_PREFIX".stats.gz \
	--bgenFile="$DIR"/ukb_imp_chr{1:22}_v3.bgen \
	--bgenMinMAF=0.01 \
    --bgenMinINFO=0.8 \
	--sampleFile="$DIR"/ukb1404_imp_chr1_v2_s487406.sample \
	--statsFileBgenSnps=$OUT_PREFIX.bgen.stats.gz \
	--verboseStats"
done


# -----------------------------------------------------------------------
# 
# below is a example code of using LDpred to develop PRS models 
#      based on GWAS summary data
# 
# paths and some file names were masked
# adjustment needs to be made based on your systems and data 
# 
# -----------------------------------------------------------------------

# for more information of how LDpred works, please see details in https://github.com/bvilhjal/ldpred

# in our study, UKB participants were seperated to two groups, the internal validition set was a ramdomly selected set of 20,000 individuals, and the rest of UKB participants were the training set that were used to run GWAS. NHS/HPFS participants were the external validation set for the PRS and were used for the interaction analysis
# below is a simple example code in the UKB


module load gcc/6.2.0 python/3.6.0

# Step 1: Coordinate data
# note: GWAS_ss_"$i".txt meanning the GWAS summary data for the ith phenotype 

for i in {1..3}; do sbatch -p short -e coordinate_$i.err -o coordinate_$i.out -t 00-10:00 --mem 96G --wrap="python /software/ldpred-1.0.6/LDpred.py coord \
--gf=/LD_Reference_Genotype_File \
--ssf=/GWAS_ss_"$i".txt \
--beta \
--ssf-format CUSTOM \
--rs RS \
--A1 A1 \
--A2 A2 \
--pos POS \
--chr CHR \
--pval PVAL \
--eff EFF \
--N=Number_of_Individuals \
--out=/COORD_FILE_"$i" "
done

# Step 2: Generate LDpred SNP weights

for i in {1..3}; do sbatch -p short -e gibbs_$i.err -o gibbs_$i.out -t 00-11:0:0 --mem 64G --wrap="python /software/ldpred-1.0.6/LDpred.py gibbs \
--cf=/COORD_FILE_"$i" \
--ldr=LD_radius \
--ldf=/OUT_ldf_file_"$i" \
--out=/OUTPUT_FILE_PREFIX_"$i" \
--N=Number_of_Individuals "
done

# Step 3: Generating individual risk scores in the internal validation set

for i in {1..1}; do sbatch -p priority -e score_$i.err -o score_$i.out -t 00-6:0:0 --mem 16G --wrap="python /software/ldpred-1.0.6/LDpred.py score \
--gf=/Validation_genotype_file \
--rf=/OUTPUT_FILE_PREFIX_"$i" \
--out=/score_"$i" \
--pf-format STANDARD \
--rf-format LDPRED "
done







































