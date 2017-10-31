path_to_libigl=[fileparts(mfilename('fullpath')), '/../libigl'];
MEXOPTS={'-v','-largeArrayDims','-DMEX'};
MSSE42='CXXFLAGS=$CXXFLAGS -msse4.2';
STDCPP11='CXXFLAGS=$CXXFLAGS -std=c++11';
EIGEN_INC='-Id:/pmlsgit/git_iso2mesh_bin/install/Eigen/include/eigen3';

% See libigl documentation. In short, Libigl is a header-only library by
% default: no compilation needed (like Eigen). There's an advanced **option**
% to precompile libigl as a static library. This cuts down on compilation time.
% It is optional and more difficult to set up. Set this to true only if you
% know what you're doing.
use_libigl_static_library = false;
LIBIGL_INC=sprintf('-I%s/include',path_to_libigl);
  % `mex` has a silly requirement that arguments be non-empty, hence the NOOP
  % defines
  LIBIGL_FLAGS=strsplit('-DIGL_NO_CORK -DEIGEN_CHOLMOD_SUPPORT -DEIGEN_UMFPACK_SUPPORT -DEIGEN_METIS_SUPPORT -DEIGEN_SPQR_SUPPORT');
  LIBIGL_LIB={'-DIGL_SKIP'};
  LIBIGL_LIBMATLAB='-DIGL_SKIP';
  LIBIGL_LIBEMBREE='-DIGL_SKIP';
  LIBIGL_LIBCGAL='-DIGL_SKIP';
  LIBIGL_LIBCORK='-DIGL_SKIP';
LIBIGL_BASE={LIBIGL_INC,LIBIGL_FLAGS{:},LIBIGL_LIB{:},LIBIGL_LIBMATLAB};



%CORK=[path_to_libigl '/external/cork'];
CORK_INC='';%sprintf('-I%s/src',CORK);
CORK_LIB='';%strsplit(sprintf('-L%s/lib -lcork',CORK));


CGAL_INC=strsplit('-Id:/pmlsgit/git_iso2mesh_bin/install/CGAL/include -Id:/pmlsgit/git_iso2mesh_bin/iso2mesh_bin/win/mpir/dll/x64/Release -Id:/pmlsgit/git_iso2mesh_bin/iso2mesh_bin/win/mpfr/dll/x64/Release');
CGAL_LIB=strsplit('-Ld:/pmlsgit/git_iso2mesh_bin/install/CGAL/lib -Ld:/pmlsgit/git_iso2mesh_bin/iso2mesh_bin/win/mpir/dll/x64/Release -Ld:/pmlsgit/git_iso2mesh_bin/iso2mesh_bin/win/mpfr/dll/x64/Release -llibCGAL-vc140-mt-4.11-I-900 -llibCGAL_Core-vc140-mt-4.11-I-900 -lmpir -lmpfr');
%CGAL_LIB=strsplit('-Lc:/dev/CGAL-4.7/build/install/lib -lCGAL-vc120-mt-4.7 -lCGAL_Core-vc120-mt-4.7 -lgmp -lmpfr');
CGAL_FLAGS='CXXFLAGS=\$CXXFLAGS -frounding-math';

BOOST='/opt/local/';
BOOST_INC='-Id:/pmlsgit/git_iso2mesh_bin/install/boost/include/boost-1_65_1';
BOOST_LIB=strsplit('-Ld:/pmlsgit/git_iso2mesh_bin/install/boost/lib -llibboost_thread-vc141-mt-1_65_1 -llibboost_system-vc141-mt-1_65_1');


mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  CGAL_INC{:},CGAL_LIB{:},CGAL_FLAGS, ...
  LIBIGL_LIBCGAL, LIBIGL_LIBCORK, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'mesh_boolean.cpp');
% mex( ...
%   MEXOPTS{:}, MSSE42, STDCPP11, ...
%   LIBIGL_BASE{:},EIGEN_INC, ...
%   CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
%   LIBIGL_LIBCGAL, LIBIGL_LIBCORK, ...
%   CORK_INC,CORK_LIB{:}, ...
%   BOOST_INC,BOOST_LIB{:}, ...
%   'mesh_boolean.cpp');

