process EGGNOG_MAPPER {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::eggnog-mapper=2.1.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper%3A2.1.12--pyhdfd78af_2':
        'biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_2' }"

    input:
    tuple val(meta), path(faa)
    path(eggnog_files), stageAs: 'eggnog/*'

    output:
    tuple val(meta), path("*.emapper.hits")                   , emit: hits
    tuple val(meta), path("*.emapper.seed_orthologs")         , emit: seedorthologs
    tuple val(meta), path("*.emapper.annotations")            , emit: anno
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    emapper.py \\
        $args \\
        -i ${faa} \\
        -o ${prefix} \\
        --data_dir eggnog \\
        --cpu ${task.cpus} \\
        --output ${prefix} \\
        --dbmem

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog: \$( echo \$(emapper.py --version 2>&1)| sed 's/.* emapper-//' | sed 's/ \\/ Expected.*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.emapper.hits
    touch ${prefix}.emapper.seed_orthologs
    touch ${prefix}.emapper.annotations
    touch ${prefix}.emapper.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog: \$( echo \$(emapper.py --version 2>&1)| sed 's/.* emapper-//' | sed 's/ \\/ Expected.*//')
    END_VERSIONS
    """
}
