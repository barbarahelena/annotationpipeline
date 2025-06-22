process VFDB_DOWNLOAD {
    tag "download"
    label 'process_single'
    storeDir "${ task.ext.storeDir ?: 'db/VFDB' }"

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    output:
    path("*.fas"), emit: db

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    curl "https://www.mgc.ac.cn/VFs/Down/VFDB_setB_pro.fas.gz"
    gunzip VFDB_setB_pro.fas.gz
    """
}