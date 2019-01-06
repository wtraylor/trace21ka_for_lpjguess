import sys
import os

# The following functions are from python files in the subdirectory
# "site_scons/".
from aggregate_modern_trace import aggregate_modern_trace
from calculate_bias import calculate_bias


### User Options #######################################################

# List all directories where the original climate files are stored. The
# directories (“repositories”) will be searched in the order you declare them
# in the `Repository()` function.
# This way we don’t need to specify full paths, but just the file name that is
# expected to reside in one of the repository directories.
Repository('$HOME/data/trace/',
           '$HOME/data/crujra/',
           '/mnt/firell/data/trace/',
           '/mnt/firell/data/crujra/')

# Directory for final output files. Can be an absolute or relative path.
out_dir = 'output'

# Directory to save intermediary files. Can be an absolute or relative path.
heap = 'heap'


### Initialize Environment #############################################

# Here, we just create the environment. The builders are appended later.
env = Environment()

# The VariantDir() function specifies where to save the output files. The `src_dir` should be set to '.' because input files are taken from a variety of directories, which are given by the Repository() call.
VariantDir(variant_dir=out_dir, src_dir='.')
VariantDir(variant_dir=heap, src_dir='.')


### Builders ###########################################################

builders = env['BUILDERS']

# Unzip a file with `gunzip` and show the progress with `pv` (“pipe viewer”).
# Specifying the source file suffix ".gz" allows to only pass the target. SCons
# will automatically find the source file by appending the suffix.
builders['Unzip'] = Builder("""pv $SOURCE | gunzip --verbose --decompress
                            --synchronous --stdout > $TARGET""",
                            src_suffix=".gz")

# Crop a file to the extent specified in "options.yaml".
# The prefix is prepended to the target’s file name (the basename of the file).
# TODO: Use Miniconda Python.
builders['Crop'] = Builder("python scripts/crop_file.py $SOURCE $TARGET",
                           prefix='cropped/', suffix='.nc')

# Regrid the source file to a common resolution.
# TODO: Make resolution customizeable.
# TODO: Use Miniconda Python.
builders['Rescale'] = Builder("python scripts/rescale.py $SOURCE $TARGET",
                              prefix='rescaled/', suffix='.nc')

builders['AggModernTrace'] = Builder(aggregate_modern_trace)

builders['ConcatCruFiles'] = Builder('ncrcat $SOURCES $TARGET',
                                     prefix='cru_cat/', suffix='.nc')

# Calculate the monthly averages over all years so that we have only 12 values
# in each file.
builders['AggCru'] = Builder('cdo ymonmean $SOURCE $TARGET',
                             prefix='cru_mean/', suffix='.nc',
                             src_prefix='cru_cat/', src_suffix='.nc')

builders['CalcBias'] = Builder(calculate_bias,
                               src_prefix='rescaled/')

### Files ##############################################################

def get_original_cru_file_names():
    """ Create list of original CRU files between 1900 and 1990. """
    years = [(y+1, y+10) for y in range(1920, 1971, 10)]
    vars = ['pre', 'wet', 'tmp']
    # Combine every time segment (decade) with each every variable.
    years_vars = tuple((y1, y2, v) for (y1, y2) in years for v in vars)
    return ["cru_ts4.01.%d.%d.%s.dat.nc" % (y1, y2, v) for (y1, y2, v) in
            years_vars)

# List of original CRU files from 1990 to 1990.
cru_files = get_original_cru_file_names()

# List of CRU-JRA files from 1958 to 1990.
crujra_files = ["crujra.V1.1.5d.pre.%d.365d.noc.nc" % y for y in
                range(1958,1991)]


### Rules ##############################################################

# The calls to Scons builder functions are comparable to Makefile rules. The
# first argument is the target and the second is the source (like prerequisites
# in Make). The builder function itself defines the commands to be executed.
# Some builder functions automatically define the source(s), either based on
# suffix patterns or emitter functions.
# TODO: Explain the production chain within each for loop.

# TODO: Set the files that are ready for LPJ-GUESS in `out_dir` as default
# targets.
# Default()

for f in crujra_files: env.Unzip(f)
for f in cru_files: env.Unzip(f)

for f in trace_files:
    cropped = env.Crop(f)
    # TODO: split files
    env.Rescale(f, cropped)
    # TODO: Continue processing the cropped file

# TODO: where does cru_mean come from?
env.Crop(os.path.join(cropped_dir, 'grid_template.nc'),
         os.path.join(cru_mean, 'tmp.nc'))

for f in cru_mean_files:
    env.Rescale(f, os.path.join(cru_mean, f))

# TODO: I don’t fully understand the following rule, copied from Makefile.
env.Rescale('monthly_std.nc', os.path.join(crujra, 'monthly_std.nc'))

for var in ['FSDS', 'PRECC', 'PRECL', 'TREFHT']:
    source = "trace.36.400BP-1990CE.cam2.h0.%s.2160101-2204012.nc" % var
    env.AggModernTrace('modern_trace_%s.nc' % var, source)

# TODO: Use miniconda environment
env.Command('modern_trace_PRECT.nc',
            ['modern_trace_PRECC.nc', 'modern_trace_PRECL.nc'],
            './scripts/add_PRECC_PRECL.sh $SOURCES $TARGET')

for var in ['FSDS', 'PRECT', 'TREFHT']:
    env.Rescale('modern_trace_%s.nc' % var, 'modern_trace_%s.nc' % var)

# Calculate the day-to-day standard deviation of daily precipitation sum as
# monthly means.
# TODO: Review aggregate_crujra.sh
env.Command('./scripts/aggregate_crujra.sh',
            target='crujra/monthly_std.nc',
            source=crujra_files)

for var in ['pre', 'tmp', 'wet']:
    # Filter list of all CRU files to file names containing `var`.
    files_with_var = [f for f in cru_files if var in f]
    env.ConcatCruFiles(target='%s.nc' % var,
                       source=files_with_var)

for trace_var in ['FSDS', 'PRECT', 'TREFHT']:
    # The CRU variables corresponding to the TraCE variables.
    cru_vars = yaml.load(open("options.yaml"))["cru_vars"]
    if not trace_var in cru_vars:
        print("Variable '%s' not mapped to a CRU variables." % trace_var)
        sys.exit(1)
    cru_file = "heap/cru_regrid/%s.nc" % cru_vars[trace_var]
    trace_file = "modern_trace_%s" % trace_var
    bias_file = "bias_%s.nc" % trace_var
    env.CalcBias(target=bias_file,
                 source=[trace_file, cru_file])
