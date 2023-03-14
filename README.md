
WARPY
==================================

Warpy is a long read sequencing workflow written in Bpipe. The 
name "warpy" derives from "War and Peace" which is a very famous long read. 
However Warpy is not original; it is a port of the official [Oxford Nanopore
Nextflow Pipeline](https://github.com/epi2me-labs/wf-human-variation).

Setup
-----

Warpy mostly utilises ONT provided containers for its steps. However
currently you need to set up some tools and paths yourself (dorado, samtools, minimap2)
which are usually straight forward. 

To do this, open the `src/bpipe.config` file and search for all lines containing "SETME"
and add in appropriate values.

You will also want to configure your compute resources (eg: scheduler or cloud compute system, etc)
by following standard Bpipe configuration steps for these.

Running
-------

Run warpy like so:

```
bpipe run /path/to/warpy/src/pipeline.groovy -fast5_dir /path/to/fast5/data -sample TEST_SAMPLE -targets target_regions.bed
```

Credits
-------

Warpy is entirely based on the official [Epi2Me Nextflow pipeline](https://github.com/epi2me-labs/wf-human-variation) found 
in the nf-core repository. All credits belong to the team who created that pipeline. Warpy also reuses most of the 
docker containers from the wf-human-variation pipeline, representing much of the overall work and value.

