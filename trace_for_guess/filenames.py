def get_cru_filenames():
    """Create list of original CRU files between 1900 and 1990."""
    years = [(y+1, y+10) for y in range(1920, 1971, 10)]
    vars = ['pre', 'wet', 'tmp']
    # Combine every time segment (decade) with every variable.
    years_vars = tuple((y1, y2, v) for (y1, y2) in years for v in vars)
    return ["cru_ts4.01.%d.%d.%s.dat.nc" % (y1, y2, v) for (y1, y2, v) in
            years_vars]

def get_crujra_filenames():
    """Create a list of all relevant original CRU-JRA filenames."""
    # TODO
    return list()


def get_modern_trace_filename(var: str):
    """Compose the name for the most recent TraCE-21ka NetCDF file."""
    return f'trace.36.400BP-1990CE.cam2.h0.{var}.2160101-2204012.nc'


def get_trace_filenames(variables: list):
    """Create a list of all original TraCE-21ka NetCDF filenames.

    Args:
        variables: List with the CAM variable names.

    Returns:
        A list of strings with the TraCE filenames.
    """
    l = list()
    for v in variables:
        l += ['trace.01.22000-20001BP.cam2.h0.%s.0000101-0200012.nc' % v,
              'trace.02.20000-19001BP.cam2.h0.%s.0200101-0300012.nc' % v,
              'trace.03.19000-18501BP.cam2.h0.%s.0300101-0350012.nc' % v,
              'trace.04.18500-18401BP.cam2.h0.%s.0350101-0360012.nc' % v,
              'trace.05.18400-17501BP.cam2.h0.%s.0360101-0450012.nc' % v,
              'trace.06.17500-17001BP.cam2.h0.%s.0450101-0500012.nc' % v,
              'trace.07.17000-16001BP.cam2.h0.%s.0500101-0600012.nc' % v,
              'trace.08.16000-15001BP.cam2.h0.%s.0600101-0700012.nc' % v,
              'trace.09.15000-14901BP.cam2.h0.%s.0700101-0710012.nc' % v,
              'trace.10.14900-14351BP.cam2.h0.%s.0710101-0765012.nc' % v,
              'trace.11.14350-13871BP.cam2.h0.%s.0765101-0813012.nc' % v,
              'trace.12.13870-13101BP.cam2.h0.%s.0813101-0890012.nc' % v,
              'trace.13.13100-12901BP.cam2.h0.%s.0890101-0910012.nc' % v,
              'trace.14.12900-12501BP.cam2.h0.%s.0910101-0950012.nc' % v,
              'trace.15.12500-12001BP.cam2.h0.%s.0950101-1000012.nc' % v,
              'trace.16.12000-11701BP.cam2.h0.%s.1000101-1030012.nc' % v,
              'trace.17.11700-11301BP.cam2.h0.%s.1030101-1070012.nc' % v,
              'trace.18.11300-10801BP.cam2.h0.%s.1070101-1120012.nc' % v,
              'trace.19.10800-10201BP.cam2.h0.%s.1120101-1180012.nc' % v,
              'trace.20.10200-09701BP.cam2.h0.%s.1180101-1230012.nc' % v,
              'trace.21.09700-09201BP.cam2.h0.%s.1230101-1280012.nc' % v,
              'trace.22.09200-08701BP.cam2.h0.%s.1280101-1330012.nc' % v,
              'trace.23.08700-08501BP.cam2.h0.%s.1330101-1350012.nc' % v,
              'trace.24.08500-08001BP.cam2.h0.%s.1350101-1400012.nc' % v,
              'trace.25.08000-07601BP.cam2.h0.%s.1400101-1440012.nc' % v,
              'trace.26.07600-07201BP.cam2.h0.%s.1440101-1480012.nc' % v,
              'trace.27.07200-06701BP.cam2.h0.%s.1480101-1530012.nc' % v,
              'trace.28.06700-06201BP.cam2.h0.%s.1530101-1580012.nc' % v,
              'trace.29.06200-05701BP.cam2.h0.%s.1580101-1630012.nc' % v,
              'trace.30.05700-05001BP.cam2.h0.%s.1630101-1700012.nc' % v,
              'trace.31.05000-04001BP.cam2.h0.%s.1700101-1800012.nc' % v,
              'trace.32.04000-03201BP.cam2.h0.%s.1800101-1880012.nc' % v,
              'trace.33.03200-02401BP.cam2.h0.%s.1880101-1960012.nc' % v,
              'trace.34.02400-01401BP.cam2.h0.%s.1960101-2060012.nc' % v,
              'trace.35.01400-00401BP.cam2.h0.%s.2060101-2160012.nc' % v,
              'trace.36.400BP-1990CE.cam2.h0.%s.2160101-2204012.nc' % v]
    return l

