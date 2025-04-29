include { FASTP } from '../modules/fastp'
include { FASTQC } from '../modules/fastqc'
include { BWA_INDEX } from '../modules/bwa_index'
include { BWA_MEM } from '../modules/bwa_mem'
include { SAMTOOLS_MERGE } from '../modules/samtools_merge'
include { SAMTOOLS_STATS } from '../modules/samtools_stats'
include { SAMTOOLS_FAIDX } from '../modules/samtools_faidx'
include { MOSDEPTH } from '../modules/mosdepth'
include { GATK4_MARKDUPLICATES } from '../modules/gatk4_markduplicates'
include { AWK_SPLITBED } from '../modules/awk_splitbed'
include { BCFTOOLS_GRP_CALL } from '../modules/bcftools_grp_call'
include { BCFTOOLS_CONCAT } from '../modules/bcftools_concat'
include { INDEX_BAM } from '../modules/index_bam'

workflow DISCOVERY {

	if (!params.skip_mapping) {

		// Read input samplesheet
		Channel
			.fromPath(params.samplesheet)
			.splitCsv(header:true)
			.map { row -> 
				def meta = [
					uuid: row.uuid,
					sample_name: row.sample_name,
					seq_ID: row.seq_ID,
					resub_no: row.resub_no,
					seq_centre: row.seq_centre,
					seq_date: row.seq_date,
					pid: row.resub_no ? "${row.uuid}_${row.resub_no}" : row.uuid,  // Create the pid field
					read_group: "\"@RG\\tID:${row.uuid}\\tSM:${row.uuid}\\tDS:${params.reference}\"" // read group header for bwa mem
				]
				def fastq = row.fastq_2 ? [file(row.fastq_1), file(row.fastq_2)] : file(row.fastq_1)
				[ meta, row.read_type, fastq ]
			}
			.set { samples_ch }


		if (params.skip_fastp) {
			// skip fastp
			trimmed_reads_ch = samples_ch
		} else {
			FASTP(samples_ch, params.split_lines)
			trimmed_reads_ch = FASTP.out.trimmed_reads
		}
		
		// QC on trimmed reads
		FASTQC(trimmed_reads_ch)

		// Prepare reference fasta index
		BWA_INDEX(params.reference)

		// Map reads to reference fasta
		BWA_MEM(trimmed_reads_ch, BWA_INDEX.out.index)

		// merge split bams per sample
		if (params.split_lines > 0) { // if reads were split merge them back together before next steps
			SAMTOOLS_MERGE(BWA_MEM.out.bam.groupTuple())
			merged_bams_ch = SAMTOOLS_MERGE.out.bam  
		} else {
			merged_bams_ch = BWA_MEM.out.bam
		}

		// duplicate read marking
		if (params.skip_markdup) {
			dedup_bams_ch = merged_bams_ch
		} else {
			GATK4_MARKDUPLICATES(merged_bams_ch)
			dedup_bams_ch = GATK4_MARKDUPLICATES.out.bam
		}

		// Get bam stats
		SAMTOOLS_STATS(dedup_bams_ch)

		// WGS coverage stats
		MOSDEPTH(dedup_bams_ch)

	} else{

		bam_ch = Channel
			.fromPath(params.samplesheet)
			.splitCsv(header:true)
			.map { row -> tuple(row.sample, file(row.bam)) }

		INDEX_BAM(bam_ch)

		dedup_bams_ch = bam_ch.join(INDEX_BAM.out.bam_index, by: 0)

	}


	// Prepare reference fasta index
    SAMTOOLS_FAIDX(params.reference)
	// perform variant calling on all samples together (e.g. variant discovery)

	split_beds = AWK_SPLITBED(params.regions)

	// Create a channel with region name and bed file
	region_beds_ch = split_beds.flatten()
		.map { bed -> 
		def region = bed.baseName
		return tuple(region, bed)
		}

	// From testing running bcftools mpileup piped into bcftools call in the same process runs quicker or equivalent to 2 seperate processes
	BCFTOOLS_GRP_CALL(dedup_bams_ch.map { tuple -> tuple[1] }.collect(), dedup_bams_ch.map { tuple -> tuple[2] }.collect(), params.reference, SAMTOOLS_FAIDX.out.fai, region_beds_ch) 

	BCFTOOLS_CONCAT(BCFTOOLS_GRP_CALL.out.vcf.collect())

}