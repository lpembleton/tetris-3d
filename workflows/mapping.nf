include { FASTP } from '../modules/fastp'
include { FASTQC } from '../modules/fastqc'
include { BWA_INDEX } from '../modules/bwa_index'
include { BWA_MEM } from '../modules/bwa_mem'
include { INDEX_BAM } from '../modules/index_bam'
include { SAMTOOLS_MERGE } from '../modules/samtools_merge'
include { SAMTOOLS_STATS } from '../modules/samtools_stats'
include { SAMTOOLS_FAIDX } from '../modules/samtools_faidx'
include { MOSDEPTH } from '../modules/mosdepth'
include { GATK4_MARKDUPLICATES } from '../modules/gatk4_markduplicates'
include { AWK_SPLITBED } from '../modules/awk_splitbed'
include { MULTIQC } from '../modules/multiqc'

workflow MAPPING {

	ch_reports = Channel.empty()

	// Read input samplesheet
	Channel
		.fromPath(params.samplesheet)
		.splitCsv(header:true)
		.take(params.max_samples)  // Limit to specified number of rows
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
		// fun fastp and read split if split_lines > 0
		FASTP(samples_ch, params.split_lines)

		trimmed_reads_ch = FASTP.out.trimmed_reads
        .flatMap { meta, read_type, fastq_files ->
            // Group into pairs and create individual channel entries
            fastq_files.collate(2).collect { pair ->
                [meta, read_type, pair]
            }
        }
		
		ch_reports = ch_reports.mix(FASTP.out.fastp_reports)
	}

	// QC on trimmed reads
	FASTQC(trimmed_reads_ch)
    ch_reports = ch_reports.mix(FASTQC.out.zip.collect{ meta, logs -> logs })

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
		ch_reports = ch_reports.mix(GATK4_MARKDUPLICATES.out.metrics.collect{ meta, metrics -> metrics })
		dedup_bams_ch = GATK4_MARKDUPLICATES.out.bam
	}

	// Get bam stats
	SAMTOOLS_STATS(dedup_bams_ch)
	ch_reports = ch_reports.mix(SAMTOOLS_STATS.out.stats)

	// WGS coverage stats
	MOSDEPTH(dedup_bams_ch)
	ch_reports = ch_reports.mix(MOSDEPTH.out.global_txt)
    ch_reports = ch_reports.mix(MOSDEPTH.out.summary_txt)

	// Generate multiqc report
	MULTIQC(ch_reports.collect())


}