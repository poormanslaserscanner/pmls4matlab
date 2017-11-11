path_to_libigl=[fileparts(mfilename('fullpath')), '/../libigl'];
MEXOPTS={'-v','-largeArrayDims','-DMEX'};
MSSE42='CXXFLAGS=$CXXFLAGS -msse4.2';
STDCPP11='CXXFLAGS=$CXXFLAGS -std=c++11';
OPENMP= 'COMPFLAGS=$COMPFLAGS /openmp';
OPENMPL = 'LINKFLAGS=$LINKFLAGS /nodefaultlib:vcomp';
pmls_dir = getenv('PMLS_INSTALL_DIR');
EIGEN_INC=['-I', pmls_dir, '/Eigen/include/eigen3'];

LIBIGL_INC=sprintf('-I%s/include',path_to_libigl);
LIBIGL_FLAGS=strsplit('-DIGL_NO_CORK -DEIGEN_CHOLMOD_SUPPORT -DEIGEN_UMFPACK_SUPPORT -DEIGEN_METIS_SUPPORT -DEIGEN_SPQR_SUPPORT');
  LIBIGL_LIB={'-DIGL_SKIP'};
  LIBIGL_LIBMATLAB='-DIGL_SKIP';
  LIBIGL_LIBEMBREE='-DIGL_SKIP';
  LIBIGL_LIBCGAL='-DIGL_SKIP';
  LIBIGL_LIBCORK='-DIGL_SKIP';
LIBIGL_BASE={LIBIGL_INC,LIBIGL_FLAGS{:},LIBIGL_LIB{:},LIBIGL_LIBMATLAB};
mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, OPENMP, OPENMPL, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  'deformunilap.cpp', 'libiomp5md.lib');