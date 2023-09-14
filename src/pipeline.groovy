
title 'Warpy - Oxford Nanopore Super High Accuracy Pipeline'

options {
    sample 'Name of sample', args:1, type: String, required: true
    targets 'Target regions to call variants in', args:1, type: File, required: true
    sex 'Sample sex (required for STR analysis)', args:1, type: String, required: true
}

ext = { File file ->
    file.name.tokenize('.')[-1]
}

if(args.size()==0) 
    throw new bpipe.PipelineError(
        """
        No data directories were provided to analyse. 

        Please provide one or more data directories containing pod5, fast5 or blow5 files as arguments.
        """
    )

List input_files = args.collect { new File(it) }*.listFiles().flatten().grep { ext(it) in ['fast5','blow5','pod5']  }

by_extension = input_files.groupBy { ext(it) }
if(by_extension.size() > 1) 
    throw new bpipe.PipelineError("Warpy can only accept a single file type for analysis in one execution")

input_pattern = '%' + by_extension*.key[0]

// to make pipeline generic to work for either fast5 or blow5,
// define virtual file extentions 'x5' that can map to either
filetype x5 : ['blow5','fast5','pod5']

Map params = model.params

DRD_MODELS_PATH="$BASE/models"

VERSION="1.0"

// Convert basecaller model to Clair3 model
model_map_file = "$BASE/data/clair3_models.tsv"
model_map = new graxxia.TSV(model_map_file).toListMap()
clair3_model = model_map.find { it.basecaller == 'dorado' && it.basecall_model_name == params.drd_model }
assert clair3_model != null : 'No dorado model for base caller model ' + params.drd_model + ' could be found in ' + model_map_file

if(clair3_model.clair3_model_name == '-') 
    throw new bpipe.PipelineError("No suitable clair3 model could be found: $clair3_model.clair3_nomodel_reason")

targets = bed(opts.targets)

str_chrs = new File(calling.repeats_bed).readLines()*.tokenize()*.getAt(0).unique()

println "The chromosomes for STR calling are: $str_chrs"

load 'stages.groovy'
load 'sv_calling.groovy'
load 'str_calling.groovy'
// load 'methylation.groovy'
   
init = {
    println "\nProcessing ${input_files.size()} input files ...\n"
    println "\nUsing base calling model: $params.drd_model"
    println "\nUsing clair3 model: $clair3_model"
    
    produce('versions.txt') {
        exec """
            echo $VERSION > versions.txt
        """
    }
}

// Adjust this group size so that a reasonable amount of compute is performed by
// each dorado job
dorado_group_size = 10

// divide the input files into groups of appropriate size
// so that we can split into multiple different dorado jobs
input_groups = input_files.collate(dorado_group_size).indexed().collectEntries { 
    [ "dorado_group_" + it.key, it.value] 
}

run(input_files) {

    init + 
    make_mmi + input_pattern * [ convert_fast5_to_pod5.when { input.x5.endsWith('.fast5') } + dorado + minimap2_align ] + merge_pass_calls + read_stats +
    [
         snp_calling : make_clair3_chunks  * [ pileup_variants ] + aggregate_pileup_variants +
         [ 
                get_qual_filter,
                chr(1..22, 'X','Y') * [
                    select_het_snps + phase_contig,
                    create_candidates + '%.bed' * [ evaluate_candidates ] ] 
                + aggregate_full_align_variants
         ] +
            chr(1..22, 'X','Y') * [ merge_pileup_and_full_vars ] + aggregate_all_variants ]/*,
             
         sv_calling: mosdepth + filterBam + sniffles2 + filter_sv_calls,
         
         str_calling: chr(*str_chrs) *  [ call_str + annotate_repeat_expansions ] + merge_str_tsv + merge_str_vcf
    ]
    */
}
