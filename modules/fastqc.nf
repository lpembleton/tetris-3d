process FASTQC {
    tag "$meta.pid"

    input:
    tuple val(meta), val(read_type), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip

    script:
    """

    fastqc -t 2 -f fastq -q ${reads}

    """
}