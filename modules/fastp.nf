process FASTP {
    tag "$meta.pid"

    input:
    tuple val(meta), val(read_type), path(reads)
    val split_lines
    
    output:
	tuple val(meta), val(read_type), path('*.fastp.fastq.gz') , emit: trimmed_reads
    path "*.fastp.{json,html}", emit: fastp_reports
    
    script:
	def prefix = task.ext.prefix ?: "${meta.pid}"
    def split_param = split_lines > 1 ? "--split_by_lines ${params.split_lines * 4}" : ""
	if (meta.read_type == "single") {
        """
        fastp \
            --in1 ${reads} \
            --out1 ${prefix}_1.fastp.fastq.gz \
			${split_param} \
            --json ${prefix}.fastp.json \
            --html ${prefix}.fastp.html \
            --thread $task.cpus \
            $args \
            2> ${prefix}.fastp.log

        """
    } else {
        """
        fastp \
            --in1 ${reads[0]} \
            --in2 ${reads[1]} \
            --out1 ${prefix}_1.fastp.fastq.gz \
            --out2 ${prefix}_2.fastp.fastq.gz \
			${split_param} \
            --json ${prefix}.fastp.json \
            --html ${prefix}.fastp.html \
            --thread $task.cpus \
            $args \
            2> ${prefix}.fastp.log

        """
    }

}