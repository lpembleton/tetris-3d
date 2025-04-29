process BWA_INDEX {
    tag "$fasta"

    input:
    path(fasta)

    output:
    path(bwa) , emit: index

    script:
    """
    mkdir bwa
    bwa \\
        index \\
        -p bwa/\$(basename ${fasta}) \\
        ${fasta}

    """
}
