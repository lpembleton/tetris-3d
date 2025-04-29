process MOSDEPTH {
    tag "$meta.pid"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path('*.global.dist.txt')   , emit: global_txt
    path('*.summary.txt')       , emit: summary_txt
    path  "versions.yml"        , emit: versions    

    script:
    """
    mosdepth -n --fast-mode --by 500 $meta.pid $bam
  
    """
    
}