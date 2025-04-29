#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { DISCOVERY } from './workflows/discovery'

workflow {
    DISCOVERY()
}
