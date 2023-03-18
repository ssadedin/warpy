
WARPY
==================================

Warpy is a long read sequencing workflow written in Bpipe. The 
name "warpy" derives from "War and Peace" which is a very famous long read. 
However Warpy is not original; it is a port of the official [Oxford Nanopore
Nextflow Human Variation Pipeline](https://github.com/epi2me-labs/wf-human-variation).

Currently Warpy supports the following arms of the wf-human-variation pipeline:

- Basecalling from FAST5/Blow5
- SNV/indel calling 
- SV calling
- STR calling

Methylation calling is not yet implemented.

Setup
-----

Warpy mostly utilises ONT provided containers for its steps. However
currently you need to set up some tools and paths yourself (dorado, samtools, minimap2)
which are usually straight forward. 

To do this, open the `src/bpipe.config` file and search for all lines containing "SETME"
and add in appropriate values.

You will also want to configure your compute resources (eg: scheduler or cloud compute system, etc)
by following standard Bpipe configuration steps for these.

To run basecalling, you also need to download the appropriate basecalling model to match your sequencing
data and configure it in the `bpipe.config` file. See [here](https://github.com/nanoporetech/dorado#available-basecalling-models)
for how to acquire the relevant models.

Running
-------

Run warpy like so:

```
/path/to/warpy/tools/bpipe/0.9.12/bin/bpipe run /path/to/warpy/src/pipeline.groovy -fast5_dir /path/to/fast5/data -sample TEST_SAMPLE -targets target_regions.bed
```

Credits
-------

Warpy is entirely based on the official [Epi2Me Nextflow pipeline](https://github.com/epi2me-labs/wf-human-variation), including direct use of many of the docker containers. All credits belong to the team who created that pipeline, and any bugs or introduced differences or issues lie entirely outside their responsibility.

**NOTE**: this pipeline was created in part as a learning exercise and also as an alternative for people who have a strong preference for using Bpipe to process their Nanopore data. If you are generically interested in processing Nanopore data outside of this context, please first check out the official pipeline rather than this fork!