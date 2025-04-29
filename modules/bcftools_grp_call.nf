process BCFTOOLS_GRP_CALL {
    tag "grouped call"

    publishDir "$params.outdir/variants", pattern: '*.vcf.gz', mode: 'copy'

    input:
    path(bam)
    path(bai)
    path fasta
    path fai
    tuple val(region), path(bed)

    output:
    path("*.vcf.gz") , emit: vcf
    
    script:
    def prefix = task.ext.prefix ?: "$params.outPrefix"
    """
    bcftools mpileup \
        --output-type u \
        --fasta-ref ${fasta} \
        --regions-file ${bed} \
        --annotate AD,DP,INFO/AD \
        --threads 4 \
        --max-depth 1000 \
        ${bam} | \
            bcftools call \
            --multiallelic-caller \
            --output-type z \
            --targets-file ${bed} \
            --group-samples - \
            --skip-variants indels \
            --variants-only \
			-f GQ,GP \
            --threads 4 \
            --output ${prefix}_${region}_variants.vcf.gz
    """
}
