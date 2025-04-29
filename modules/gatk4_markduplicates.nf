process GATK4_MARKDUPLICATES {
    tag "$meta.pid"

    publishDir "$params.outdir/mapping", pattern: '*markdup.bam', mode: 'copy'
    publishDir "$params.outdir/mapping", pattern: '*markdup.bai', mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*markdup.bam"), path("*markdup.bai"), emit: bam
    tuple val(meta), path("*.metrics"), emit: metrics

    script:
    def avail_mem = 16
    def prefix = task.ext.prefix ?: "${meta.pid}"
    """
    gatk --java-options "-Xmx${avail_mem}g" MarkDuplicates \
        --INPUT ${bam} \
        --OUTPUT ${prefix}.markdup.bam \
        --METRICS_FILE ${prefix}.metrics \
        --CREATE_INDEX true \
        --TMP_DIR . \
        --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 \
        --VALIDATION_STRINGENCY LENIENT \
        --MAX_FILE_HANDLES_FOR_READ_ENDS_MAP 800 \

    rm ${bam}

    samtools index ${prefix}.markdup.bam

    """
}