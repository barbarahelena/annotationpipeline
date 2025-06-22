process CAYMAN_CAYMAN {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::cayman=0.10.1"
    container "docker://ghcr.io/zellerlab/cayman@sha256:29da4ffcbb1cf4efe5d36213eac9c036e1be2358018db7122a4035f1f16983c0"

    input:
    tuple val(meta), path(input)
    path(db)

    output:
    tuple val(meta), path("*.csv"), emit: cayman
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cayman annotate_proteome \\
        ${db} \\
        ${input} \\
        $args \\
        -t $task.cpus \\
        -o ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cayman: \$(cayman --version |& sed '1!d ; s/cayman //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cayman: \$(cayman --version |& sed '1!d ; s/cayman //')
    END_VERSIONS
    """
}
