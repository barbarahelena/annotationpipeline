<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="">
    <img alt="annopipeline" src="">
  </picture>
</h1>

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**annopipeline** is a bioinformatics pipeline that performs functional annotation of genomes and bacterial metagenomes. It annotates proteins using Bakta, and the Bakta output is then used for further functional annotation of the proteins using eggNOG-mapper, Cayman, and VFDB. The pipeline is designed to be flexible and can be run on a variety of platforms, including local machines and clusters.

<!-- 1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))-->
1. Annotation of genomes using Bakta ([`Bakta`](https://github.com/oschwengers/bakta))
2. EggNOG functional annotation of the proteins ([`eggNOG-mapper`](https://github.com/eggnogdb/eggnog-mapper))
3. Cayman carbohydrate active enzymes (CAZy) profiling of proteins ([`Cayman`](https://github.com/zellerlab/cayman))
4. Virulence factor annotation profiling using VFDB ([`VFDB`](https://www.mgc.ac.cn/VFs/main.htm)) and Diamond ([`Diamond`](https://github.com/bbuchfink/diamond))
<!-- 5. Present QC for raw reads and Diamond  ([`MultiQC`](http://multiqc.info/)) -->

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fasta
Sample1,/path/to/sample1.fasta
```

Each row represents either an assembly fasta or Bakta .faa output (to skip the Bakta step).

Now, for assemblies, you can run the pipeline using:

```bash
nextflow run annopipeline \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

If you already have Bakta output files, you can provide the Bakta .faa files in the samplesheet and skip the Bakta step by using the `--annotation false` parameter:

```bash
nextflow run annopipeline \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --annotation false
```

For more details and further functionality, please refer to the [usage documentation](https://github.com/barbarahelena/assembly_annotation/blob/master/docs/usage.md) and the [parameter documentation](https://github.com/barbarahelena/assembly_annotation/blob/master/docs/parameters.md).

## Pipeline output

For more details about the output files and reports, please refer to the
[output documentation](https://github.com/barbarahelena/assembly_annotation/blob/master/docs/output.md).

## Credits

annopipeline was originally written by Barbara Verhaar and Kyanna Ouyang. If you would like to contribute to this pipeline, please open a pull request or issue.

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.