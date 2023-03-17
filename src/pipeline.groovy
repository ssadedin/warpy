
title 'Warpy - Oxford Nanopore Super High Accuracy Pipeline'

options {
    fast5_dir 'Directory containig FAST5 files', args:1, type: File, required: true
    sample 'Name of sample', args:1, type: String, required: true
    targets 'Target regions to call variants in', args:1, type: File, required: true
    sex 'Sample sex (required for STR analysis)', args:1, type: String, required: true
}

List input_files = opts.fast5_dir.listFiles().grep { it.name.endsWith('.fast5') || it.name.endsWith('.blow5') }
input_pattern = input_files.any { it.endsWith('.fast5') } ? '%.fast5' : '%.blow5'

// to make pipeline generic to work for either fast5 or blow5,
// define virtual file extentions 'x5' that can map to either
filetype x5 : ['blow5','fast5']

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

load 'stages.groovy'
load 'sv_calling.groovy'
load 'str_calling.groovy'
   
init = {
    println "\nProcessing ${input_files.size()} input fast5 files ...\n"
    println "\nUsing base calling model: $params.drd_model"
    println "\nUsing clair3 model: $clair3_model"
    
    produce('versions.txt') {
        exec """
            echo $VERSION > versions.txt
        """
    }
}

run(input_files) {
    init + 
    make_mmi + input_pattern * [ dorado + minimap2_align ] + merge_pass_calls + read_stats +
    [
        snp_calling : make_clair3_chunks  * [ pileup_variants ] + aggregate_pileup_variants +
             [ 
                 get_qual_filter,
                 chr(1..22, 'X','Y') * [ 
                     select_het_snps + 
                     phase_contig + 
                     create_candidates + '%.bed' * [ evaluate_candidates ] ] 
             ] + aggregate_full_align_variants +
             chr(1..22, 'X','Y') *  [ merge_pileup_and_full_vars ] + aggregate_all_variants,
             
         sv_calling: mosdepth + filterBam + sniffles2 + filter_sv_calls,
         
         str_calling: chr(1..22, 'X','Y') *  [ call_str + annotate_repeat_expansions ] + 
             merge_str_tsv + merge_str_vcf
    ]
}
