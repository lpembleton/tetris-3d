process SAMTOOLS_STATS {
    tag "$meta.pid"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.stats")     , emit: stats

    script:
    def prefix = task.ext.prefix ?: "${meta.pid}"
    """
    samtools \
        stats \
        --threads 2 \
        ${bam} \
        > ${prefix}_samtools.stats

    """

}
