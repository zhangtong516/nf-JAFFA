<!--
 * @Author: Zhang Tong
 * @Email: zhangtong516@gmail.com
 * @Company: GIS
 * @Date: 2025-12-04 15:53:09
 * @LastEditors: Zhang Tong
 * @LastEditTime: 2025-12-04 15:59:58
-->
# nf-JAFFA

This repository contains a Nextflow translation of the JAFFA fusion detection pipeline. The pipeline was converted from a `test.sh` orchestration script and split into modular Nextflow processes under the `modules/` directory. Each process is written to run inside an Apptainer / Singularity container (or Docker image converted by Singularity).

**Overview**
- **Purpose**: Detect fusion genes from long-read transcriptome FASTQ using JAFFA-style steps.
- **Entrypoint**: `main.nf` — wires modular processes and launches the workflow.
- **Modules**: Each process lives in `modules/` as its own `.nf` file.

**Repository Layout**
- `main.nf`: Pipeline orchestration and channel wiring.
- `nextflow.config`: Nextflow configuration and default container placeholders.
- `modules/`: Folder with one `.nf` file per pipeline process (e.g. `get_fasta.nf`, `minimap2_transcriptome.nf`, ...).
- `test.sh`: Original shell script used as the conversion source.
- `src/`: Contains standalone C/C++ tools and small utilities (source code) used by the pipeline. Build these locally if you prefer using the host binaries instead of containerized tools.

**Requirements**
- Nextflow (>=21.x recommended)
- Singularity / Apptainer (if using `.sif` images or converting Docker images)
- Java (if running tools outside containers)
- Tools required by JAFFA (`/JAFFA/tools`, `process_transcriptome_align_table`, `reformat`, `extract_seq_from_fasta`, `minimap2`, R scripts, etc.) must be available inside the chosen container(s) or mounted at runtime.

**Standalone tools in `src/`**
- The `src/` directory contains small standalone programs (C/C++) that the original JAFFA pipeline uses. You can either:
  - Build them locally and rely on the host binaries (recommended for development/testing), or
  - Add them to your container image (recommended for reproducible runs).

Build example (Linux/macOS):

```bash
# change into the src directory and build the tools (may require gcc/g++ and make)
cd src
make || \
  for f in *.c*; do gcc -O2 -o "../bin/${f%.*}" "$f"; done
```

After building, ensure the resulting executables are on `PATH` or provide absolute paths to processes in `nextflow.config` or via container images.

**How it works**
- The pipeline looks for input reads matching the `params.reads` pattern (default `"$PWD/*.fastq.gz"`) and runs each sample through the modular steps.
- Processes read their `container` image from `params.container.<name>` as configured in `nextflow.config` or overridden at runtime.

**Running the pipeline**

1) Simple local run (uses `nextflow.config` defaults):

```bash
nextflow run main.nf
```

2) Override input paths and container images on the command line:

```bash
nextflow run main.nf \
  --reads '/data/samples/*_merged.fastq.gz' \
  --transFasta '/ref/transcripts.fasta' \
  --refGenome '/ref/hg38.fa' \
  --refGeneTab '/ref/hg38_genCode22.tab' \
  --container.get_fasta 'docker://quay.io/biocontainers/bbmap:38.96' \
  --container.minimap2 'docker://quay.io/biocontainers/minimap2:2.24'
```

3) Use local Apptainer `.sif` images:

```bash
nextflow run main.nf --container.get_fasta '/path/to/bbmap.sif' --container.minimap2 '/path/to/minimap2.sif'
```

**Notes about containers and tools**
- The original `test.sh` references tools under `/JAFFA/tools` and `/JAFFA/scripts`. These paths must either be present inside the container image you use or you must bind-mount the host `/JAFFA` directory into the container at runtime.
- Recommended approach: build a container image (or Apptainer `.sif`) that contains all JAFFA tools and scripts at `/JAFFA`. Alternatively, point `params.container` to images for individual tools and ensure the required binaries are available in each container.
- `nextflow.config` has placeholder images under `params.container`. Replace them with appropriate Biocontainers or your own images.

**Apptainer cache directory**
- If Nextflow/Apptainer fails with an error about opening images under an `apptainer_cache` path (for example: "no such file or directory"), the cache directory configured in `nextflow.config` may not exist or be writable.
- You can set an explicit cache directory by exporting the `APPTAINER_CACHE` environment variable, for example:

```bash
export APPTAINER_CACHE=/path/to/writable/apptainer_cache
mkdir -p $APPTAINER_CACHE
chmod 700 $APPTAINER_CACHE
```

- The pipeline `nextflow.config` will fall back to `~/.apptainer/cache` if `APPTAINER_CACHE` is not set.

**Parameters**
- `params.reads` — glob for input FASTQ files (default: `"$PWD/*.fastq.gz"`).
- `params.transFasta` — transcriptome FASTA path used by `minimap2_transcriptome`.
- `params.refGenome` — genome FASTA used by `minimap2_genome`.
- `params.refGeneTab` — gene annotation table used by filtering/R steps.
- `params.container` — map of container images per process (set defaults in `nextflow.config` or override on CLI).

**Troubleshooting & tips**
- If a process fails because a binary is not found, the container for that process is missing the tool. Either change the container to a working image or build your own image that includes the tool(s).
- On Windows, Nextflow + Singularity is usually run against a Linux host (or WSL2). Running containers on native Windows is non-trivial; consider running on a Linux machine, cluster, or via WSL2/VM.
- Use `-with-report`, `-with-trace`, and `-with-timeline` Nextflow options to collect runtime metadata for debugging.

**Next steps (suggested)**
- Add a `params.json` containing recommended container image names for reproducibility.
- Build a single `jaffa-tools` container that contains the `/JAFFA` tree and set it as the default for `params.container.jaffa_tools`.
- Add unit tests or a small example dataset + workflow test to verify end-to-end execution.

**Author / Contact**
- Original script and pipeline conversion by Zhang Tong — see the repo history for details.
