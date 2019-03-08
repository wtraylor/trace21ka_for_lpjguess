builders['Debias'] = Builder(debias_trace_file_action, prefix='debiased/',
                             src_prefix='rescaled/')


# Rules ################################################################

# TODO: where does cru_mean come from?
env.Crop('grid_template.nc', os.path.join('cru_mean', 'tmp.nc'))

# Calculate the day-to-day standard deviation of daily precipitation sum as
# monthly means.
# TODO: Review aggregate_crujra.sh
env.Command('./scripts/aggregate_crujra.sh',
            target='crujra/monthly_std.nc',
            source=crujra_files)

# TODO: I don’t fully understand the following rule, copied from Makefile.
env.Rescale('monthly_std.nc', os.path.join('crujra', 'monthly_std.nc'))

# TODO: Calculate bias for FSDS?
for trace_var in ['PRECT', 'TREFHT']:
    # The CRU variables corresponding to the TraCE variables.
    cru_vars = yaml.load(open("options.yaml"))["cru_vars"]
    if trace_var not in cru_vars:
        print("Variable '%s' not mapped to a CRU variables." % trace_var)
        sys.exit(1)
    cru_file = "%s.nc" % cru_vars[trace_var]
    trace_file = "modern_trace_%s" % trace_var
    bias_file = "bias_%s.nc" % trace_var
    env.CalcBias(target=bias_file,
                 source=[trace_file, cru_file])
