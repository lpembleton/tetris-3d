process SAMTOOLS_FAIDX {
    tag "$fasta"

    input:
    path(fasta)

    output:
    path ("*.fai"), emit: fai


    script:
    """
    samtools \
        faidx \
        $fasta

    """

}
