process INDEX_BAM {
    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path("*.bai"), emit: bam_index

    script:
    """
    samtools index ${bam}
    """
}
