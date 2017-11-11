%mex  -v CXXFLAGS="\$CXXFLAGS -std=c++0x" deform.cpp
%-Ic:/dev/libigl-master/include -Ic:/dev/eigen3/install/include/eigen3
mex  -v -DEIGEN_CHOLMOD_SUPPORT -DEIGEN_UMFPACK_SUPPORT -DEIGEN_METIS_SUPPORT -DEIGEN_SPQR_SUPPORT deformunilap.cpp -Id:/pmlsgit/git_pmls4matlab/pmls4matlab/libigl4pmls/libigl/include -Id:/pmlsgit/git_iso2mesh_bin/install/Eigen/include/eigen3

