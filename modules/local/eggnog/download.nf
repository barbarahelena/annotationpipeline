process EGGNOG_DOWNLOAD {
    tag "download"
    label 'process_single'
    storeDir "${ task.ext.storeDir ?: 'db/eggnog' }"

    conda "bioconda::eggnog-mapper=2.1.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper%3A2.1.12--pyhdfd78af_2':
        'biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_2' }"

    output:
    path "eggnog.db"                  , emit: eggnog
    path "eggnog_proteins.dmnd"       , emit: dmnd
    path "eggnog.taxa.db"             , emit: taxa
    path "eggnog.taxa.db.traverse.pkl", emit: pkl
    path "*"                          , emit: all
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    download_eggnog_data.py $args -y --data_dir .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog: \$( echo \$(emapper.py --version 2>&1)| sed 's/.* emapper-//' | sed 's/ \\/ Expected.*//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog: \$( echo \$(emapper.py --version 2>&1)| sed 's/.* emapper-//' | sed 's/ \\/ Expected.*//')
    END_VERSIONS
    """
}
