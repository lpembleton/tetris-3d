process BWA_MEM {
    tag "mapping $meta.pid"

	publishDir "$params.outdir/mapping", pattern: '*.bam', mode: 'copy', enabled: (params.split_fastq == 0 && params.skip_markdup)
	publishDir "$params.outdir/mapping", pattern: '*.bai', mode: 'copy', enabled: (params.split_fastq == 0 && params.skip_markdup)

    input:
    tuple val(meta), val(read_type), path(reads)
    path(index)
    
    output:
    tuple val(meta), path("*.bam"), path("*bai"), emit: bam

    script:
    def prefix = task.ext.prefix ?: "${meta.pid}"
	"""
		INDEX=`find -L ./ -name "*.amb" | sed 's/.amb//'`

		bwa mem \
			-t 4 \
			\${INDEX} \
			-R ${meta.read_group} \
			$reads \
			| samtools sort --threads $task.cpus -o ${prefix}.bam
		
		samtools \
			index \
			-@ 1 \
			${prefix}.bam

	"""
}