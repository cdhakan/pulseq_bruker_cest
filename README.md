# pulseq_bruker_cest

WASABI/CEST pulse sequence developed for 9.4T. Works on Bruker ParaVision 360 (PV 360.3.x).

Takes a Pulseq CEST `.seq` file and adds its saturation block to a Bruker method. Works with any Pulseq CEST sequence and any Bruker readout method.

## Usage

1. Copy a Bruker readout method (e.g. `EPI`) from `/opt/PV-360.3.[version]/prog/parx/src/`.
2. In MATLAB with [Pulseq](https://github.com/pulseq/pulseq) on the path, run `pulseq_wasabi_bruker`. Pick the method folder, then your `.seq` file.
3. The script writes:
   - `cbd_<method>.ppg`: the readout with the CEST saturation added
   - `mod/cest_wasabi.mod`: the saturation module
   - `mod/cest_pulse00.exc`: the RF pulse shape
   - updated method source files (`BaseLevelRelations.c`, `parsRelations.c`, ...)

## Where to put the files on the scanner

| File | Location |
|---|---|
| Method source code | `/opt/PV-360.3.[version]/prog/curdir/[username]/ParaVision/methods/src/` |
| `cest_wasabi.mod` | `/opt/PV-360.3.[version]/prog/curdir/[username]/ParaVision/exp/lists/pp/` |
| `cest_pulse*.exc` | `/opt/PV-360.3.[version]/prog/curdir/[username]/ParaVision/exp/lists/wave/` |

After copying the source code, delete the original `<method>.ppg` (e.g. `EPI.ppg`) and keep only `cbd_<method>.ppg`.

## Author

Chetan B Dhakan (cdhakan@mgh.harvard.edu)
