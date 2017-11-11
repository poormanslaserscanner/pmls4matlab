#include "mex.h"

#include <igl/readOBJ.h>
#include <igl/matlab/prepare_lhs.h>
#include <igl/matlab/parse_rhs.h>
#include <igl/harmonic.h>
#include <Eigen/Core>


void mexFunction(
     int          nlhs,
     mxArray      *plhs[],
     int          nrhs,
     const mxArray *prhs[]
     )
{
  using namespace Eigen;
  /* Check for proper number of arguments */



  MatrixXd Vr;
  MatrixXi Fr;
  MatrixXi b;
  MatrixXd Bval;

  MatrixXd Vl;
  MatrixXi Fl;

  // Read the mesh
  igl::matlab::parse_rhs_index( prhs, Fr );
  igl::matlab::parse_rhs_double( prhs+1, Vr);
  igl::matlab::parse_rhs_index( prhs+2, b );
  igl::matlab::parse_rhs_double( prhs+3, Bval);
  double *order = mxGetPr( prhs[4] );
  int ord = int(*order);
  igl::harmonic(Fr,b,Bval,ord,Vl);
  // Return the matrices to matlab
  switch(nlhs)
  {
    case 1:
      igl::matlab::prepare_lhs_double(Vl,plhs);
    default: break;
  }

  return;
}
