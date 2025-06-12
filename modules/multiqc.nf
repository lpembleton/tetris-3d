process MULTIQC {
    publishDir "$params.outdir/multiqc_report", mode:'copy'

    input:
    path  multiqc_files, stageAs: "?/*"

    output:
    path "multiqc_report.html", emit: report

    script:
    """
    multiqc .

    """
}
