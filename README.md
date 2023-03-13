
WARPY
==================================

Warpy is a long read sequencing workflow written in Bpipe. The 
name "warpy" derives from "War and Peace" which is a very famous long read. 
However Warpy is not original; it is a port of the official Oxford Nanopore
Nextflow Pipeline which can be found on nf-core.

Setup
-----

Warpy mostly utilises ONT provided containers for its steps. However
currently you need to set up some tools and paths yourself (dorado, samtools, minimap2)
which are usually straight forward. 

To do this, open the `src/bpipe.config` file and search for all lines containing "SETME"
and add in appropriate values.

Running
-------

Run warpy like so:

```
bpipe run /path/to/warpy/src/pipeline.groovy -fast5_dir /path/to/fast5/data -sample TEST_SAMPLE -targets target_regions.bed
```

Credits
-------

Warpy is entirely based on the Nextflow pipeline found in the nf-core repository. All credits
belong to the team who created that pipeline.