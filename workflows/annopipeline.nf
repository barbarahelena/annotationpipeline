/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { DIAMOND_BLASTP         } from '../modules/nf-core/diamond/blastp/main'
include { DIAMOND_MAKEDB         } from '../modules/nf-core/diamond/makedb/main' 
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_annopipeline_pipeline'

include { CAYMAN_DOWNLOAD        } from '../modules/local/cayman/download'
include { CAYMAN_CAYMAN          } from '../modules/local/cayman/cayman'
include { CAT_CAT as CAYMAN_CAT  } from '../modules/nf-core/cat/cat/main'
include { EGGNOG_DOWNLOAD        } from '../modules/local/eggnog/download'
include { EGGNOG_MAPPER          } from '../modules/local/eggnog/mapper'
include { CAT_CAT as EGGNOG_CAT  } from '../modules/nf-core/cat/cat/main' 
include { BAKTA_BAKTADBDOWNLOAD  } from '../modules/local/bakta/baktadbdownload/main'
include { BAKTA_BAKTA            } from '../modules/local/bakta/bakta/main'
include { VFDB_DOWNLOAD          } from '../modules/local/vfdb/download'
include { CAT_CAT as VFDB_CAT    } from '../modules/nf-core/cat/cat/main' 

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANNOPIPELINE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    bakta_db = params.bakta_database ? Channel.fromPath( params.bakta_database ) : []
    cayman_db = params.cayman_database ? Channel.fromPath( params.cayman_database ) : []
    vfdb_db = params.vfdb_database ? Channel.fromPath( params.vfdb_database ) : []
    diamond_db = params.diamond_database ? Channel.fromPath( params.diamond_database ) : []

    //
    // MODULE: Bakta
    // 
    if ( params.annotation ) {
        if ( ! bakta_db ){
            BAKTA_BAKTADBDOWNLOAD()
            bakta_db = BAKTA_BAKTADBDOWNLOAD.out.db
        }         
        BAKTA_BAKTA( 
            ch_samplesheet, 
            bakta_db,
            [],
            []
        )
        ch_annotation = BAKTA_BAKTA.out.faa
        ch_versions = ch_versions.mix( BAKTA_BAKTA.out.versions )
    } else{
        ch_annotation = ch_samplesheet
    }

    //
    // MODULE: EGGNOG Mapper
    //
    if ( params.eggnogmapper ) {
        EGGNOG_DOWNLOAD ()
        ch_eggnog_db = EGGNOG_DOWNLOAD.out.eggnog
                            .combine(EGGNOG_DOWNLOAD.out.dmnd)
                            .combine(EGGNOG_DOWNLOAD.out.taxa)
                            .combine(EGGNOG_DOWNLOAD.out.pkl)
                            .collect()

        EGGNOG_MAPPER (
            ch_annotation,
            ch_eggnog_db
        )
        ch_versions = ch_versions.mix(EGGNOG_MAPPER.out.versions)

        ch_eggnog_tables = EGGNOG_MAPPER.out.anno
                .collect { meta, txt -> txt }
                .map { files -> [['id': 'all_eggnog_results'], files] }

        EGGNOG_CAT ( ch_eggnog_tables )
        ch_versions = ch_versions.mix( EGGNOG_CAT.out.versions )
    }

    // 
    // MODULE: Cayman
    //
    if ( params.cayman ) {
        if(!cayman_db){
            CAYMAN_DOWNLOAD()
            cayman_db = CAYMAN_DOWNLOAD.out.db
        }
        CAYMAN_CAYMAN (
            ch_annotation,
            cayman_db
        )
        ch_versions = ch_versions.mix(CAYMAN_CAYMAN.out.versions)

        CAYMAN_CAT ( 
            CAYMAN_CAYMAN.out.cayman
                .collect { meta, txt -> txt }
                .map { files -> [['id': 'all_cayman_results'], files] }
        )
        ch_versions = ch_versions.mix(CAYMAN_CAT.out.versions)
    }

    //
    // MODULE: Diamond
    //
    if ( params.diamond ) {
        if(!vfdb_db && !diamond_db){
            VFDB_DOWNLOAD ( )
            vfdb_db = VFDB_DOWNLOAD.out.db
        }
        if(! diamond_db ){
        ch_vfdb_for_makedb = vfdb_db.map { db -> [['id': 'vfdb_db'], db] }
        DIAMOND_MAKEDB (
            ch_vfdb_for_makedb,
            [],
            [],
            []
        )
        ch_diamond_db = DIAMOND_MAKEDB.out.db
        ch_versions = ch_versions.mix(DIAMOND_MAKEDB.out.versions)
        } else{
            ch_diamond_db = diamond_db.map { db -> [['id': 'diamond_db'], db] }
        }
        
        DIAMOND_BLASTP ( // task.ext: '-e 0.00001 -k 1 --header'
            ch_annotation,
            ch_diamond_db,
            6, // outfmt
            []
        )
        
        ch_versions = ch_versions.mix(DIAMOND_BLASTP.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(DIAMOND_BLASTP.out.blast.collect{it[1]})
        ch_vfdb_files = DIAMOND_BLASTP.out.txt
                            .collect { meta, txt -> txt }
                            .map { files -> [['id': 'all_vfdb_results'], files]}

        VFDB_CAT ( ch_vfdb_files )
        ch_versions = ch_versions.mix(VFDB_CAT.out.versions)
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'annopipeline_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
