#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Parameters
params.workflow = null
params.run_discovery = false
params.run_mapping = false

// Include your workflows
include { DISCOVERY } from './workflows/discovery.nf'
include { MAPPING } from './workflows/mapping.nf'

// Named workflows for -entry usage
workflow discovery {
    DISCOVERY()
}

workflow mapping {
    MAPPING()
}

// Main workflow with parameter logic
workflow {
    if (params.run_discovery || params.workflow == 'discovery') {
        DISCOVERY()
    }
    else if (params.run_mapping || params.workflow == 'mapping') {
        MAPPING()
    }
    else {
        log.info """
        Please specify which workflow to run:
        
        Option 1: Use -entry flag
          nextflow run main.nf -entry discovery
          nextflow run main.nf -entry mapping
          
        Option 2: Use parameters
          nextflow run main.nf --workflow discovery
          nextflow run main.nf --workflow mapping
          
        Option 3: Use boolean flags
          nextflow run main.nf --run_discovery
          nextflow run main.nf --run_mapping
        """
        error "No workflow specified"
    }
}
