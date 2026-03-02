process SAMTOOLS_MERGE {
    tag "$meta.pid"

    publishDir "$params.outdir/mapping", pattern: '*.merged.bam', mode: 'copy', enabled: params.skip_markdup
    publishDir "$params.outdir/mapping", pattern: '*.merged.bam.bai', mode: 'copy', enabled: params.skip_markdup  

    input:
    tuple val(meta), path(input_files, stageAs: "?/*")

    output:
    tuple val(meta), path("${prefix}.merged.bam"), path("${prefix}.merged.bam.bai"), emit: bam

    script:
    prefix   = task.ext.prefix ?: "${meta.pid}"
    """
    samtools \
        merge \
        --threads 1 \
        ${prefix}.merged.bam \
        $input_files

    samtools \
        index \
        ${prefix}.merged.bam

    """
}