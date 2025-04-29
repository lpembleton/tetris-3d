process BCFTOOLS_CONCAT {
    tag "concat vcf"

    publishDir "$params.outdir/variants", pattern: '*.vcf.gz', mode: 'copy'

    input:
    path(vcf)

    output:
    path("*.vcf.gz") , emit: vcf
    
    script:
    def prefix = task.ext.prefix ?: "$params.outPrefix"
    """
	bcftools concat *vcf.gz \
		--output-type z \
		--threads $task.cpus \
        --output ${prefix}.vcf.gz
    """
}
