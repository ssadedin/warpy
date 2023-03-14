
title 'Warpy - Oxford Nanopore Super High Accuracy Pipeline'

options {
    fast5_dir 'Directory containig FAST5 files', args:1, type: File, required: true
    sample 'Name of sample', args:1, type: String, required: true
    targets 'Target regions to call variants in', args:1, type: File, required: true
}

List input_files = opts.fast5_dir.listFiles().grep { it.name.endsWith('.fast5') }


Map params = model.params

DRD_MODELS_PATH="$BASE/models"

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
    
init = {
    println "\nProcessing ${input_files.size()} input fast5 files ...\n"
    println "\nUsing base calling model: $params.drd_model"
    println "\nUsing clair3 model: $clair3_model"
    
    output.dir = "cram_cache"
    produce('cram_cache_init.txt') {
        exec """
            date > $output.txt
        """
    }
}

dorado = {

    output.dir='dorado/' + file(input.fast5.prefix).name
    
    uses(dorados: 1) {
        exec """
            set -o pipefail

            ln -s ${file(input.fast5).absolutePath} $output.dir/${file(input.fast5).name}

            $tools.DORADO basecaller $DRD_MODELS_PATH/$params.drd_model $output.dir | $tools.SAMTOOLS view -b -o $output.ubam -
        """
    }
}

make_mmi = {
    output.dir = 'ref'

    produce('ref.mmi') {
        exec """
            $tools.MINIMAP2 -t ${threads} -x map-ont -d $output ${REF}
        """
    }
}

minimap2_align = {
    
    def SAMTOOLS = tools.SAMTOOLS
    
    output.dir = 'align'

    exec """
        $SAMTOOLS bam2fq -@ $threads -T 1 $input.ubam
            | $tools.MINIMAP2 -y -t $threads -ax map-ont $input.mmi - 
            | $SAMTOOLS sort -@ $threads
            | tee >($SAMTOOLS view -e '[qs] < $calling.qscore_filter' -o $output.fail.bam - )
            | $SAMTOOLS view -e '[qs] >= $calling.qscore_filter' -o $output.pass.bam -

        $SAMTOOLS index $output.pass.bam

    """
}

run(input_files) {
    init + 
    make_mmi + '%.fast5' * [ dorado + minimap2_align ] + merge_pass_calls +
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
             
         sv_calling: mosdepth + filterBam + sniffles2 + filter_sv_calls
    ]
    
}


/*

```plantuml

component MCRI {
    database "IBM SpecScale Storage" as IBM
    node Meerkat
}

cloud "Google Cloud" as GC {
    database "Google Cloud Storage" as GCS
}

IBM -> GCS : Copied using Google Cloud\ncommand line utilities

```

*/
