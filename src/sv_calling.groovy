

filterBam = {

    output.dir = "align"

    filter('filtered') {
        exec """
            $tools.SAMTOOLS view -@ $threads 
                $input.bam
                -F 2308 
                -o $output.bam
                --write-index 
                --reference $REF
        """
    }
}


// NOTE VCF entries for alleles with no support are removed to prevent them from
//      breaking downstream parsers that do not expect them
sniffles2 = {
    
    var sniffles_args : ''
    
    branch.dir = "sv/$opts.sample"

    produce("${opts.sample}.sniffles.vcf") {
        exec """
            export REF_PATH=$REF

            sniffles
                --threads $threads
                --sample-id ${opts.sample}
                --output-rnames
                --cluster-merge-pos $calling.cluster_merge_pos
                --input $input.bam
                --tandem-repeats ${calling.tr_bed} $sniffles_args
                --vcf ${output.vcf.prefix}.tmp.vcf

            sed '/.:0:0:0:NULL/d' ${output.vcf.prefix}.tmp.vcf > $output.vcf
        """
    }
}

filter_sv_calls = {
//    input:
//        file vcf
//        tuple path(mosdepth_bed), path(mosdepth_dist), path(mosdepth_threshold) // MOSDEPTH_TUPLE
//        file target_bed
//    output:
//        path "*.filtered.vcf", emit: vcf
//    script:
//        def sv_types_joined = params.sv_types.split(',').join(" ")
    

    from('*.regions.bed.gz') produce("${opts.sample}.wf_sv.vcf.gz", "${opts.sample}_filter.sh") {
        exec """
            set -o pipefail

            $BASE/scripts/get_filter_calls_command.py 
                --target_bedfile $opts.targets
                --vcf $input.vcf
                --depth_bedfile $input.bed.gz
                --min_sv_length $calling.min_sv_length
                --max_sv_length $calling.max_sv_length
                --sv_types ${calling.sv_types.split(',').join(' ')}
                --min_read_support $calling.min_read_support
                --min_read_support_limit $calling.min_read_support_limit > $output.sh

            bash $output.sh > $output.vcf.gz.prefix

            vcfsort $input.vcf | bgziptabix $output.vcf.gz
        """
    }
}

// NOTE This is the last touch the VCF has as part of the workflow,
//  we'll rename it with its desired output name here
sort_sv_vcf = {
//    label "wf_human_sv"
//    cpus 1
//    input:
//        file vcf
//    output:
//        path "*.wf_sv.vcf", emit: vcf
    
    produce("${opts.sample}.wf_sv.vcf.gz") {
        exec """
            vcfsort $input.vcf | bgziptabix $output.vcf.gz
        """
    }
}


