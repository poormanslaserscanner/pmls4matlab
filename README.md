# pmls4matlab - Surface reconstruction for 3D cave surveying
![](teaser.gif)

**pmls4matlab** is the proof of concept implementation of the applied surface reconstruction technique in our novel 3D cave surveying method: [Poor Man's Laserscanner (PMLS): a simple method of 3D cave surveying](http://cave3d.org/cmssimple). Our method is based on sparse measurements performed with Beat Heeb's  [DistoX](https://paperless.bheeb.ch) or similar laser distance meter equipped with compass and inclinometer. We can capture very few samples with the Disto compared to point clouds resulting from Terrestrial Laser Scanners (TLS) or [GeoSlam’s ZEB1/ZEB REVO](https://geoslam.com/) handheld laser scanners. In addition, the distribution of the sampled points can be extremely uneven, while caves usually have layouts with lots of features at all scales. To overcome these difficulties a robust and reliable surface reconstruction algorithm had to be developed. The proposed sofware, **pmls4matlab** interpolates the measured points with a watertight surface, which is free of self-intersections. We have found that even complicated geometric layouts can be recovered with good detail from as few as 50 to 150 splay shots per station. More technical details can be found in our [paper](https://poormanslaserscanner.github.io/pmls4matlab/paper.pdf). 

## Installation
### Prerequisites
- A 64-bit version of Microsoft Windows (We provide precompiled binaries of the used 3rd party software only for windows, but these could also be compiled on Linux.)
- Matlab version 2015b or later
- Hardware requirements: 8GB Ram, but 16 or more is recommended for large surveys

### Obtain the packages using git:
Change to a directory in which the PMLS system will be installed. A new directory called "pmls4matlab" will be created in which pmls4matlab will be set up.

1. Download pmls4matlab:
```
git clone https://github.com/poormanslaserscanner/pmls4matlab.git
cd pmls4matlab
```
2. Dependencies are incorporated as submodules, you can obtain them by:
```
git submodule update --init
cd ..
```
3. Alternatively you can also download these files in .zip format from https://github.com/poormanslaserscanner/pmls4matlab/archive/v2.0rc1.zip
4. Download precompiled binaries (bin.zip) from https://github.com/poormanslaserscanner/pmls4matlab/releases
5. Unzip and copy the bin directory into the pmls4matlab directory

### Setup
1. Set PMLS_INSTALL_DIR environmental variable to the pmls installation folder, eg.: "d:\pmls4matlab"
1. Start Matlab
1. Setup the Matlab path by typing in the Matlab command line: 
```matlab
cd(getenv('PMLS_INSTALL_DIR'))
setup
```
## Usage
### Preparing input data
PMLS uses an input file structure based on CSV files. The input structure is to have a main CSV file that references the CSV files of different surveys called survey CSV files. For each survey CSV file a unique survey Id is defined and magnetic declination may be set. The format of these files follow the table structure of the TopoDroid sqlite database (namely the columns of the "shots" table). In the CSV files the '|' character has to be used as delimeter. For some examples see the [testdata](testdata) directory.
#### The main CSV file
The first line is assumed to be a header and will be skipped. The main CSV file has the following fields:
1. Id: Unique identifier of the survey. If the id is `xyz` then the name of the corresponding survey CSV file is `xyz.csv` 
1. Name: Helps the user to identify the survey
1. Day: The date of the survey
1. Team: Name of the surveying team
1. Comment: Anything can be written here
1. Declination: Magnetic declination. Azimuth readings will be corrected with this value.
1. Init_station: Always zero.
#### The survey CSV files
In contrast to the main CSV survey CSV feles do not have a header. The following fields required:
1. Survey id: The id of the survey. (The name of the CSV file without ```.csv```.)
1. Shot id: Unique numeric identifier of the given shot.
1. From station: Identifier of the station the shot was taken from. Each station must have a unique case sensitive name.
1. To station: For splay shots it is left empty. For leg shots it is the identifier of the end point of the shot.  
1. Distance reading in meters.
1. Azimuth in degrees: Norts is zero, east is 90 degrees.
1. Elevation in degrees between -90 and +90.

It is always assumed that there is a station with identifier ```0``` and cartesian coordinates ```[0,0,0]```. The shots whith both ```From station``` and ```To station``` identifiers compose the network of the stations. This network cannot be disconnected and so the cartesian coordinates of all the stations can be derived from the shots and from the location of station ```0```. There can be multiple shots with the same from and to stations. In that case we will take the average of the readings. The network may also contain loops, in which case we shall optimally distribute the errors on the measurements.

A shot without a ```To station``` is called a splay shot and is assumed to be a point on the cave's wall. Stations are not necesarily on the wall, shots can also be made from a tripod. If a station is on the wall, it is recommended to take a so called ```zeroshot```. A ```zeroshot``` is a shot without a distance but with normal direction to the wall. ```zeroshots``` have identical ```From station``` and ```To station``` identifiers in the CSV. Only stations with zeroshots will be assumed to be on the wall.
### Reading in the input
```matlab
H = plgetinput(csvname,n);
```
Will read the survey data from the ```csvname``` main CSV file and the refered survey CSV files. The stations with fewer splay shots than ```n``` will be ignored (they will be used in determining the location of the stations, but they will not be used for surface reconstruction). A typical value of ```n``` is between 5 and 10. 
```matlab
H = plgetinput(csvname,n,poligonname);
```
`poligonname` is the name of a .cave file. This file format is used by the poligon software, which is the most widely used cave surveying program in Hungary. In that format the function will first read in the stations defined in the `poligonname` file.
The output ```H``` is a special struct that will be used in the further steps. We will call this internal data structure ```plstruct```
### Reconstruct surface
```matlab
M = pmlsrecon(H, vox1, vox2, ...);
```
Outlier measurements will be automatically removed and the surface reconstruction will be done based on the remaining shots. The reconstruction is performed in several steps starting with a coarser step followed with steps trying to recover finer details. The number of the ```vox1, vox2,...``` parameters determines the number of steps and the values give the level of detail in voxel size for the corresponding steps. Voxel sizes should be given in centimeters. In the case of the [test data sets](testdata) for [Speizi](testdata/speizi) and [Ferenc](testdata/ferenc) 
```matlab
M = pmlsrecon(H, 4, 3);
```
For [Legeny](testdata/legeny):
```matlab
M = pmlsrecon(H, 6, 5);
```
is a good choice. Note that run times will be long. It can take several hours. Temporary files will be created in the subdirectory ```pltmp```. The output M will be a plstruct with the resulting mesh and the input data without the outliers.
### Save and load plstruct
```matlab
plsave(filename, S);
```
Saves plstruct `S` to `filename`. `filename` will be a `.mat` file.
```matlab
plload(filename);
```
Loads plstruct from `filename` to the current matlab workspace with the name it was saved.
### Export the result
The resulted mesh can be exported into Stanford Polygon format.
```matlab
plexport(filename, M);
```
The content of the plstruct `M` will be exported. The mesh will be saved in `filename.ply`. The input survey will exported to `filename.dxf`. 

## Contact
PMLS is a group endeavor of a few cavers from Hungary. You can [contact us](mailto:pmls-hu@cave3d.org) if you have questions or comments.
If you're using our work, please drop us a note to justify spending time maintaining this.

#### The members of our team:
- Attila G&#XE1;ti
- Zsombor Fekete
- Nikolett Reh&#XE1;ny
- P&#XE9;ter S&#X171;r&#X171;
- Bal&#XE1;zs Holl

#### Contributors:
- Imre Balogh
- Kamilla Borzs&#XE1;k
- Edit Harangozó
- Beat Heeb
- Richard Kov&#XE1;cs
- Fanni Matuszka
- József Mészáros
- Magdolna Novák
- Andr&#XE1;s Rántó
- Eszter Szabó
- Réka Veres


## Copyright
Copyright 2014-2017  [Attila G&#XE1;ti](mailto:poormanslaserscanner@gmail.com).
If you publish a work, in which you have used PMLS you could cite:

Attila G&#XE1;ti, Nikolett Reh&#XE1;ny, Bal&#XE1;zs Holl, Zsombor Fekete and P&#XE9;ter S&#X171;r&#X171;: 
"The Poor Man's Laser Scanner: a Simple Method of 3D Cave Surveying"
[CREG-Journal 96](http://bcra.org.uk/pub/cregj/index.html?j=96), pp. 8—14, 2016

## License
pmls4matlab is licensed under the [GNU GENERAL PUBLIC LICENSE version 3](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Acknowledgement
Our software is heavily based on other's work:
1. [Alec Jacobson](https://github.com/alecjacobson), [Daniele Panozzo](https://github.com/danielepanozzo), et al.: [libigl](https://github.com/libigl/libigl) - A simple C++ geometry processing library
1. [Qianqian Fang](https://github.com/fangq): [Iso2mesh](http://iso2mesh.sourceforge.net/cgi-bin/index.cgi): an image-based 3D surface and volumetric mesh generator (Fang 2009)
1. [Jonathan Shewchuk](https://people.eecs.berkeley.edu/~jrs): [Triangle](https://www.cs.cmu.edu/~quake/triangle.html): A Two-Dimensional Quality Mesh Generator and Delaunay Triangulator
1. [Hang Si](http://www.wias-berlin.de/~si): [Tetgen](http://wias-berlin.de/software/index.jsp?id=TetGen&lang=1): A Quality Tetrahedral Mesh Generator and a 3D Delaunay Triangulator (Hang Si 2015)
1. [Marco Attene](http://pers.ge.imati.cnr.it/attene/PersonalPage/attene.html): [MeshFix](https://github.com/MarcoAttene/MeshFix-V2.1): A lightweight approach to repairing digitized polygon meshes (Attene 2010)
1. [Alec Jacobson](https://github.com/alecjacobson): [gptoolbox](https://github.com/alecjacobson/gptoolbox): Matlab toolbox for Geometry Processing
1. [Pierre Terdiman](http://codercorner.com/Pierre.htm): [OPCODE](http://www.codercorner.com/Opcode.htm): Optimized Collision Detection
1. [Vipin Vijayan](https://uk.mathworks.com/matlabcentral/profile/authors/3188385-vipin-vijayan): [opcodemesh](https://uk.mathworks.com/matlabcentral/fileexchange/41504-ray-casting-for-deformable-triangular-3d-meshes): Ray casting for deformable triangular 3D meshes
1. [Jeroen Baert](https://people.cs.kuleuven.be/~jeroen.baert), PhD student at [Katholieke Universiteit te Leuven](https://www.kuleuven.be/kuleuven): [cuda_voxeizer](https://github.com/Forceflow/cuda_voxelizer) Experimental CUDA voxelizer, to convert polygon meshes to annotated voxel grids
1. [Blender foundation](https://www.blender.org/foundation): Blender: Open Source 3D creation. Free to use for any purpose, forever.
1. [Beat Heeb](https://bheeb.ch): [DistoX](https://paperless.bheeb.ch): An All-in-One Electronic Cave Surveying Device (Heeb 2009, 2014)
1. [Marco Corvi](https://github.com/marcocorvi): [topodroid](https://play.google.com/store/apps/details?id=com.topodroid.DistoX&hl=en): Cave surveying on Android


## References
Fang, Qianqian, and David A Boas. 2009. “Tetrahedral Mesh Generation
from Volumetric Binary and Grayscale Images.” In *2009 Ieee
International Symposium on Biomedical Imaging: From Nano to Macro*,
1142–5. IEEE. <http://iso2mesh.sourceforge.net/cgi-bin/index.cgi>.

Hang Si. 2015. ”TetGen, a Delaunay-Based Quality Tetrahedral Mesh Generator”. *ACM Trans. on Mathematical Software*. 41 (2), Article 11 (February 2015), 36 pages. <http://doi.acm.org/10.1145/2629697>.

M. Attene. 2010. ”A lightweight approach to repairing digitized polygon meshes”. The Visual Computer, (c) Springer. DOI: 10.1007/s00371-010-0416-3

Heeb, Beat. 2009. “An All-in-One Electronic Cave Surveying Device.”
*CREG-Journal*, no. 72. BCRA:8–10.
<http://bcra.org.uk/pub/cregj/index.html?j=72>.

———. 2014. “The Next Generation of the DistoX Cave Surveying
Instrument.” *CREG-Journal*, no. 88. BCRA:5–8.
<http://bcra.org.uk/pub/cregj/index.html?j=88>.
