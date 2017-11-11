bl_info = {
    "name": "PMLS",
    "description": "Surface reconstruction from DistoX data.",
    "author": "Attila Gati, et al.",
    "version": (0, 82),
    "blender": (2, 65, 0),
    "location": "View3D",
    "warning": "", # used for warning icon and text in addons panel
    "support": "COMMUNITY",
    "category": "3D View"
    }




import bpy
import bmesh
from bpy.app.handlers import persistent
import os
import io
import collections

import importlib.util
import sys

name = 'pmlslib'

spec = importlib.util.find_spec(name)
pmlslib_module = None
if spec is not None:
    # If you chose to perform the actual import ...
    pmlslib_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(pmlslib_module)
    # Adding the module to sys.modules is optional.
    sys.modules[name] = pmlslib_module
    pmlslib = pmlslib_module

import matlab

if importlib.util.find_spec('engine', 'matlab') is not None:
    import matlab.engine

class PmlsObjectType(type):
    def __init__(cls, *args, **kwargs):
#        print(cls)
#        print(cls.pmls_type)
        if cls.pmls_type:
            cls.PmlsObjectDictionary[cls.pmls_type] = cls                    
        return super().__init__(*args, **kwargs)
    
class PmlsObjectBase( metaclass=PmlsObjectType ):
    PmlsObjectDictionary = {}
    pmls_type = None

    @staticmethod
    def type_str( bpyobj ):
        if ('pmls_type' in bpyobj.keys()):
            return bpyobj['pmls_type']
        else:
            return None
        
    @classmethod
    def pmls_type_check( cls, bpyobj ):
        typestr = cls.type_str( bpyobj ) 
        return typestr and cls.pmls_type and typestr == cls.pmls_type
    
    @classmethod
    def pmls_get_type( cls, bpyobj ):
        typestr = cls.type_str( bpyobj ) 
        if typestr and typestr in cls.PmlsObjectDictionary:
            return cls.PmlsObjectDictionary[typestr]
        return None
        
class PmlsObject(PmlsObjectBase):
    @staticmethod
    def tr_default( obj ):
        if obj is None:
            return bpy.context.active_object
        else:
            return obj
    
    def __bool__(self):
#        print( "Object::bool called" )
        return bool( self.object )
    
    def clear(self, objdata_too=True):
        bm = self.get_bmesh()
        bm.clear()
        bmesh.update_edit_mesh(self.object.data)
        if objdata_too:
            self._clear_objdata()
        
    
    def NullInit(self):
        self.object = None
        
    def delete_object(self):
        obj = self.object
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action='DESELECT')
        obj.hide = False
        obj.select = True
        bpy.ops.object.delete()
        self.NullInit()
       
        
    def update_from_matlab(self, mobj):
        t1 = type(self)
        t2 = PmlsObjectBase.pmls_get_type(mobj)
        b = issubclass(t2,t1)
        self.clear(not b)
        obj = self.object
        self.NullInit()
        obj["pmls_type"] = PmlsObjectBase.type_str(mobj)
        pmls_obj = PmlsObject(obj)
        pmls_obj._init_from_matlab(mobj)
        return pmls_obj        
        
    def __init__( self, bpyobj = None ):
#        print( "Object::__init__ called" )
        bpyobj = PmlsObject.tr_default( bpyobj )
        if (type(bpyobj) is bpy.types.Object) and (bpyobj.type == "MESH"):
            self.object = bpyobj
        else:
            self._init_from_matlab(bpyobj)
            self.object["pmls_type"] = self.pmls_type
            
        
    def __new__(cls, bpyobj = None):
#        print( 'Obj: ' + str(cls) )
        bpyobj = cls.tr_default(bpyobj)
        if cls.pmls_type_check( bpyobj ):
            pobj = PmlsObjectBase.__new__( cls )
            pobj.NullInit()
            return pobj
        ncls = cls.pmls_get_type( bpyobj )
        if ncls is not None:
            return PmlsObject.__new__( ncls, bpyobj )

    @classmethod
    def add_mesh(cls, vt, edges, faces, obj):
        selvt = vt.get("selvt")
        return PmlsEngine.add_mesh( vt["pmls_name"], vt["vt"], edges, faces, obj, selvt )
    
    @staticmethod
    def get_selected_objects():
        return [PmlsObject(o) for o in bpy.context.selected_objects 
                if pmls_is_pmlsobj(o) and (pmls_is_deform_mesh(o) or not(o.parent and pmls_is_deform_mesh(o.parent)))]
    
    
    def set_active(self):
        obj = self.object
        aobj = bpy.context.active_object
        if aobj is None or obj.name != aobj.name:
            if bpy.ops.object.mode_set.poll():
                bpy.ops.object.mode_set()
            bpy.ops.object.select_all(action='DESELECT')
            obj.hide = False
            obj.select = True
            bpy.context.scene.objects.active = obj
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action='DESELECT')
        obj.hide = False
        obj.select = True
        
        
    def set_object_mode(self):
        self.set_active()
        bpy.ops.object.mode_set(mode='OBJECT')

    def set_edit_mode(self):
        self.set_active()
        bpy.ops.object.mode_set(mode='EDIT')
        
    def is_parent_of(self, child):
        if not isinstance(child, PmlsObject):
            return False
        return child.object.parent and child.object.parent.name == self.object.name
            
    def parent_clear(self):
        if self.object.parent:
            self.object.hide = False
            self.object.select = True
            bpy.context.scene.objects.active = self.object
            bpy.ops.object.duplicate(linked=True)
            bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
            self.object.hide = True
            self.object.select = False
            obj = PmlsObject(bpy.context.scene.objects.active)
            obj.object.select = False
            return obj
        return self         
            
    
    def get_bmesh(self):
        obj = self.object
#         aobj = bpy.context.active_object
#         if aobj is None or obj.name != aobj.name:
#             if bpy.ops.object.mode_set.poll():
#                 bpy.ops.object.mode_set()
#             bpy.ops.object.select_all(action='DESELECT')
#             obj.hide = False
#             obj.select = True
#             bpy.context.scene.objects.active = obj
        self.set_active()
        bpy.ops.object.mode_set(mode='EDIT')
        me = obj.data
        return bmesh.from_edit_mesh( me )
    
    @staticmethod
    def _mvt_to_py(mobj):
        mvt = mobj["vt"]
        vt = [];
        vt.extend([(p[0], p[1], p[2]) for p in mvt])
        selvt = mobj.get("selvt")
        if selvt:
            if not isinstance(selvt, collections.Iterable):
                selvt = [[selvt]]
            return {"vt" : vt, "pmls_name" : mobj["pmls_name"], "selvt" : [v[0] for v in selvt]}
        else:
            return {"vt" : vt, "pmls_name" : mobj["pmls_name"]}

    @staticmethod
    def _medges_to_py(mobj):
        medges = mobj["edges"]
        edges = []
        edges.extend([(e[0], e[1]) for e in medges])
        return edges

    @staticmethod
    def _mfaces_to_py(mobj):
        mfaces = mobj["tris"]
        faces = []
        faces.extend([(f[0], f[1], f[2]) for f in mfaces])
        return faces

    @classmethod
    def is_hedgehog(cls):
        return False

    @classmethod
    def is_mesh(cls):
        return False
        
class PmlsMesh(PmlsObject):
    pmls_type = "mesh"

    def _init_from_matlab(self, mobj):
        ob = self.add_mesh( self._mvt_to_py(mobj), [], self._mfaces_to_py(mobj), self.object );
        self.object = ob

    def _to_matlab(self, bm):
        S = {}
        S["verts"] = matlab.double([list(v.co) for v in bm.verts])
        S["tris"] = matlab.int32([[v.index for v in f.verts] for f in bm.faces])
        return S
    
    def _to_matlab_skeleton(self):
        S = {};
        S["verts"] = matlab.double(size=(1,0))
        S["tris"] = matlab.int32(size=(1,0))
        S["pmls_type"] = self.pmls_type
        S["pmls_name"] = self.object.name
        return S
        
            
    def to_matlab(self):
        self.set_edit_mode()
        bpy.ops.mesh.select_all(action="DESELECT")
        bpy.ops.mesh.select_face_by_sides(number=3, type='GREATER', extend=False)
        bpy.ops.mesh.quads_convert_to_tris()
        bpy.ops.mesh.select_all(action="DESELECT")
        self.set_object_mode()
        vertices = self.object.data.vertices
        faces = self.object.data.polygons
        S = {};
        n = len(vertices)
        mvt = matlab.double(size=(1,3*n))
        vertices.foreach_get('co', mvt[0])
        mvt.reshape((3,n))
        S["verts"] = mvt
        n = len(faces)
        mtris = matlab.int32(size=(1,3*n))
        faces.foreach_get('vertices', mtris[0])
        mtris.reshape((3,n))
        S["tris"] = mtris
        S["pmls_type"] = self.pmls_type
        S["pmls_name"] = self.object.name
        return S
#         return self._to_matlab(bm)            
        
    def advance(self, hedg, anchors):
        obj = self.object
        obj["pmls_type"] = PmlsDeformMesh.pmls_type
        obj = PmlsObject(obj)
        if obj:
            obj.set_children(hedg, anchors)
        return obj

    @classmethod
    def is_mesh(cls):
        return True
    
    @classmethod
    def _get_loop(cls, vs):
        loop=[]
        if not vs:
            return loop
        v1 = vs[0]
        es = [e for e in v1.link_edges if e.select]
        if not es:
            raise Exception('Bad selecting!')
        v2 = es[0].other_vert(v1)
        loop = [v1,v2]
        vstart = v1;
        while True:
            es = [e for e in v2.link_edges if e.select]
            if not es:
                raise Exception('Bad selecting!')
            vs = [e.other_vert(v2) for e in es if e.other_vert(v2) not in loop ]
            if not vs:
                vs = [e.other_vert(v2) for e in es if e.other_vert(v2) in loop and e.other_vert(v2) != v1]
                if len(vs) != 1 or vs[0] != vstart:
                    raise Exception('Bad selecting!')
                return loop
            if len(vs) > 1: 
                raise Exception('Bad selecting!')
            v1 = v2
            v2 = vs[0]
            loop.append(v2)

    
    def get_selected_loops(self):
        bm = self.get_bmesh()
        vs = [v for v in bm.verts if v.select]
        if not vs:
            raise Exception('Bad selecting!')
        loops = []
        while vs:
            loop = self._get_loop(vs)
            vs = list(set(vs) - set(loop))
            loops.append(matlab.int32([v.index + 1 for v in loop]))
        return loops        
        
class PmlsDeformMesh(PmlsMesh):
    pmls_type = "deform_mesh"
    
    def set_children(self, hedgehog, anchor):
        H = self.hedgehog()
        if hedgehog and H and H.object.name != hedgehog.object.name:
                H.delete_object()
        H = self.anchor()
        if anchor and H and H.object.name != anchor.object.name:
                H.delete_object()
        obj = self.object
        aobj = bpy.context.active_object
        if aobj is None or obj.name != aobj.name:
            if bpy.ops.object.mode_set.poll():
                bpy.ops.object.mode_set()
            bpy.ops.object.select_all(action='DESELECT')
            bpy.context.scene.objects.active = obj
            obj.hide = False
            obj.select = True
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action='DESELECT')
        if hedgehog and not self.is_parent_of(hedgehog):
            hedgehog = hedgehog.parent_clear()
        if anchor and not self.is_parent_of(anchor):
            anchor = anchor.parent_clear()
#         if hedgehog and hedgehog.object.parent:
#             hedgehog.object.hide = False
#             hedgehog.object.select = True
#             bpy.context.scene.objects.active = hedgehog.object
#             bpy.ops.object.duplicate(linked=True)
#             bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
#             hedgehog.object.hide = True
#             hedgehog.object.select = False
#             hedgehog = PmlsObject(bpy.context.scene.objects.active)         
#         if anchor and anchor.object.parent:
#             anchor.object.hide = False
#             anchor.object.select = True
#             bpy.context.scene.objects.active = anchor.object
#             bpy.ops.object.duplicate(linked=True)
#             bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')            
#             anchor.object.select = False
#             anchor = PmlsObject(bpy.context.scene.objects.active)  
        bpy.context.scene.objects.active = obj                   
        if hedgehog:
            hedgehog.object.select = True
        if anchor:
            anchor.object.select = True
        bpy.ops.object.parent_set()
        if hedgehog:
            hedgehog.object.select = False
            hedgehog.object.hide = True
        if anchor:
            anchor.object.select = False
            anchor.object.hide = True
            
                

        
        
    def _init_from_matlab(self, mobj):
        super()._init_from_matlab(mobj)
        self.set_edit_mode()
        obj = self.object
        I = obj.vertex_groups.get("anchor")
        if I:
            bpy.ops.object.vertex_group_set_active(group="anchor")
            bpy.ops.object.vertex_group_lock(action='UNLOCK')
        NI = mobj.get("anchor_i")
        if I:
            if NI:
                bpy.ops.object.vertex_group_remove_from(use_all_verts=True)
                I.add(NI, 1.0, 'REPLACE')
            else:
                bpy.ops.object.vertex_group_remove()
                I = None
        elif NI:
            I = obj.vertex_groups.new("anchor")
            I.add(NI, 1.0, 'REPLACE')
        if I:
            bpy.ops.object.vertex_group_lock(action='LOCK')


        H = self.hedgehog()
        NH = mobj.get("hedgehog")
        if H:
            if NH:
                if pmls_is_pmlsobj(NH):
                    if NH.name != H.object.name:
                        H.delete_object()
                        NH = PmlsObject(NH)
                    else:
                        NH = H
                else:
                    NH = H.update_from_matlab(NH)
            elif NH is not None:
                NH = H
        elif NH:
            NH = PmlsObject(NH)
        A = self.anchor()
        NA = mobj.get("anchor")
        if A:
            if NA:
                if pmls_is_pmlsobj(NA):
                    if NA.name != A.object.name:
                        A.delete_object()
                        NA = PmlsObject(NA)
                    else:
                        NA = A
                else:
                    NA = A.update_from_matlab(NA)
            elif NA is not None:
                NA = A
        elif NA:
            NA = PmlsObject(NA)
            
            
        self.set_children(NH, NA)
        
    def complete_matlab_data(self, T):
        NH = T.get("hedgehog")
        if not NH and NH is not None:
            H = self.hedgehog()
            if H:
                T["hedgehog"] = H.object
        NA = T.get("anchor")
        if not NA and NA is not None:
            A = self.anchor()
            if A:
                T["anchor"] = A.object
        return T
        

           
    def hedgehog(self):
        for H in self.object.children:
            ot = PmlsObject.pmls_get_type(H)
            if ot and ot.is_hedgehog():
                return PmlsObject(H)

    def anchor(self):
        for H in self.object.children:
            ot = PmlsObject.pmls_get_type(H)
            if ot and ot.is_mesh():
                return PmlsObject(H)
    

        
    def to_matlab(self, only_anchors=False, no_hedgehog=False, no_anchor=False):
        if not only_anchors:
            S = super().to_matlab()
        else:
            S = self._to_matlab_skeleton()
        self.set_object_mode()
        obj = self.object
        if not no_anchor and "anchor" in obj.vertex_groups.keys():
            vg = obj.vertex_groups["anchor"].index
            S['anchor_i'] = matlab.int32([v.index + 1 for v in obj.data.vertices if vg in [g.group for g in v.groups]])
        if not no_hedgehog:
            H = self.hedgehog()
            if H:
                S["hedgehog"] = H.to_matlab()
                H.object.select = False
                H.object.hide = True
        if not no_anchor:
            H = self.anchor()
            if H:
                S["anchor"] = H.to_matlab()
                H.object.select = False
                H.object.hide = True
        return S
    
    def _split_complicated(self):
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        bpy.ops.object.mode_set(mode="EDIT")
        if "tmp" in self.object.vertex_groups.keys():
            bpy.ops.object.vertex_group_set_active(group="tmp")
            bpy.ops.object.vertex_group_remove()
        self.object.vertex_groups.new(name="tmp")
        bpy.ops.object.vertex_group_assign()                
        bpy.ops.mesh.duplicate()
        bpy.ops.mesh.separate()
#        bpy.ops.object.vertex_group_assign()                
        bpy.ops.mesh.select_all(action="DESELECT")
        obj = bpy.context.selected_objects[0]
        obj.name = "selector"
        bpy.ops.object.mode_set()
        bpy.context.scene.objects.active = obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.region_to_loop()
        bpy.ops.mesh.fill()
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent()
#         bpy.ops.mesh.select_all(action="DESELECT")
#         bpy.ops.mesh.select_face_by_sides(number=3, type='GREATER', extend=False)
#         bpy.ops.mesh.quads_convert_to_tris()
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        obj["pmls_type"] = "mesh"
        mobj = self.to_matlab()
        data = PmlsEngine.split_complicated(mobj, PmlsObject(obj).to_matlab())
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.scene.objects.active = obj
        obj.select = True
        bpy.ops.object.delete()
        bpy.context.scene.objects.active = self.object
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.object.vertex_group_select()                
        bpy.ops.object.vertex_group_remove()
        
        return data
  
    def _split_simple(self):
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        bpy.ops.object.mode_set(mode="EDIT")
        if "tmp" in self.object.vertex_groups.keys():
            bpy.ops.object.vertex_group_set_active(group="tmp")
            bpy.ops.object.vertex_group_remove()
#         self.object.vertex_groups.new(name="tmp")
#         bpy.ops.object.vertex_group_assign()
        
        self.set_object_mode()
        bpy.ops.object.duplicate()
        
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.separate()

        obj1 = bpy.context.selected_objects[0]
        obj2 = bpy.context.selected_objects[1]
        
        obj1.name = "selector1"
        bpy.ops.object.mode_set()
        bpy.context.scene.objects.active = obj1
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.region_to_loop()
        bpy.ops.mesh.fill()
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent()
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        obj1["pmls_type"] = "mesh"
        obj2.name = "selector2"
        bpy.ops.object.mode_set()
        bpy.context.scene.objects.active = obj2
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.region_to_loop()
        bpy.ops.mesh.fill()
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent()
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        obj2["pmls_type"] = "mesh"
        
        mobj = self.to_matlab(True)
        obj1 = PmlsObject(obj1)
        obj2 = PmlsObject(obj2)
        data = PmlsEngine.split(mobj, obj1.to_matlab(), obj2.to_matlab())
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        obj1.set_object_mode()
        bpy.ops.object.delete()
        obj2.set_object_mode()
        bpy.ops.object.delete()
        self.set_edit_mode()
        return data
    
    def _split(self):
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        bpy.ops.object.mode_set(mode="EDIT")
        if "tmp" in self.object.vertex_groups.keys():
            bpy.ops.object.vertex_group_set_active(group="tmp")
            bpy.ops.object.vertex_group_remove()
        self.object.vertex_groups.new(name="tmp")
        bpy.ops.object.vertex_group_assign()
        self.set_edit_mode()
        bpy.ops.mesh.select_all(action="DESELECT")
        bpy.ops.mesh.select_face_by_sides(number=3, type='GREATER', extend=False)
        bpy.ops.mesh.quads_convert_to_tris()
        bpy.ops.mesh.select_all(action="DESELECT")
        bpy.ops.object.vertex_group_select()                
        bpy.ops.object.vertex_group_remove()
#        bpy.ops.mesh.loop_to_region()
        
        self.set_object_mode()
        bpy.ops.object.duplicate()
        
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.separate()

        obj1 = bpy.context.selected_objects[0]
        obj2 = bpy.context.selected_objects[1]
        
        obj1.name = "selector1"
        bpy.ops.object.mode_set()
        obj1["pmls_type"] = "mesh"
        obj1 = PmlsObject(obj1)
        obj1.set_edit_mode()
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.region_to_loop()
        loops = obj1.get_selected_loops()
        
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")

        obj2.name = "selector2"
        bpy.ops.object.mode_set()
        obj2["pmls_type"] = "mesh"
        obj2 = PmlsObject(obj2)

        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        
        mobj = self.to_matlab(True)
        data = PmlsEngine.split(mobj, obj1.to_matlab(), obj2.to_matlab(), loops)
        bpy.ops.object.mode_set()
        bpy.ops.object.select_all(action="DESELECT")
        obj1.set_object_mode()
        bpy.ops.object.delete()
        obj2.set_object_mode()
        bpy.ops.object.delete()
        self.set_edit_mode()
        return data
        
    
    def cut(self, simple=True):
        if simple:
            data = self._split()
        else:
            data = self._split_complicated()
        PmlsObject(data[0])
        return self.update_from_matlab(data[1])
        
    def copy(self, simple=True):
        if simple:
            data = self._split()
        else:
            data = self._split_complicated()
        PmlsObject(data[0])
#        PmlsObject(data[1])
        return self

    def split(self, simple=True):
        if simple:
            data = self._split()
        else:
            data = self._split_complicated()
        PmlsObject(data[0])
        PmlsObject(data[1])
        return self
                    
    def delete(self, simple=True):
        if simple:
            data = self._split()
        else:
            data = self._split_complicated()
        return self.update_from_matlab(data[1])
            
class PmlsVolMesh(PmlsObject):
    pmls_type = "vol_mesh"

    @classmethod
    def _add_custom_layers(cls, obj, mobj):
        me = mobj["elements"]
        obj.data["tet_elements"] = [e for e in me];

    def _init_from_matlab(self, mobj):
        ob = self.add_mesh( self._mvt_to_py(mobj), self._medges_to_py(mobj), [], self.object );
        self._add_custom_layers(ob, mobj)
        self.object = ob

        
    def to_matlab(self):
        vertices = self.object.data.vertices
        S = {};
        n = len(vertices)
        mvt = matlab.double(size=(1,3*n))
        vertices.foreach_get('co', mvt[0])
        mvt.reshape((3,n))
        S["verts"] = mvt
        melems = matlab.int32(self.object.data["tet_elements"])
        S["elements"] = melems
        S["pmls_type"] = self.pmls_type
        S["pmls_name"] = self.object.name
        return S
        
class PmlsHedgehog(PmlsObject):
    pmls_type = "hedgehog"
    
    @classmethod
    def _add_bmesh_layers(cls, bm, mobj):
        mbindices = mobj["bindices"]
        mvzindices = mobj["vzindices"]
        mvid = mobj["vid"]
        lay = bm.verts.layers.int.new("is_base")
        layname = bm.verts.layers.string.new("basename")
        bm.verts.ensure_lookup_table();
        for v in bm.verts:
            v[lay] = 0
        if not isinstance(mbindices, collections.Iterable):
            mbindices = [[mbindices]]
        n = len(mbindices)
        for i in range(n):
            index = mbindices[i][0]
            bm.verts[index][lay] = 1
            bm.verts[index][layname] = bytes(mvid[i],'ascii')
        if not isinstance(mvzindices, collections.Iterable):
            mvzindices = [[mvzindices]]
        n = len(mvzindices)
        for i in range(n):
            index = mvzindices[i][0]
            bm.verts[index][lay] = 2
   


    @classmethod
    def _add_custom_layers(cls, obj, mobj):
        bpy.ops.object.mode_set(mode='EDIT')
        me = obj.data
        cls._add_bmesh_layers(bmesh.from_edit_mesh( me ), mobj)
        bpy.ops.object.mode_set()
        
    @classmethod
    def _add_custom_props(cls, obj):
        obj["disp_base"] = True;
        obj["disp_pnts"] = True;
        obj["disp_zeroshots"] = True;
        obj["disp_edges"] = True;
        
        
    def _init_from_matlab(self, mobj):
        ob = self.add_mesh( self._mvt_to_py(mobj), self._medges_to_py(mobj), [], self.object );
        self._add_custom_layers( ob, mobj )
        self._add_custom_props(ob)
        self.object = ob
        
    def _clear_objdata(self):
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_base")
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_pnts")
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_zeroshots")
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_edges")
        
    @staticmethod
    def _update_display_verts_old(obj, bm):
        lay = bm.verts.layers.int["is_base"]
        if not obj['disp_base'] and not obj['disp_pnts']:
            for v in bm.verts:
                PmlsObject.hide(v)
        elif not obj['disp_base'] or not obj['disp_pnts']:
            to_select = True
            if obj['disp_base']:
                to_select = False
            for v in bm.verts:
                if bool(v[lay]) == to_select:
                    PmlsObject.hide(v)
                else:
                    PmlsObject.un_hide(v)
        else:
            for v in bm.verts:
                PmlsObject.un_hide(v)

    @staticmethod
    def _update_display_verts(obj, bm):
        lay = bm.verts.layers.int["is_base"]
        for v in bm.verts:
            if v[lay] != 1:
                v.hide = True
        if obj['disp_pnts'] or obj['disp_zeroshots']:
            overts0 = [e.other_vert(b) for b in bm.verts if b[lay] == 1 and not b.hide for e in b.link_edges]
            if obj['disp_pnts']:
                overts = [v for v in overts0 if v[lay] == 0] 
                for v in overts:
                    v.hide = False
            if obj['disp_zeroshots']:
                overts = [v for v in overts0 if v[lay] == 2] 
                for v in overts:
                    v.hide = False
    
    @staticmethod
    def _update_display_edges(obj, bm):
        lay = bm.verts.layers.int["is_base"]
        if ( not obj['disp_edges']  ):
            for v in bm.edges:
                if (not(v.verts[0].hide or v.verts[1].hide)) and (v.verts[0][lay] == 2 or v.verts[1][lay] == 2):
                    v.hide = False
                else:
                    v.hide = True 
        else:
            for v in bm.edges:
                if v.verts[0].hide or v.verts[1].hide:
                    v.hide = True
                else:
                    v.hide = False
 
    @staticmethod
    def _update_display(obj, bm):
        PmlsHedgehog._update_display_verts(obj, bm)
        PmlsHedgehog._update_display_edges(obj, bm)
        
        
    def update_display(self):
        obj = self.object
        bm = self.get_bmesh()
        seq = [v for v in bm.faces if v.select]
        seq.extend( [v for v in bm.edges if v.select] )
        seq.extend( [v for v in bm.verts if v.select] )
        bpy.ops.mesh.select_all(action='DESELECT')
        self._update_display(obj, bm)
        for v in seq:
            if not v.hide:
                v.select = True
#         seq = [v for v in bm.faces if v.hide]
#         seq.extend( [v for v in bm.edges if v.hide] )
#         seq.extend( [v for v in bm.verts if v.hide] )
#         for v in seq:
#             v.hide = False
#             v.select = False
#             v.hide = True
        
        bm.select_flush(True)
        bmesh.update_edit_mesh(obj.data, tessface=False, destructive=False)
        
    def hide_stations(self,selected):
        obj = self.object
        bm = self.get_bmesh()
        seq = [v for v in bm.faces if v.select]
        seq.extend( [v for v in bm.edges if v.select] )
        seq.extend( [v for v in bm.verts if v.select] )
        bpy.ops.mesh.select_all(action='DESELECT')
        lay = bm.verts.layers.int["is_base"]
        for v in bm.verts:
            if v[lay] == 1 and selected == v.select:
                v.hide = True
        self._update_display(obj, bm)
        for v in seq:
            if not v.hide:
                v.select = True
        bm.select_flush(True)
        bmesh.update_edit_mesh(obj.data, tessface=False, destructive=False)

    def reveal_stations(self):
        obj = self.object
        bm = self.get_bmesh()
        seq = [v for v in bm.faces if v.select]
        seq.extend( [v for v in bm.edges if v.select] )
        seq.extend( [v for v in bm.verts if v.select] )
        bpy.ops.mesh.select_all(action='DESELECT')
        lay = bm.verts.layers.int["is_base"]
        for v in bm.verts:
            if v[lay] == 1:
                v.hide = False
        self._update_display(obj, bm)
        for v in seq:
            if not v.hide:
                v.select = True
        bm.select_flush(True)
        bmesh.update_edit_mesh(obj.data, tessface=False, destructive=False)
        
    def deselect_stations(self):
        obj = self.object
        bm = self.get_bmesh()
        lay = bm.verts.layers.int["is_base"]
        for v in bm.verts:
            if v[lay] == 1:
                v.select = False
        bm.select_flush(False)
        bmesh.update_edit_mesh(obj.data, tessface=False, destructive=False)
        
        
        
        
    def _to_matlab(self, bm, sbase, lay):
        layname = bm.verts.layers.string["basename"]
        S = {}
        S["verts"] = matlab.double([list(v.co) for v in bm.verts])
        S["selvt"] = matlab.logical([v.select for v in bm.verts])
        S["vid"] = [v[layname].decode("utf-8") for v in sbase]
        S["base_i"] = matlab.int32([v.index + 1 for v in sbase])
        S["rays_i"] =      [matlab.int32([e.other_vert(b).index + 1 for e in b.link_edges if e.other_vert(b)[lay] != 2 ]) for b in sbase]
        S["zeroshots_i"] = [matlab.int32([e.other_vert(b).index + 1 for e in b.link_edges if e.other_vert(b)[lay] == 2 ]) for b in sbase]
        S["pmls_type"] = self.pmls_type
        S["pmls_name"] = self.object.name
        return S
        
    def to_matlab(self):
        bm = self.get_bmesh()
        lay = bm.verts.layers.int["is_base"]
        sbase = [v for v in bm.verts if v[lay] == 1]
        return self._to_matlab(bm, sbase, lay)

    @classmethod
    def is_hedgehog(cls):
        return True
    
    def cut(self):
        self.deselect_stations()
        bpy.ops.mesh.select_more(False)
        bpy.ops.mesh.separate()
        
    def copy(self):
        self.deselect_stations()
        bpy.ops.mesh.select_more(False)
        bpy.ops.mesh.duplicate()
        bpy.ops.mesh.separate()

    def split(self):
        self.set_object_mode()
        if "tmp" in self.object.vertex_groups.keys():
            bpy.ops.object.vertex_group_set_active(group="tmp")
            bpy.ops.object.vertex_group_remove()
        self.set_edit_mode()
        self.object.vertex_groups.new(name="tmp")
        bpy.ops.object.vertex_group_assign()                
        self.deselect_stations()
        bpy.ops.mesh.select_more(False)
        bpy.ops.mesh.duplicate()
        bpy.ops.mesh.separate()
        obj1 = PmlsObject(bpy.context.selected_objects[0])
        bpy.ops.mesh.select_all(action="DESELECT")
        bpy.ops.object.vertex_group_select()                
        bpy.ops.mesh.select_all(action="INVERT")
        self.deselect_stations()
        bpy.ops.mesh.select_more(False)
        bpy.ops.mesh.duplicate()
        bpy.ops.mesh.separate()
        obj2 = PmlsObject(bpy.context.selected_objects[0])
        bpy.ops.object.vertex_group_select()                
        bpy.ops.object.vertex_group_remove()
        if obj1:
            obj1.set_object_mode()
            bpy.ops.object.vertex_group_remove()
        if obj2:
            obj2.set_object_mode()
            bpy.ops.object.vertex_group_remove()
        self.set_edit_mode()
            
        
        
    def delete(self):
        self.deselect_stations()
        bpy.ops.mesh.delete()
             
class PmlsTurtle(PmlsHedgehog, PmlsMesh):
    pmls_type = "turtle"    

    @classmethod
    def _add_custom_props(cls, obj):
        super()._add_custom_props(obj)
        obj["disp_faces"] = True;

    def _clear_objdata(self):
        super()._clear_objdata()
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_faces")

    @classmethod
    def _add_bmesh_layers(cls, bm, mobj):
        super()._add_bmesh_layers(bm, mobj)
        lay = bm.edges.layers.int.new("is_extended")
        for e in bm.edges:
            e[lay] = -1
        edges = cls._medges_to_py(mobj)
        bm.verts.ensure_lookup_table();
        edges = [bm.edges.get( (bm.verts[e[0]], bm.verts[e[1]]) ) for e in edges]
        for e in edges:
            e[lay] = 0
                

    def _init_from_matlab(self, mobj):
        ob = self.add_mesh( self._mvt_to_py(mobj), self._medges_to_py(mobj), self._mfaces_to_py(mobj), self.object );
        self._add_custom_layers(ob, mobj)
        self._add_custom_props(ob)
        self.object = ob
        
    @staticmethod
    def _update_display(obj, bm):
        PmlsHedgehog._update_display_verts(obj, bm)
        vlay = bm.verts.layers.int["is_base"]
        elay = bm.edges.layers.int["is_extended"]

        todisp = set()        
        if obj['disp_edges']:
            todisp.add(0)
        if obj['disp_faces']:
            todisp.add(-1)
        for v in bm.edges:
            if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] in todisp or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
                v.hide = False
            else:
                v.hide = True 
        
        
#         if ( not obj['disp_edges']  ):
#             for v in bm.edges:
#                 if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] == -1 or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
#                     v.hide = False
#                 else:
#                     v.hide = True 
#         else:
#             for v in bm.edges:
#                 if v.verts[0].hide or v.verts[1].hide:
#                     v.hide = True
#                 else:
#                     v.hide = False
        
        for f in bm.faces:
            f.hide = any([ e.hide for e in f.edges ])
            
        
    def clear_turtles(self):
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.reveal()
        bpy.ops.mesh.select_all(action="DESELECT")
        bm = self.get_bmesh()
        lay = bm.edges.layers.int["is_extended"]
        for e in bm.edges:
            if e[lay] == -1:
                e.select_set(True)
        bmesh.update_edit_mesh(self.object.data, tessface=False, destructive=False)
        bpy.ops.mesh.delete(type="EDGE_FACE")
        bm = self.get_bmesh()
        lay = bm.edges.layers.int["is_extended"]
        bm.edges.layers.int.remove(lay)
        bmesh.update_edit_mesh(self.object.data, tessface=False, destructive=False)
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_faces")
        self.object["pmls_type"] = PmlsHedgehog.pmls_type
        ob = self.object
        ob["disp_base"] = True;
        ob["disp_pnts"] = True;
        ob["disp_zeroshots"] = True;
        ob["disp_edges"] = True;
        return PmlsObject(ob)        

class PmlsExtendedHedgehog(PmlsHedgehog):
    pmls_type = "ehedgehog"
    
    @classmethod
    def _add_custom_props(cls, obj):
        super()._add_custom_props(obj)
        obj["disp_extedges"] = True;


#     def _init_from_matlab(self, mobj):
#         super()._init_from_matlab(mobj)
#         self.object["disp_extedges"] = True;
        
    def _clear_objdata(self):
        PmlsHedgehog._clear_objdata(self)
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_extedges")

    
    @classmethod    
    def _add_bmesh_layers(cls, bm, mobj):
        super()._add_bmesh_layers(bm, mobj)
#        bm.edges.ensure_lookup_table();
        mextindices = mobj["extindices"]
        lay = bm.edges.layers.int.new("is_extended")
        for e in bm.edges:
            e[lay] = 0
        edges = cls._medges_to_py(mobj)
        edges = [edges[i[0]] for i in mextindices];
        bm.verts.ensure_lookup_table();
        edges = [bm.edges.get( (bm.verts[e[0]], bm.verts[e[1]]) ) for e in edges]
        for e in edges:
            e[lay] = 1
            
#        for i in mextindices:
#            index = i[0]
#            bm.edges[index][lay] = 1
    
    @staticmethod    
    def _update_display(obj, bm):
        PmlsHedgehog._update_display(obj, bm)
        lay = bm.edges.layers.int["is_extended"]
        
        if ( not obj['disp_extedges']  ):
            for v in bm.edges:
                if v[lay] == 1:
                    v.hide = True
        else:
            for v in bm.edges:
                if v[lay] == 1:
                    if v.verts[0].hide or v.verts[1].hide:
                        v.hide = True
                    else:
                        v.hide = False
                        
    def downdate(self, todel):
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.reveal()
        bpy.ops.mesh.select_all(action="DESELECT")
        if todel:
            bm = self.get_bmesh()
            lay = bm.edges.layers.int["is_extended"]
            for e in bm.edges:
                if e[lay]:
                    e.select_set(True)
            bmesh.update_edit_mesh(self.object.data, tessface=False, destructive=False)
            bpy.ops.mesh.delete(type="EDGE")
        bm = self.get_bmesh()
        lay = bm.edges.layers.int["is_extended"]
        bm.edges.layers.int.remove(lay)
        bmesh.update_edit_mesh(self.object.data, tessface=False, destructive=False)
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_extedges")
        self.object["pmls_type"] = PmlsHedgehog.pmls_type
        ob = self.object
        ob["disp_base"] = True;
        ob["disp_pnts"] = True;
        ob["disp_zeroshots"] = True;
        ob["disp_edges"] = True;
        return PmlsObject(ob)
        
    def _to_matlab(self, bm, sbase, lay):
        S = PmlsHedgehog._to_matlab(self, bm, sbase, lay)
        S["erays_i"] = S["rays_i"]
        elay = bm.edges.layers.int["is_extended"]
        S["rays_i"] = [matlab.int32([e.other_vert(b).index + 1 for e in b.link_edges if (e[elay] == 0 and e.other_vert(b)[lay] != 2) ]) for b in sbase]
        return S
        
class PmlsExtendedTurtle(PmlsExtendedHedgehog, PmlsMesh):
    pmls_type = "eturtle"    

    @classmethod
    def _add_custom_props(cls, obj):
        super()._add_custom_props(obj)
        obj["disp_faces"] = True;
        
    def _clear_objdata(self):
        super()._clear_objdata()
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_faces")


    def _init_from_matlab(self, mobj):
        ob = self.add_mesh( self._mvt_to_py(mobj), self._medges_to_py(mobj), self._mfaces_to_py(mobj), self.object );
        self._add_custom_layers(ob, mobj)
        self._add_custom_props(ob)
        self.object = ob
          
    @classmethod
    def _add_bmesh_layers(cls, bm, mobj):
        tmp = super(PmlsExtendedHedgehog, cls)
        tmp._add_bmesh_layers(bm, mobj)
        mextindices = mobj["extindices"]
        lay = bm.edges.layers.int.new("is_extended")
        for e in bm.edges:
            e[lay] = -1
        edges = cls._medges_to_py(mobj)
        bm.verts.ensure_lookup_table();
        bmedges = [bm.edges.get( (bm.verts[e[0]], bm.verts[e[1]]) ) for e in edges]
        for e in bmedges:
            e[lay] = 0
        edges = [edges[i[0]] for i in mextindices];
        bm.verts.ensure_lookup_table();
        edges = [bm.edges.get( (bm.verts[e[0]], bm.verts[e[1]]) ) for e in edges]
        for e in edges:
            e[lay] = 1
        
    @staticmethod
    def _update_display(obj, bm):
        PmlsHedgehog._update_display_verts(obj, bm)
        vlay = bm.verts.layers.int["is_base"]
        elay = bm.edges.layers.int["is_extended"]
        todisp = set()        
        if obj['disp_edges']:
            todisp.add(0)
        if obj['disp_extedges']:
            todisp.add(1)
        if obj['disp_faces']:
            todisp.add(-1)
        for v in bm.edges:
            if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] in todisp or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
                v.hide = False
            else:
                v.hide = True 
#         if ( not obj['disp_edges'] and not obj['disp_extedges']  ):
#             for v in bm.edges:
#                 if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] == -1 or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
#                     v.hide = False
#                 else:
#                     v.hide = True 
#         elif not obj['disp_edges']:
#             for v in bm.edges:
#                 if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] != 0 or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
#                     v.hide = False
#                 else:
#                     v.hide = True 
#         elif not obj['disp_extedges']:
#             for v in bm.edges:
#                 if (not(v.verts[0].hide or v.verts[1].hide)) and (v[elay] != 1 or v.verts[0][vlay] == 2 or v.verts[1][vlay] == 2):
#                     v.hide = False
#                 else:
#                     v.hide = True 
#         else:
#             for v in bm.edges:
#                 if v.verts[0].hide or v.verts[1].hide:
#                     v.hide = True
#                 else:
#                     v.hide = False
         
        for f in bm.faces:
            f.hide = any([ e.hide for e in f.edges ])
        edges = [e for e in bm.edges if not e.hide and e[elay] == -1 and not any( [not f.hide for f in e.link_faces] ) ]
        for e in edges:
            e.hide = True
        
                    
    def clear_turtles(self):
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.reveal()
        bpy.ops.mesh.select_all(action="DESELECT")
        bm = self.get_bmesh()
        lay = bm.edges.layers.int["is_extended"]
        for e in bm.edges:
            if e[lay] == -1:
                e.select_set(True)
        bmesh.update_edit_mesh(self.object.data, tessface=False, destructive=False)
        bpy.ops.mesh.delete(type="EDGE_FACE")
        bpy.ops.wm.properties_remove(data_path="active_object", property="disp_faces")
        self.object["pmls_type"] = PmlsExtendedHedgehog.pmls_type
        ob = self.object
        ob["disp_base"] = True;
        ob["disp_pnts"] = True;
        ob["disp_zeroshots"] = True;
        ob["disp_edges"] = True;
        ob["disp_extedges"] = True;
        return PmlsObject(ob)
    
    def downdate(self, todel):
        return self.clear_turtles().downdate(todel)       
        

class PmlsEngine:
    eng = None
    isr = False
    data_counter = 0
    name = ""
    islib = False
    
    @classmethod
    def enginename( cls ):
        return cls.eng.matlab.engine.engineName()
    
    @classmethod
    def is_running(cls):
        eng = cls.eng
        if eng and hasattr(matlab, 'engine') and isinstance(eng, matlab.engine.matlabengine.MatlabEngine):
            try:
                x = eng.eye(1)
                cls.isr = True
                cls.islib = False
                return True
            except: #matlab.engine.matlabengine.RejectedExecutionError:
                cls.isr = False
                cls.name = ""
                cls.islib = False
                return False
        if eng and pmlslib_module and getattr(eng, 'name', 'nn') == 'pmlslib':
            try:
                x = eng.areyouthere()
                cls.isr = True
                cls.islib = True
                return True
            except: #matlab.engine.matlabengine.RejectedExecutionError:
                cls.isr = False
                cls.name = ""
                cls.islib = False
                return False
        else:
            cls.isr = False
            cls.name = ""
            cls.islib = False
            return False
   
    @classmethod
    def start(cls):
        if (not cls.is_running()) and hasattr(matlab, 'engine'):
            cls.eng = matlab.engine.start_matlab("-desktop")
            cls.name = ""
            cls.is_running()
            
    @classmethod
    def startpoll(cls):
        return (not cls.isr) and hasattr(matlab, 'engine')

    @classmethod
    def connect(cls, name):
        if not cls.is_running():
            if hasattr(matlab, 'engine') and name in matlab.engine.find_matlab():
                cls.eng = matlab.engine.connect_matlab( name )
            if pmlslib_module and name == 'pmlslib':
                cls.eng = pmlslib.initialize()
            if cls.is_running():
                cls.name = name
    
    @classmethod
    def stop(cls):
        eng = cls.eng
        if cls.is_running() and not cls.islib:
            eng.eval( 'quit', nargout = 0 )
            if not cls.is_running():
                cls.name = ""
                
    @classmethod
    def stoppoll(cls):
        return cls.isr and not cls.islib
    

    @classmethod
    def disconnect(cls):
        if cls.is_running():
            if cls.islib:
                if cls.name != getattr(cls.eng, 'name', ''):
                    raise AssertionError('name != libname')
                eng=cls.eng
                eng.quit()
                cls.eng = None
            else:
                if cls.name != cls.enginename():
                    raise AssertionError('name != enginename')
                eng=cls.eng
                eng.quit()
                cls.eng = None
            if not cls.is_running():
                cls.name = ""

    @staticmethod
    def findmatlab():
        if hasattr(matlab, 'engine') and pmlslib_module:
            return ('pmlslib',) + matlab.engine.find_matlab()
        if hasattr(matlab, 'engine'):
            return matlab.engine.find_matlab()
        if pmlslib_module:
            return ('pmlslib',)


    @staticmethod
    def add_mesh(name, verts, edges, faces, ob=None, selvt=None  ):
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set()
        if not ob:
            bpy.ops.object.select_all(action='DESELECT')
            bpy.ops.object.add(type='MESH',location=(0,0,0))
            ob = bpy.context.object
            ob.name = name
            me = ob.data
            me.name = name
        else:
            me = ob.data
        me.from_pydata(verts, edges, faces)
        me.update(calc_edges=True)
        if selvt:
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.reveal()
            bpy.ops.mesh.select_all(action="DESELECT")
            bm=bmesh.from_edit_mesh(me)
            bm.verts.ensure_lookup_table()
            for i in selvt:
                bm.verts[i].select = True
            bm.select_flush(True)
            bmesh.update_edit_mesh(me, tessface=False, destructive=False)
            bpy.ops.object.mode_set()

                                    
        return ob
    
    @classmethod
    def load_mat(cls, path):
        data = cls.eng.loadhedgehogs(path)
        for D in data:
            PmlsObject(D)

    @classmethod
    def main_sqlite2csv(cls, source, dest):
        cls.eng.mainsqlite2csv(source, dest, nargout=0)

    @classmethod
    def sqlite2csvs(cls, sqfile, maincsv, destdir):
        cls.eng.sqlite2csvs(sqfile, maincsv, destdir, nargout=0)

    @classmethod
    def get_input(cls, csvfile, polfile, truemin):
        err = io.StringIO()
         
        try:
            if polfile:
                D = cls.eng.getinputpy(csvfile, truemin, polfile, stderr=err)
            else:
                D = cls.eng.getinputpy(csvfile, truemin, stderr=err)
            PmlsObject(D)
            return (True, '', err.getvalue())
        except:
            return (False, '', err.getvalue())
#     @classmethod
#     def get_input(cls, csvfile, polfile):
#         try:
#             if polfile:
#                 cls.eng.getinputmain(csvfile, polfile, nargout=0)
#             else:
#                 cls.eng.getinputmain(csvfile, nargout=0)
#         except:
#             self.report({'INFO'}, self.message)
#             pass
            
            

    @classmethod
    def save_mat(cls, path, data):
        cls.eng.savehedgehogs(path, data, nargout=0)

    @classmethod
    def turtles(cls, S):
        return cls.eng.turtlepy(S)

    @classmethod
    def separate_turtles(cls, S):
        data = cls.eng.separateturtles(S)
        for D in data:
            PmlsObject(D)
    
    

    @classmethod
    def extend_hedgehog(cls, S):
        return cls.eng.extendvisiblepy(S)

    @classmethod
    def remeshunion(cls, S, vox, ext):
        return cls.eng.remeshunionpy(S, vox, ext)

    @classmethod
    def tetremeshunion(cls, S, tetgen, par_a, par_q, par_d):
        return cls.eng.tetremeshunionpy(S, tetgen, par_a, par_q, par_d)

    @classmethod
    def bihar_pnts(cls, S, unilap, snaptol, voxsiz, to_raycheck):
        return cls.eng.biharpntspy(S, unilap, snaptol, voxsiz, to_raycheck)

    @classmethod
    def map_pnts(cls, S):
        return cls.eng.mappntspy(S)

    @classmethod
    def merge_hedgehogs(cls, S):
        return cls.eng.mergeinputpy(S)

    @classmethod
    def remesh_union(cls, S, vox, ext):
        return cls.eng.remeshunioncpy(S, vox, ext)

    @classmethod
    def remesh_union_bihar(cls, S, vox, ext, unilap, premesh):
        return cls.eng.remeshunionbiharcpy(S, vox, ext, unilap, premesh)

    @classmethod
    def normal_union(cls, S, premesh, tetgen, par_a, par_q, par_d):
        return cls.eng.libiglunionpy(S, premesh, tetgen, par_a, par_q, par_d)

    @classmethod
    def create_vol_mesh(cls, S):
        return cls.eng.surf2meshpy(S)

    @classmethod
    def split_complicated(cls, S, H):
        return cls.eng.separatepy(S,H)

    @classmethod
    def split_simple(cls, S, H1, H2):
        return cls.eng.separatesimplepy(S,H1, H2)

    @classmethod
    def split(cls, S, H1, H2, L):
        return cls.eng.separatetrianglepy(S,H1, H2, L)
    
    @classmethod
    def fill(cls, S):
        return cls.eng.filltripy(S)



class PmlsStart(bpy.types.Operator):
    bl_idname = "pmls.start"
    bl_label = "pmls start"
    
    @classmethod
    def pmls_engine(cls):
        return PmlsEngine
    
    @classmethod
    def poll(cls, context):
        return PmlsEngine.startpoll()

    def execute(self, context):
        PmlsEngine.start()
        return {'FINISHED'}

class PmlsConnect(bpy.types.Operator):
    bl_idname = "pmls.connect"
    bl_label = "pmls connect"
    
    name = bpy.props.StringProperty()
    
    @classmethod
    def poll(cls, context):
        return not PmlsEngine.isr

    def execute(self, context):
        PmlsEngine.connect(self.name)
        return {'FINISHED'}

class PmlsStop(bpy.types.Operator):
    bl_idname = "pmls.stop"
    bl_label = "pmls stop"
    
    @classmethod
    def poll(cls, context):
        return PmlsEngine.stoppoll()

    def execute(self, context):
        PmlsEngine.stop()
        return {'FINISHED'}

class PmlsDisconnect(bpy.types.Operator):
    bl_idname = "pmls.disconnect"
    bl_label = "pmls disconnect"
    
    @classmethod
    def poll(cls, context):
        return PmlsEngine.isr and PmlsEngine.name

    def execute(self, context):
        PmlsEngine.disconnect()
        return {'FINISHED'}
    
class PmlsLoadMat(bpy.types.Operator):
    """Loads mat file"""
    bl_idname = "pmls.loadmat"
    bl_label = "pmls load mat file"
    
    filter_glob = bpy.props.StringProperty(default="*.mat", options={'HIDDEN'})
    directory = bpy.props.StringProperty(subtype="DIR_PATH")
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
    files = bpy.props.CollectionProperty(name="File Path",type=bpy.types.OperatorFileListElement) 
    @classmethod
    def poll(cls, context):
        return PmlsEngine.isr

    def execute(self, context):
        for fp in self.files:
            PmlsEngine.load_mat(self.directory + fp.name)
#        PmlsEngine.load_mat(self.filepath)
        return {'FINISHED'}

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

class PmlsSaveMat(bpy.types.Operator):
    """Saves selected PMLS objects to mat file"""
    bl_idname = "pmls.savemat"
    bl_label = "pmls save mat file"
    
    filter_glob = bpy.props.StringProperty(default="*.mat", options={'HIDDEN'})
    directory = bpy.props.StringProperty(subtype="DIR_PATH")
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
    files = bpy.props.CollectionProperty(name="File Path",type=bpy.types.OperatorFileListElement) 
    @classmethod
    def poll(cls, context):
        if not PmlsEngine.isr:
            return False
        if not context.selected_objects:
            return False
        for obj in context.selected_objects:
            if not pmls_is_pmlsobj(obj):
                return False
        return True

    def execute(self, context):
        objs = PmlsObject.get_selected_objects()
        data = [o.to_matlab() for o in objs]
        PmlsEngine.save_mat(self.filepath, data)
        return {'FINISHED'}

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

def pmls_is_pmlsobj( obj ):
    return obj is not None and isinstance(obj, bpy.types.Object) and obj.type == 'MESH' and "pmls_type" in obj.keys()

def pmls_is_hedgehog( obj ):
    return pmls_is_pmlsobj( obj ) and obj["pmls_type"] == "hedgehog"

def pmls_is_ehedgehog( obj ):
    return pmls_is_pmlsobj( obj ) and obj["pmls_type"] == "ehedgehog"

def pmls_is_extended(obj):
    return pmls_is_pmlsobj( obj ) and (obj["pmls_type"] == "ehedgehog" or obj["pmls_type"] == "eturtle")

def pmls_is_turtle(obj):
    return pmls_is_pmlsobj( obj ) and (obj["pmls_type"] == "turtle" or obj["pmls_type"] == "eturtle")

def pmls_is_mesh(obj):
    return pmls_is_pmlsobj( obj ) and (obj["pmls_type"] == "mesh")

def pmls_is_deform_mesh(obj):
    return pmls_is_pmlsobj( obj ) and (obj["pmls_type"] == "deform_mesh")

def pmls_has_hedgehog(obj):
    for H in obj.children:
        ot = PmlsObject.pmls_get_type(H)
        if ot and ot.is_hedgehog():
            return True
    return False
            
    

class PmlsUpdateDisplay(bpy.types.Operator):
    """Updates display of active object"""
    bl_idname = "pmls.updatedisplay"
    bl_label = "pmls update display"

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and pmls_is_pmlsobj( obj )
          

    def execute(self, context):
        pobj = PmlsObject()
        if pobj:
            pobj.update_display()
        return {'FINISHED'}
            

class PmlsDowdateEhedgehog(bpy.types.Operator):
    bl_idname = "pmls.downdate_ehedgehog"
    bl_label = "pmls downdate ehedgehog"
    todel = bpy.props.BoolProperty(default=True)
    
    @classmethod
    def poll(cls, context):
        return pmls_is_extended(context.active_object)

    def execute(self, context):
        obj = PmlsExtendedHedgehog(context.active_object)
        obj.downdate(self.todel)
        return {'FINISHED'}

class PmlsHedgehogUnion(bpy.types.Operator):
    """Union by voxelization"""
    bl_idname = "pmls.hedgehog_union"
    bl_label = "pmls hedgehog union"

    voxel_siz = bpy.props.FloatProperty(
                name="Voxel size (cm):", default=3.0, step=5, min=0.000001, soft_min=1.0, soft_max=1000.0, subtype='DISTANCE')
    extend = bpy.props.FloatProperty(
                name="Thicken volume (voxel):", default=3.0, step=5, min=0.0, soft_min=0.0, soft_max=10.0, subtype='DISTANCE')
    
    @classmethod
    def poll(cls, context):
        return pmls_is_extended(context.active_object)

    def execute(self, context):
        obj = PmlsExtendedHedgehog(context.active_object)
        H = obj.to_matlab()
        S = PmlsEngine().remeshunion(H, self.voxel_siz, self.extend)
        S = PmlsObject(S)
        S.advance(obj,None)
        return {'FINISHED'}

class PmlsHedgehogUnionAlec(bpy.types.Operator):
    """Union by voxelization"""
    bl_idname = "pmls.hedgehog_union_alec"
    bl_label = "pmls hedgehog union_alec"

    tetgen = bpy.props.BoolProperty(name="Remesh turtles before union", description="Remesh increases the number of triangles, but the mesh will be nicer.", default=True)
    tetgen_a = bpy.props.FloatProperty(
        name="Max volume of tetrahedra (m3)", description="Tetgen command line parameter -a.",
        default=0.5, step=0.001, min=0.0000001, soft_min=0.0000001, soft_max=100.0, subtype='UNSIGNED', unit='VOLUME')
    tetgen_q = bpy.props.FloatProperty(
        name="Max radius-edge ratio", description="First value of tetgen command line parameter -q.",
        default=2.0, step=0.001, min=1.0, soft_min=1.0, soft_max=100.0, subtype='UNSIGNED')
    tetgen_d = bpy.props.FloatProperty(
        name="Min dihedral angle (deg)", description="Second value of tetgen command line parameter -q.",
        default=0.0, step=5.0, min=0.0, soft_min=0.0, soft_max=70, subtype='UNSIGNED')
    
    @classmethod
    def poll(cls, context):
        return pmls_is_extended(context.active_object)

    def execute(self, context):
        obj = PmlsExtendedHedgehog(context.active_object)
        H = obj.to_matlab()
        S = PmlsEngine().tetremeshunion(H, self.tetgen, self.tetgen_a, self.tetgen_q, self.tetgen_d)
        S = PmlsObject(S)
        S.advance(obj,None)
        return {'FINISHED'}

class PmlsVoxelizedUnion(bpy.types.Operator):
    """Union of meshes by voxelization"""
    bl_idname = "pmls.voxelized_union"
    bl_label = "pmls voxelized union"

    voxel_siz = bpy.props.FloatProperty(
                name="Voxel size (cm):", default=3.0, step=5, min=0.000001, soft_min=1.0, soft_max=1000.0, subtype='DISTANCE')
    extend = bpy.props.FloatProperty(
                name="Thin volume (voxel):", default=3.0, step=5, min=0.0, soft_min=0.0, soft_max=10.0, subtype='DISTANCE')
    deform = bpy.props.BoolProperty(name="Volumetric deform", default=True)

#     hedgehog = bpy.props.StringProperty()
    unilap = bpy.props.BoolProperty(name="Uniform laplacian", description="If true uniform weights will be used instead of edge lenghts. Less conservative deformation.", default=True)
    premesh = bpy.props.BoolProperty(name="Remesh before deform", description="If true remesh done before and after the deform else only after", default=True)

   
    @classmethod
    def poll(cls, context):
        if not PmlsEngine.isr:
            return False
        obj = context.active_object
        if obj is None:
            return False
#         if obj.mode != "OBJECT":
#             return False
        if not pmls_is_pmlsobj( obj ):
            return False
        if not pmls_is_deform_mesh(obj) or not pmls_has_hedgehog(obj):
            return False
        if not all([pmls_is_deform_mesh(o) and pmls_has_hedgehog(o) for o in context.selected_objects if o.name != obj.name ]):
            return False
        return True

    def execute(self, context):
        obj = context.active_object
        in_place = obj.mode == 'EDIT'
        
        sobjs = PmlsObject.get_selected_objects()
        name = obj.name
        sobjs = [o for o in sobjs if name != o.object.name]         
        aobj = PmlsObject(obj)
        objs = [aobj.to_matlab(no_hedgehog=(not sobjs and not self.deform), no_anchor=(not sobjs))]
        for o in sobjs:
            objs.append(o.to_matlab(no_anchor=True))
        if self.deform:
            T = PmlsEngine.remesh_union_bihar(objs, self.voxel_siz, self.extend, self.unilap, self.premesh)
        else:
            T = PmlsEngine.remesh_union(objs, self.voxel_siz, self.extend)
        if in_place:
            aobj = aobj.update_from_matlab(T)
        else:
            T = aobj.complete_matlab_data(T)
            PmlsObject(T)
        return {'FINISHED'}

class PmlsNormalUnion(bpy.types.Operator):
    """Union of meshes by intersecting faces"""
    bl_idname = "pmls.normal_union"
    bl_label = "pmls normal union"

    premesh = bpy.props.BoolProperty(default=True)
    tetgen = bpy.props.BoolProperty(name="Remesh turtles before union", description="Remesh increases the number of triangles, but the mesh will be nicer.", default=True)
    tetgen_a = bpy.props.FloatProperty(
        name="Max volume of tetrahedra (m3)", description="Tetgen command line parameter -a.",
        default=0.5, step=0.001, min=0.0000001, soft_min=0.0000001, soft_max=100.0, subtype='UNSIGNED', unit='VOLUME')
    tetgen_q = bpy.props.FloatProperty(
        name="Max radius-edge ratio", description="First value of tetgen command line parameter -q.",
        default=2.0, step=0.001, min=1.0, soft_min=1.0, soft_max=100.0, subtype='UNSIGNED')
    tetgen_d = bpy.props.FloatProperty(
        name="Min dihedral angle (deg)", description="Second value of tetgen command line parameter -q.",
        default=0.0, step=5.0, min=0.0, soft_min=0.0, soft_max=70, subtype='UNSIGNED')

   
    @classmethod
    def poll(cls, context):
        if not PmlsEngine.isr:
            return False
        obj = context.active_object
        if obj is None:
            return False
        if obj.mode != "OBJECT":
            return False
        if not pmls_is_pmlsobj( obj ):
            return False
        if not pmls_is_deform_mesh(obj):
            return False
        if not all([pmls_is_deform_mesh(o) for o in context.selected_objects if o.name != obj.name ]):
            return False
        return True

    def execute(self, context):
        obj = context.active_object
        sobjs = PmlsObject.get_selected_objects()
        aobj = PmlsObject(obj)
        objs = [aobj.to_matlab()]
        name = obj.name
        for obj in sobjs:
            if name == obj.object.name:
                continue
            objs.append(obj.to_matlab())
        T = PmlsEngine.normal_union(objs, self.premesh, self.tetgen, self.tetgen_a, self.tetgen_q, self.tetgen_d)
        PmlsObject(T)
        return {'FINISHED'}

class PmlsCreateVolMesh(bpy.types.Operator):
    """Tetrahedralizes the interior of surface mesh"""
    bl_idname = "pmls.create_vol_mesh"
    bl_label = "pmls create volumetric mesh"


   
    @classmethod
    def poll(cls, context):
        if not PmlsEngine.isr:
            return False
        obj = context.active_object
        if obj is None:
            return False
        if obj.mode != "OBJECT":
            return False
        if not pmls_is_pmlsobj( obj ):
            return False
        return pmls_is_mesh(obj)

    def execute(self, context):
        obj = context.active_object
        obj = PmlsObject(obj)
        obj = obj.to_matlab()
        T = PmlsEngine.create_vol_mesh(obj)
        PmlsObject(T)
        return {'FINISHED'}



class PmlsExtendHedgehog(bpy.types.Operator):
    bl_idname = "pmls.extend_hedgehog"
    bl_label = "pmls extend hedgehog"
    
    @classmethod
    def poll(cls, context):
        return PmlsEngine.isr and pmls_is_hedgehog(context.active_object)

    def execute(self, context):
        obj = PmlsHedgehog(context.active_object)
        S = obj.to_matlab()
        T = PmlsEngine.extend_hedgehog(S)
        obj = obj.update_from_matlab(T)
        return {'FINISHED'}
    
class PmlsRecalculateTurtles(bpy.types.Operator):
    bl_idname = "pmls.recalculate_turtles"
    bl_label = "pmls recalculate turtles"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and ( pmls_is_hedgehog(obj) or pmls_is_ehedgehog(obj) ) 
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        S = obj.to_matlab()
        T = PmlsEngine.turtles(S)
        obj = obj.update_from_matlab(T)
        return {'FINISHED'}

class PmlsSeparateTurtles(bpy.types.Operator):
    """Separates hedgehogs by stations, calculates turtles and transorms them to deformable meshes """    
    
    bl_idname = "pmls.separate_turtles"
    bl_label = "pmls separate turtles"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and pmls_is_pmlsobj( obj )
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        S = obj.to_matlab()
        PmlsEngine.separate_turtles(S)
        return {'FINISHED'}

class PmlsClearTurtles(bpy.types.Operator):
    bl_idname = "pmls.clear_turtles"
    bl_label = "pmls clear turtles"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return pmls_is_turtle(obj)
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        obj.clear_turtles()
        return {'FINISHED'}

class PmlsHideSelectedStations(bpy.types.Operator):
    bl_idname = "pmls.hide_selected_stations"
    bl_label = "pmls hide selected stations"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and pmls_is_pmlsobj( obj )
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        obj.hide_stations(True)
        return {'FINISHED'}

class PmlsHideUnselectedStations(bpy.types.Operator):
    bl_idname = "pmls.hide_unselected_stations"
    bl_label = "pmls hide unselected stations"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and pmls_is_pmlsobj( obj )
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        obj.hide_stations(False)
        return {'FINISHED'}
    
class PmlsRevealStations(bpy.types.Operator):
    bl_idname = "pmls.reveal_stations"
    bl_label = "pmls reveal stations"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return PmlsEngine.isr and pmls_is_pmlsobj( obj )
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        obj.reveal_stations()
        return {'FINISHED'}

class PmlsDeselectAllStations(bpy.types.Operator):
    bl_idname = "pmls.deselect_all_stations"
    bl_label = "pmls deselect all stations"
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return pmls_is_pmlsobj( obj )
    
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        obj.deselect_stations()
        return {'FINISHED'}
    
class PmlsMergeHedgehogs(bpy.types.Operator):    
    bl_idname = "pmls.merge_selected_hedges_to_active"
    bl_label = "pmls merge selected hedgehogs to active"
    
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if not PmlsEngine.isr:
            return False
        if obj is None:
            return False
        if obj.mode != "OBJECT":
            return False
        if not pmls_is_pmlsobj( obj ):
            return False
        if not PmlsObject.pmls_get_type(obj).is_hedgehog():
            return False
        return any([PmlsObject.pmls_get_type(o).is_hedgehog() for o in context.selected_objects if o.name != obj.name and pmls_is_pmlsobj( o )]) 
    
    def execute(self, context):
        obj = context.active_object
        sobjs = context.selected_objects
        aobj = PmlsObject(obj)
        objs = [aobj.to_matlab()]
        name = obj.name
        for obj in sobjs:
            if name == obj.name:
                continue
            pobj = PmlsObject(obj)
            if pobj and pobj.is_hedgehog():
                objs.append(pobj.to_matlab())
        T = PmlsEngine.merge_hedgehogs(objs)
        PmlsObject(T)
#        aobj = aobj.update_from_matlab(T)                
        return {'FINISHED'}

class PmlsSurfaceDeform(bpy.types.Operator):
    """Snaps surface to points and interpolates by biharmonic surface"""    
    bl_idname = "pmls.smoot_by_surface_deform"
    bl_label = "pmls smooth by surface deform"
#     hedgehog = bpy.props.StringProperty()
#     points = bpy.props.StringProperty()

    unilap = bpy.props.BoolProperty(
                name="Uniform laplacian", default=True)

    snaptol = bpy.props.FloatProperty(
                name="Snap tolerance (cm):", default=5.0, step=5, min=0.000001, soft_min=0.1, soft_max=100000.0, subtype='DISTANCE')
    
    to_raycheck = bpy.props.BoolProperty(
                name="Ray check", default=True)
    
    voxsiz = bpy.props.FloatProperty(
        name="Voxel size for ray check (cm):", default=7.0, step=5, min=0.000001, soft_min=1.0, soft_max=1000.0, subtype='DISTANCE')

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if not PmlsEngine.isr:
            return False
        if obj is None:
            return False
#         if obj.mode != "OBJECT":
#             return False
        return pmls_is_deform_mesh(obj)
#         if not pmls_is_pmlsobj( obj ):
#             return False
#         if not PmlsObject().pmls_get_type(obj).is_mesh():
#             return False
#         if pmls_is_deform_mesh(obj):
#             return True
#         hdg = context.scene.pmls_op_smooth_by_surface_deform_hdg
#         if hdg:
#             ot = PmlsObject.pmls_get_type(bpy.data.objects[hdg])
#             if ot and ot.is_hedgehog():
#                 return True
#         pnt = context.scene.pmls_op_smooth_by_surface_deform_pnt
#         if pnt and pmls_is_mesh(bpy.data.objects[pnt]):
#             return True
#         return False
        
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        in_place = obj.object.mode == 'EDIT'
        S = obj.to_matlab()
#         HP = {}
#         hedgehog = None
#         if self.hedgehog:
#             hedgehog = PmlsObject(context.scene.objects[self.hedgehog])
#             HP["H"] = hedgehog.to_matlab()
#         points = None
#         if self.points:
#             points = PmlsObject(context.scene.objects[self.points])
#             HP["P"] = points.to_matlab()
#         data = PmlsEngine.bihar_pnts(S, HP, self.snaptol, self.voxsiz)
        data = PmlsEngine.bihar_pnts(S, self.unilap, self.snaptol, self.voxsiz, self.to_raycheck)
#         n = len(data)
        if in_place:
            obj = obj.update_from_matlab(data)
#             if n > 1:
#                 points = points.update_from_matlab(data[1])
        else:
#             NH = data.get("hedgehog")
#             if not NH and NH is not None:
#                 data["hedgehog"] = obj.hedgehog().object
                
                
            data = obj.complete_matlab_data(data)
                
            obj = PmlsObject(data)
#             if n > 1:
#                 points = PmlsObject(data[1])
#         obj.advance(hedgehog, points)
        return {'FINISHED'}

class PmlsMapPointsToMesh(bpy.types.Operator):
    """Select mapped points on surface surface"""    
    bl_idname = "pmls.map_points_to_mesh"
    bl_label = "pmls smooth by surface deform"
#     hedgehog = bpy.props.StringProperty()
#     points = bpy.props.StringProperty()

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if not PmlsEngine.isr:
            return False
        if obj.mode != "EDIT":
            return False
        if obj is None:
            return False
        return pmls_is_deform_mesh(obj)
        
    def execute(self, context):
        obj = PmlsObject(context.active_object)
        S = obj.to_matlab()
        selvt = PmlsEngine.map_pnts(S)
        if selvt:
            if not isinstance(selvt, collections.Iterable):
                selvt = [[selvt]]
            selvt =  [v[0] for v in selvt]
            bm = obj.get_bmesh()
            bm.verts.ensure_lookup_table()
            for i in selvt:
                bm.verts[i].select = True
            bm.select_flush(True)
            bmesh.update_edit_mesh(obj.object.data, tessface=False, destructive=False)
        return {'FINISHED'}

# class PmlsSplit(bpy.types.Operator):
#     """Splits mesh into two pieces"""    
#     bl_idname = "pmls.split"
#     bl_label = "pmls split"
#     selmesh = bpy.props.StringProperty()
# 
#     @classmethod
#     def poll(cls, context):
#         obj = context.active_object
#         if not PmlsEngine.isr:
#             return False
#         if obj is None:
#             return False
#         if obj.mode != "EDIT":
#             return False
#         if not pmls_is_pmlsobj( obj ):
#             return False
#         if not pmls_is_mesh(obj):
#             return False
#         smsh = context.scene.pmls_op_split_selector
#         if smsh:
#             return pmls_is_mesh(bpy.data.objects[smsh])
#         return False
#         
#     def execute(self, context):
#         S = PmlsObject(context.active_object).to_matlab()
#         H = PmlsObject(context.scene.objects[self.selmesh]).to_matlab()
#         data = PmlsEngine.split(S, H)
#         for D in data:
#             PmlsObject(D)        
#         return {'FINISHED'}

class PmlsEditOperator(bpy.types.Operator):
    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if not PmlsEngine.isr:
            return False
        if obj is None:
            return False
        if obj.mode != "EDIT":
            return False
        if not pmls_is_pmlsobj( obj ):
            return False
        return PmlsObject.pmls_get_type(obj).is_hedgehog() or pmls_is_deform_mesh(obj)
    
class PmlsCopy(PmlsEditOperator):
    """Copy selection to new object"""    
    bl_idname = "pmls.copy"
    bl_label = "pmls copy"
    simple = bpy.props.BoolProperty()

    def execute(self, context):
        obj = PmlsObject(context.active_object)
        if obj.is_hedgehog():
            obj.copy()
        else:
            obj.copy(self.simple)
        return {'FINISHED'}

class PmlsSplit(PmlsEditOperator):
    """Split into 2 new object"""    
    bl_idname = "pmls.split"
    bl_label = "pmls split"
    simple = bpy.props.BoolProperty()

    def execute(self, context):
        obj = PmlsObject(context.active_object)
        if obj.is_hedgehog():
            obj.split()
        else:
            obj.split(self.simple)
        return {'FINISHED'}

class PmlsCut(PmlsEditOperator):
    """Cut selection to new object"""    
    bl_idname = "pmls.cut"
    bl_label = "pmls cut"
    simple = bpy.props.BoolProperty()

    def execute(self, context):
        obj = PmlsObject(context.active_object)
        if obj.is_hedgehog():
            obj.cut()
        else:
            obj.cut(self.simple)
        return {'FINISHED'}

class PmlsDelete(PmlsEditOperator):
    """Delete selection"""    
    bl_idname = "pmls.delete"
    bl_label = "pmls delete"
    simple = bpy.props.BoolProperty()

    def execute(self, context):
        obj = PmlsObject(context.active_object)
        if obj.is_hedgehog():
            obj.delete()
        else:
            obj.delete(self.simple)
        return {'FINISHED'}

class PmlsFill(bpy.types.Operator):
    """Fill selected hole"""    
    bl_idname = "pmls.fill"
    bl_label = "pmls fill"
    simple = bpy.props.BoolProperty()

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if not PmlsEngine.isr:
            return False
        if obj is None:
            return False
        if obj.mode != "EDIT":
            return False
        if not pmls_is_pmlsobj( obj ):
            return False
        return PmlsObject.pmls_get_type(obj).is_mesh()
    
    @classmethod
    def get_loop(cls, vs):
        loop=[]
        if not vs:
            return loop
        v1 = vs[0]
        es = [e for e in v1.link_edges if e.select]
        if not es:
            raise Exception('Bad selecting!')
        v2 = es[0].other_vert(v1)
        loop = [v1,v2]
        vstart = v1;
        while True:
            es = [e for e in v2.link_edges if e.select]
            if not es:
                raise Exception('Bad selecting!')
            vs = [e.other_vert(v2) for e in es if e.other_vert(v2) not in loop ]
            if not vs:
                vs = [e.other_vert(v2) for e in es if e.other_vert(v2) in loop and e.other_vert(v2) != v1]
                if len(vs) != 1 or vs[0] != vstart:
                    raise Exception('Bad selecting!')
                return loop
            if len(vs) > 1: 
                raise Exception('Bad selecting!')
            v1 = v2
            v2 = vs[0]
            loop.append(v2)
        


    def execute(self, context):
        obj = PmlsObject(context.active_object)
        bm = obj.get_bmesh()
        vs = [v for v in bm.verts if v.select]
        if not vs:
            raise Exception('Bad selecting!')
        loops = []
        while vs:
            loop = self.get_loop(vs)
            vs = list(set(vs) - set(loop))
            loops.append(matlab.double([list(v.co) for v in loop]))
        
        data = PmlsEngine.fill(loops)
        data2 = []
        for D in data:
            data2.append( PmlsObject(D) )
        obj.select = False
        for obji in data2:
            obji.object.select = True
        bpy.ops.object.duplicate()
        context.scene.objects.active = obj.object;
        bpy.ops.object.join()
        obj.set_edit_mode()
        for obji in data2:
            obji.object.select = True
        
        return {'FINISHED'}
    
    

    
class PmlsCreateMainCsv(bpy.types.Operator):
    """Create main csv"""
    bl_idname = "pmls.create_main_csv"
    bl_label = "pmls create main csv"
    
    filter_glob = bpy.props.StringProperty(default="*.sqlite", options={'HIDDEN'})
    directory = bpy.props.StringProperty(subtype="DIR_PATH")
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
    @classmethod
    def poll(cls, context):
        return PmlsEngine.isr

    def execute(self, context):
        PmlsEngine.main_sqlite2csv(self.filepath, self.directory + "main.csv")
        scene = context.scene
        scene.pmls_op_create_survey_csvs_sqlite = self.filepath      
        scene.pmls_op_create_survey_csvs_csv = (self.directory + "main.csv")      
        return {'FINISHED'}

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

class PmlsCreateSurveyCsvs(bpy.types.Operator):
    """Create survey csvs (main.csv must exist in the directory of sqlite file)"""
    bl_idname = "pmls.create_survey_csvs"
    bl_label = "pmls create survey csvs"
    
    
    @classmethod
    def poll(cls, context):
        scene = context.scene
        return PmlsEngine.isr and os.path.isfile(scene.pmls_op_create_survey_csvs_sqlite) and os.path.isfile(scene.pmls_op_create_survey_csvs_csv)

    def execute(self, context):
        scene = context.scene
        destdir = os.path.dirname(scene.pmls_op_create_survey_csvs_sqlite)
        PmlsEngine.sqlite2csvs(scene.pmls_op_create_survey_csvs_sqlite, scene.pmls_op_create_survey_csvs_csv, destdir + '\\')
        return {'FINISHED'}

class PmlsImportCsv(bpy.types.Operator):
    """Import data from csvs"""
    bl_idname = "pmls.import_csv"
    bl_label = "pmls import csv"
    
    filter_glob = bpy.props.StringProperty(default="*.csv", options={'HIDDEN'})
    directory = bpy.props.StringProperty(subtype="DIR_PATH")
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
    
    @classmethod
    def poll(cls, context):
        scene = context.scene
        return PmlsEngine.isr and (not scene.pmls_op_import_csv_use or os.path.isfile(scene.pmls_op_import_csv_pol))

    def execute(self, context):
        scene = context.scene
        if scene.pmls_op_import_csv_use:
            polfile = scene.pmls_op_import_csv_pol
        else:
            polfile = None
        out = PmlsEngine.get_input(self.filepath, polfile, scene.pmls_op_import_csv_min)
        if not out[0]:
            if out[2]:
                self.report({'ERROR'}, out[2])
            else:                        
                self.report({'ERROR'}, 'Unknown matlab error')
        return {'FINISHED'}

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

class PmlsRegisterAsMesh(bpy.types.Operator):
    """Register to pmls as deformable mesh"""    
    bl_idname = "pmls.register_as_mesh"
    bl_label = "pmls register as mesh"
    hedgehog = bpy.props.StringProperty()
    points = bpy.props.StringProperty()

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if obj is None:
            return False
        if obj.mode != "OBJECT":
            return False
        if obj.type != 'MESH':
            return False
#         if not PmlsObject().pmls_get_type(obj).is_mesh():
#             return False
        if pmls_is_deform_mesh(obj):
            return False
        hdg = context.scene.pmls_op_smooth_by_surface_deform_hdg
        if hdg:
            ot = PmlsObject.pmls_get_type(bpy.data.objects[hdg])
            if not (ot and ot.is_hedgehog()):
                return False
        pnt = context.scene.pmls_op_smooth_by_surface_deform_pnt
        if pnt and bpy.data.objects[pnt].type != 'MESH':
            return False
        return True
                
    def execute(self, context):
        obj = context.active_object
        ot = PmlsObject.pmls_get_type(obj)
        if not ot or not PmlsObject().pmls_get_type(obj).is_mesh():
            obj["pmls_type"] = "mesh"
        obj = PmlsObject(obj)
        hedgehog = None
        if self.hedgehog:
            hedgehog = PmlsObject(context.scene.objects[self.hedgehog])
        anchor = None
        if self.points:
            points = context.scene.objects[self.points]
            if not PmlsObject().pmls_get_type(points).is_mesh():
                points["pmls_type"] = "mesh"
            anchor = PmlsObject(points)
        obj.advance(hedgehog, anchor)
        
        return {'FINISHED'}

class MessageOperator(bpy.types.Operator):
    bl_idname = "error.message"
    bl_label = "Message"
    type = bpy.props.StringProperty()
    message = bpy.props.StringProperty()
 
    def execute(self, context):
        self.report({'INFO'}, self.message)
        print(self.message)
        return {'FINISHED'}
 
    def invoke(self, context, event):
        wm = context.window_manager
        return wm.invoke_popup(self, width=800, height=200)
 
    def draw(self, context):
        self.layout.label("A message has arrived")
        row = self.layout.column(align = True)
        row.prop(self, "type")
        row.prop(self, "message")
        row.operator("error.ok")
 
#
#   The OK button in the error dialog
#
class OkOperator(bpy.types.Operator):
    bl_idname = "error.ok"
    bl_label = "OK"
    def execute(self, context):
        return {'FINISHED'}       
#PANELS

class PmlsPanel(bpy.types.Panel):
    bl_idname = "OBJECT_PT_pmls"
    bl_label = "MATLAB Engine"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'
    bl_category = "Pmls"
    bl_context = "objectmode"

    def draw(self, context):
        layout = self.layout
        col = layout.column(align=True)
        col.label(text="Start/Connect to:")
        names = PmlsEngine.findmatlab()
        if names:
            for n in names:
                col.operator("pmls.connect", text="Connect to: " + n).name = n
        else:
            col.label(text="Nothing to connect to. Install pmls lib or start matlab engine!")
#        col.operator("pmls.start", text="Start new")
        col.separator()
        col.label(text="Stop/Disconnect:")
        col.operator("pmls.stop", text="Stop")
        col.operator("pmls.disconnect", text = "Disconnect " + PmlsEngine.name )
        col.operator("pmls.loadmat", text="Load mat file")

class PmlsMultipleObjectPanel(bpy.types.Panel):
    bl_idname = "OBJECT_PT_pmls_multiple"
    bl_label = "PMLS Objects"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'
    bl_category = "Pmls"
    bl_context = "objectmode"

    def draw(self, context):
        layout = self.layout
        col = layout.column(align=False)
        col.label(text="Save selected:")
        box = col.box()
        col1 = box.column(align=False)
        col1.operator("pmls.savemat", text="Save mat file")
        col.separator()
        col.label(text="Hedgehogs:")
        box = col.box()
        col1 = box.column(align=False)
        col1.operator("pmls.merge_selected_hedges_to_active", text="Merge")
        col1.operator("pmls.separate_turtles", text="Separate")
        col.separator()
        col.label(text="Smooth mesh:")
        box = col.box()
        col1 =  box.column(align=False)
        opprops = col1.operator("pmls.smoot_by_surface_deform", text="Surface deform")
        scene = context.scene
#         opprops.hedgehog = scene.pmls_op_smooth_by_surface_deform_hdg
#         opprops.points = scene.pmls_op_smooth_by_surface_deform_pnt
        opprops.unilap = scene.pmls_op_smooth_by_surface_deform_unilap
        opprops.snaptol = scene.pmls_op_smooth_by_surface_deform_tol
        opprops.to_raycheck = scene.pmls_op_smooth_by_surface_deform_ray
        opprops.voxsiz = scene.pmls_op_smooth_by_surface_deform_vox
#         col1.prop_search(scene, "pmls_op_smooth_by_surface_deform_hdg", 
#                         scene, "objects", text = "Hedgehog:", icon='OBJECT_DATA')
#         col1.prop_search(scene, "pmls_op_smooth_by_surface_deform_pnt", 
#                         scene, "objects", text = "Additional points:", icon='OBJECT_DATA')
        col1.prop(scene, "pmls_op_smooth_by_surface_deform_unilap")
        col1.prop(scene, "pmls_op_smooth_by_surface_deform_tol")
        col1.prop(scene, "pmls_op_smooth_by_surface_deform_ray")
        if scene.pmls_op_smooth_by_surface_deform_ray:
            box = col1.box()
            col2 =  box.column(align=False)
            col2.prop(scene, "pmls_op_smooth_by_surface_deform_vox")
        col.separator()
        col.label(text="Voxelized union:")
        box = col.box()
        col1 =  box.column(align=False)
        opprops = col1.operator("pmls.voxelized_union", text="Union/Remesh by voxelization")
        opprops.voxel_siz = scene.pmls_op_hedgehog_union_vox
        opprops.extend = scene.pmls_op_hedgehog_union_ext
        opprops.deform = scene.pmls_op_voxelized_union_vol
#         opprops.hedgehog = scene.pmls_op_smooth_by_surface_deform_hdg
        opprops.unilap = scene.pmls_op_voxelized_union_unilap
        opprops.premesh = scene.pmls_op_voxelized_union_pre
        col1.prop( scene, "pmls_op_hedgehog_union_vox" )
        col1.prop( scene, "pmls_op_hedgehog_union_ext" )
        col1.prop( scene, "pmls_op_voxelized_union_vol")
        if scene.pmls_op_voxelized_union_vol:
            box = col1.box()
            col2 =  box.column(align=False)
#             col2.prop_search(scene, "pmls_op_smooth_by_surface_deform_hdg", 
#                     scene, "objects", text = "Hedgehog:", icon='OBJECT_DATA')
            col2.prop( scene, "pmls_op_voxelized_union_unilap" )
            col2.prop( scene, "pmls_op_voxelized_union_pre" )
        col.separator()
        col.label(text="Normal union:")
        box = col.box()
        col1 =  box.column(align=False)
        opprops = col1.operator("pmls.normal_union", text="Union")
        opprops.premesh = scene.pmls_op_normal_union_pre
        opprops.tetgen   = scene.pmls_op_hedgehog_union_tetgen
        opprops.tetgen_a = scene.pmls_op_hedgehog_union_tetgen_a
        opprops.tetgen_q = scene.pmls_op_hedgehog_union_tetgen_q
        opprops.tetgen_d = scene.pmls_op_hedgehog_union_tetgen_d
    
        col1.prop( scene, "pmls_op_normal_union_pre" )
        col1.prop( scene, "pmls_op_hedgehog_union_tetgen" )
        if scene.pmls_op_hedgehog_union_tetgen:
            col1.prop( scene, "pmls_op_hedgehog_union_tetgen_a" )
            col1.prop( scene, "pmls_op_hedgehog_union_tetgen_q" )
            col1.prop( scene, "pmls_op_hedgehog_union_tetgen_d" )


        col.separator()
#         col.label(text="Split into two pieces:")
#         box = col.box()
#         col1 =  box.column(align=False)
#         opprops = col1.operator("pmls.split", text="Split:")
#         opprops.selmesh = scene.pmls_op_split_selector
#         col1.prop_search(scene, "pmls_op_split_selector", 
#                         scene, "objects", text = "Selector mesh:", icon='OBJECT_DATA')
#        
#         col.separator()
        col.label(text="Register as deformable mesh:")
        box = col.box()
        col1 =  box.column(align=False)
        opprops = col1.operator("pmls.register_as_mesh", text="Resgister as mesh")
        opprops.hedgehog = scene.pmls_op_smooth_by_surface_deform_hdg
        opprops.points = scene.pmls_op_smooth_by_surface_deform_pnt
        col1.prop_search(scene, "pmls_op_smooth_by_surface_deform_hdg", 
                        scene, "objects", text = "Hedgehog:", icon='OBJECT_DATA')
        col1.prop_search(scene, "pmls_op_smooth_by_surface_deform_pnt", 
                        scene, "objects", text = "Anchor points:", icon='OBJECT_DATA')
       

#         col.separator()
#         col.label(text="Create volumetric mesh:")
#         box = col.box()
#         col1 =  box.column(align=False)
#         col1.operator("pmls.create_vol_mesh", text="Create")
        
        
class PmlsSqlitePanel(bpy.types.Panel):
    bl_idname = "OBJECT_PT_pmls_sqlite"
    bl_label = "Topodroid sqlite"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'
    bl_category = "Pmls"
    bl_context = "objectmode"

    def draw(self, context):
        layout = self.layout
#         obj = context.active_object
        scn = context.scene
        col = layout.column(align=False)
        
        col.label(text="Main csv:")
        col.operator("pmls.create_main_csv", text="Create")
        col.label(text="Survey csvs:")
        box = col.box()
        col1 = box.column(align=False)
        col1.prop(scn, "pmls_op_create_survey_csvs_sqlite")
        col1.prop(scn, "pmls_op_create_survey_csvs_csv")
        col1.operator("pmls.create_survey_csvs", text="Create")
        col.separator()
        col.label(text="Import csv")
        box = col.box()
        col1 = box.column(align=False)
        col1.prop(scn, "pmls_op_import_csv_use")
        if scn.pmls_op_import_csv_use:
            col1.prop(scn, "pmls_op_import_csv_pol")
        col1.prop(scn, "pmls_op_import_csv_min")
        col1.operator("pmls.import_csv", text="Import")
        
        
class PmlsObjectPanel(bpy.types.Panel):
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'
    bl_category = "Pmls"
    bl_context = "mesh_edit"
    
    @classmethod
    def poll(cls, context):
        if not PmlsEngine.isr:
            return False
        obj = context.active_object
        if obj is None:
            return False
        if obj.type != 'MESH':
            return False
        if "pmls_type" not in obj.keys():
            return False
        return cls._poll( context )
    
    def editdisplay(self, context, col0):
        col0.label(text="Edit:")
        box = col0.box()
        col = box.column(align=True)
        col.operator("pmls.copy", text="Copy").simple = context.scene.pmls_edit_simple
        col.operator("pmls.split", text="Split").simple = context.scene.pmls_edit_simple
        col.operator("pmls.cut", text="Cut").simple = context.scene.pmls_edit_simple
        col.operator("pmls.delete", text="Delete").simple = context.scene.pmls_edit_simple
        return col
    

class PmlsDeformMeshPanel(PmlsObjectPanel):    
    bl_idname = "OBJECT_PT_pmls_deform_mesh"
    bl_label = "Deformable mesh"

    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "deform_mesh"

    def draw(self, context):
        layout = self.layout
        col0 = layout.column(align=False)
        col = self.editdisplay(context, col0)
        col.prop(context.scene, "pmls_edit_simple")
        
        col0.separator()
#         col = col0
#         col.label(text="Deform mesh:")
#         box = col.box()
#         col1 =  box.column(align=False)
#         opprops = col1.operator("pmls.smoot_by_surface_deform", text="Surface deform")
#         scene = context.scene
#         obj = context.active_object
#         obj = PmlsObject(obj)


#         h = obj.hedgehog()
#         opprops.hedgehog = ""
#         if h:
#             opprops.hedgehog = obj.hedgehog().object.name
#         h = obj.anchor()
#         opprops.points = ""
#         if h:
#             opprops.points = obj.anchor().object.name


#         opprops.snaptol = scene.pmls_op_smooth_by_surface_deform_tol
#         opprops.voxsiz = scene.pmls_op_smooth_by_surface_deform_vox
#         col1.prop(scene, "pmls_op_smooth_by_surface_deform_tol") 
#         col1.prop(scene, "pmls_op_smooth_by_surface_deform_vox")
#         col.separator()
        col = col0
        col.label(text="Map points to mesh:")
        box = col.box()
        col1 =  box.column(align=False)
        col1.operator("pmls.map_points_to_mesh", text="Select mapped")
        
   

class PmlsHedgehogPanelBase(PmlsObjectPanel):
    
    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "hedgehog"
    
    def drawdisplay(self, context, col0):
        obj = context.active_object
        col0.label(text="Display:")
        box = col0.box()
        col = box.column(align=True)
#        col.operator("pmls.recalculate_turtles", text="Recalculate turtles")
#        col.separator()
#        col.label(text="Stations")
#        col.operator("pmls.deselect_all_stations", text="Deselect all")
#        col.operator("pmls.hide_selected_stations", text="Hide selected")
#        col.operator("pmls.hide_unselected_stations", text="Hide unselected")
#        col.operator("pmls.reveal_stations", text="Reveal all")
#        col.separator()
#        col.prop( obj.users_scene[0], "pmls_disp_base" )

        col.prop( obj.users_scene[0], "pmls_disp_pnts" )
        col.prop( obj.users_scene[0], "pmls_disp_zeroshots" )
        col.prop( obj.users_scene[0], "pmls_disp_edges" )
        return col

    def draw(self, context):
        layout = self.layout
        col0 = layout.column(align=False)
        self.drawdisplay(context, col0)
        col0.separator()
        self.editdisplay(context, col0)
        col0.separator()
        col0.label(text="Extend by visibility:")
        box = col0.box()
        col = box.column(align=True)
        col.operator("pmls.extend_hedgehog", text="Extend")
        

class PmlsHedgehogPanel(PmlsHedgehogPanelBase):
    bl_idname = "OBJECT_PT_pmls_hedgehog"
    bl_label = "Hedgehog"
    
    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "hedgehog"
    
#     def drawdisplay(self, context, col0):
#         obj = context.active_object
#         col0.label(text="Display:")
#         box = col0.box()
#         col = box.column(align=True)
#         col.operator("pmls.recalculate_turtles")
#         col.prop( obj.users_scene[0], "pmls_disp_base" )
#         col.prop( obj.users_scene[0], "pmls_disp_pnts" )
#         col.prop( obj.users_scene[0], "pmls_disp_edges" )
#         return col

#     def draw(self, context):
#         layout = self.layout
#         col0 = layout.column(align=False)
#         self.drawdisplay(context, col0)        

class PmlsTurtlePanel(PmlsHedgehogPanelBase):
    bl_idname = "OBJECT_PT_pmls_turtle"
    bl_label = "Turtle"
    
    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "turtle"
    
    def drawdisplay(self, context, col0):
        col = super().drawdisplay(context, col0)
        obj = context.active_object
        col.prop( obj.users_scene[0], "pmls_disp_faces" )
        col.separator()
        col.operator("pmls.clear_turtles", text="Clear turtle")
        return col
        
        

 
class PmlsExtendedHedgehogPanelBase(PmlsHedgehogPanelBase):
    def drawdisplay(self, context, col0):
        col = super().drawdisplay(context, col0)
        obj = context.active_object
        col.prop( obj.users_scene[0], "pmls_disp_extedges" )
        return col


    def draw(self, context):
        layout = self.layout
        col0 = layout.column(align=False)
        self.drawdisplay(context, col0)        
        obj = context.active_object
        col0.separator()
        self.editdisplay(context, col0)
        col0.separator()

        col0.label(text="Downdate to hedgehog:")
        box = col0.box()
        col = box.column(align=True)
        col.operator("pmls.downdate_ehedgehog", text="Downdate").todel = obj.users_scene[0].pmls_op_ehedgehog_downdate
        col.prop( obj.users_scene[0], "pmls_op_ehedgehog_downdate" )

        col0.label(text="Union by voxelization:")
        box = col0.box()
        col = box.column(align=True)
        opprop = col.operator("pmls.hedgehog_union", text="Create")
        opprop.voxel_siz = obj.users_scene[0].pmls_op_hedgehog_union_vox
        opprop.extend = obj.users_scene[0].pmls_op_hedgehog_union_ext
        col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_vox" )
        col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_ext" )

        col0.label(text="Union:")
        box = col0.box()
        col = box.column(align=True)
        opprop = col.operator("pmls.hedgehog_union_alec", text="Create")
        opprop.tetgen   = obj.users_scene[0].pmls_op_hedgehog_union_tetgen
        opprop.tetgen_a = obj.users_scene[0].pmls_op_hedgehog_union_tetgen_a
        opprop.tetgen_q = obj.users_scene[0].pmls_op_hedgehog_union_tetgen_q
        opprop.tetgen_d = obj.users_scene[0].pmls_op_hedgehog_union_tetgen_d
        col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_tetgen" )
        if obj.users_scene[0].pmls_op_hedgehog_union_tetgen:
            col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_tetgen_a" )
            col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_tetgen_q" )
            col.prop( obj.users_scene[0], "pmls_op_hedgehog_union_tetgen_d" )

class PmlsExtendedHedgehogPanel(PmlsExtendedHedgehogPanelBase):
    bl_idname = "OBJECT_PT_pmls__extended_hedgehog"
    bl_label = "Extended hedgehog"

    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "ehedgehog"

class PmlsExtendedTurtlePanel(PmlsExtendedHedgehogPanelBase):
    bl_idname = "OBJECT_PT_pmls__extended_turtle"
    bl_label = "Extended turtle"

    def drawdisplay(self, context, col0):
        col = super().drawdisplay(context, col0)
        obj = context.active_object
        col.prop( obj.users_scene[0], "pmls_disp_faces" )
        col.separator()
        col.operator("pmls.clear_turtles", text="Clear turtle")
        return col

    @classmethod
    def _poll(cls, context):
        return context.active_object["pmls_type"] == "eturtle"

def get_pmls_disp_base(self):
    obj = bpy.context.active_object
    return obj["disp_base"]


def set_pmls_disp_base(self, value):
    obj = bpy.context.active_object
    if obj["disp_base"] != value:
        obj["disp_base"] = value
        bpy.ops.pmls.updatedisplay()
        
def get_pmls_disp_pnts(self):
    obj = bpy.context.active_object
    return obj["disp_pnts"]


def set_pmls_disp_pnts(self, value):
    obj = bpy.context.active_object
    if obj["disp_pnts"] != value:
        obj["disp_pnts"] = value
        bpy.ops.pmls.updatedisplay()
        
def get_pmls_disp_zeroshots(self):
    obj = bpy.context.active_object
    return obj["disp_zeroshots"]


def set_pmls_disp_zeroshots(self, value):
    obj = bpy.context.active_object
    if obj["disp_zeroshots"] != value:
        obj["disp_zeroshots"] = value
        bpy.ops.pmls.updatedisplay()
        
def get_pmls_disp_edges(self):
    obj = bpy.context.active_object
    return obj["disp_edges"]


def set_pmls_disp_edges(self, value):
    obj = bpy.context.active_object
    if obj["disp_edges"] != value:
        obj["disp_edges"] = value
        bpy.ops.pmls.updatedisplay()

def get_pmls_disp_faces(self):
    obj = bpy.context.active_object
    return obj["disp_faces"]


def set_pmls_disp_faces(self, value):
    obj = bpy.context.active_object
    if obj["disp_faces"] != value:
        obj["disp_faces"] = value
        bpy.ops.pmls.updatedisplay()
        
def get_pmls_disp_extedges(self):
    obj = bpy.context.active_object
    return obj["disp_extedges"]


def set_pmls_disp_extedges(self, value):
    obj = bpy.context.active_object
    if obj["disp_extedges"] != value:
        obj["disp_extedges"] = value
        bpy.ops.pmls.updatedisplay()
        



# Register and add to the file selector
def register():
    bpy.types.Scene.pmls_disp_base = bpy.props.BoolProperty(name="Display stations",
    get=get_pmls_disp_base, set=set_pmls_disp_base)

    bpy.types.Scene.pmls_disp_pnts = bpy.props.BoolProperty(name="Display shots",
    get=get_pmls_disp_pnts, set=set_pmls_disp_pnts)

    bpy.types.Scene.pmls_disp_zeroshots = bpy.props.BoolProperty(name="Display zeroshots",
    get=get_pmls_disp_zeroshots, set=set_pmls_disp_zeroshots)

    bpy.types.Scene.pmls_disp_edges = bpy.props.BoolProperty(name="Display edges",
    get=get_pmls_disp_edges, set=set_pmls_disp_edges)

    bpy.types.Scene.pmls_disp_extedges = bpy.props.BoolProperty(name="Display extended edges",
    get=get_pmls_disp_extedges, set=set_pmls_disp_extedges)

    bpy.types.Scene.pmls_disp_faces = bpy.props.BoolProperty(name="Display faces",
    get=get_pmls_disp_faces, set=set_pmls_disp_faces)
    
    bpy.types.Scene.pmls_op_ehedgehog_downdate = bpy.props.BoolProperty(name="Delete extended edges", default=True)

    bpy.types.Scene.pmls_op_create_survey_csvs_csv = bpy.props.StringProperty(name="Main csv:", subtype="FILE_PATH")
    bpy.types.Scene.pmls_op_create_survey_csvs_sqlite = bpy.props.StringProperty(name="Sqlite:", subtype="FILE_PATH")

    bpy.types.Scene.pmls_op_import_csv_use = bpy.props.BoolProperty(name="Use poligon file", default=False)
    bpy.types.Scene.pmls_op_import_csv_pol = bpy.props.StringProperty(name="Poligon file:", subtype="FILE_PATH")
    bpy.types.Scene.pmls_op_import_csv_min = bpy.props.IntProperty(name="Min splay/station:", default=20, soft_min=0)
    
    bpy.types.Scene.pmls_op_hedgehog_union_vox = bpy.props.FloatProperty(
        name="Voxel size (cm):", default=3.0, step=5, min=0.000001, soft_min=1.0, soft_max=1000.0, subtype='DISTANCE')
    bpy.types.Scene.pmls_op_hedgehog_union_ext = bpy.props.FloatProperty(
        name="Thin volume (voxel):", default=1.0, step=5, min=0.0, soft_min=0.0, soft_max=10.0, subtype='DISTANCE')

    bpy.types.Scene.pmls_op_hedgehog_union_tetgen = bpy.props.BoolProperty(name="Remesh before union", description="Remesh increases the number of triangles, but the mesh will be nicer.", default=True)
    bpy.types.Scene.pmls_op_hedgehog_union_tetgen_a = bpy.props.FloatProperty(
        name="Max volume of tetrahedra (m3)", description="Tetgen command line parameter -a.",
        default=0.5, step=0.001, min=0.0000001, soft_min=0.0000001, soft_max=100.0, subtype='UNSIGNED', unit='VOLUME')
    bpy.types.Scene.pmls_op_hedgehog_union_tetgen_q = bpy.props.FloatProperty(
        name="Max radius-edge ratio", description="First value of tetgen command line parameter -q.",
        default=2.0, step=0.001, min=1.0, soft_min=1.0, soft_max=100.0, subtype='UNSIGNED')
    bpy.types.Scene.pmls_op_hedgehog_union_tetgen_d = bpy.props.FloatProperty(
        name="Min dihedral angle (deg)", description="Second value of tetgen command line parameter -q.",
        default=0.0, step=5.0, min=0.0, soft_min=0.0, soft_max=70, subtype='UNSIGNED')


    bpy.types.Scene.pmls_op_smooth_by_surface_deform_hdg = bpy.props.StringProperty()
    bpy.types.Scene.pmls_op_smooth_by_surface_deform_pnt = bpy.props.StringProperty()

    bpy.types.Scene.pmls_op_smooth_by_surface_deform_unilap = bpy.props.BoolProperty(name="Uniform laplacian", description="If true uniform weights will be used instead of edge lenghts. Less conservative deformation.", default=True)
    bpy.types.Scene.pmls_op_smooth_by_surface_deform_tol = bpy.props.FloatProperty(
        name="Snap tolerance (cm):", default=5.0, step=5, min=0.1, soft_min=0.1, soft_max=10000.0, subtype='DISTANCE')
    bpy.types.Scene.pmls_op_smooth_by_surface_deform_vox = bpy.props.FloatProperty(
        name="Voxel size for ray check (cm):", default=7.0, step=5, min=0.000001, soft_min=1.0, soft_max=1000.0, subtype='DISTANCE')
    
    bpy.types.Scene.pmls_op_voxelized_union_vol = bpy.props.BoolProperty(name="Volumetric deform", default=True)
    bpy.types.Scene.pmls_op_voxelized_union_unilap = bpy.props.BoolProperty(name="Uniform laplacian", description="If true uniform weights will be used instead of edge lenghts. Less conservative deformation.", default=True)
    bpy.types.Scene.pmls_op_voxelized_union_pre = bpy.props.BoolProperty(name="Remesh before deform", description="If true remesh done before and after the deform else only after", default=True)

    bpy.types.Scene.pmls_op_normal_union_pre = bpy.props.BoolProperty(name="Meshfix before union", description="If true meshfix is done for input to guarantee success", default=True)

    bpy.types.Scene.pmls_op_smooth_by_surface_deform_ray = bpy.props.BoolProperty(name="Ray check", description="If true constraint 2 will be guaranteed", default=True)

    bpy.types.Scene.pmls_op_split_selector = bpy.props.StringProperty()

    bpy.types.Scene.pmls_edit_simple = bpy.props.BoolProperty(name="Simple mode", description="Faster, but less robus", default=True)
    
    bpy.utils.register_class(PmlsStart)
    bpy.utils.register_class(PmlsStop)
    bpy.utils.register_class(PmlsConnect)
    bpy.utils.register_class(PmlsDisconnect)
    bpy.utils.register_class(PmlsLoadMat)
    bpy.utils.register_class(PmlsSaveMat)
    bpy.utils.register_class(PmlsUpdateDisplay)
    bpy.utils.register_class(PmlsDowdateEhedgehog)
    bpy.utils.register_class(PmlsRecalculateTurtles)
    bpy.utils.register_class(PmlsHideSelectedStations)
    bpy.utils.register_class(PmlsHideUnselectedStations)
    bpy.utils.register_class(PmlsRevealStations)
    bpy.utils.register_class(PmlsClearTurtles)
    bpy.utils.register_class(PmlsDeselectAllStations)
    bpy.utils.register_class(PmlsExtendHedgehog)
    bpy.utils.register_class(PmlsMergeHedgehogs)
    bpy.utils.register_class(PmlsCreateMainCsv)
    bpy.utils.register_class(PmlsCreateSurveyCsvs)
    bpy.utils.register_class(PmlsImportCsv)
    bpy.utils.register_class(PmlsHedgehogUnion)
    bpy.utils.register_class(PmlsHedgehogUnionAlec)
    bpy.utils.register_class(PmlsSurfaceDeform)
    bpy.utils.register_class(PmlsSeparateTurtles)
    bpy.utils.register_class(PmlsVoxelizedUnion)
    bpy.utils.register_class(PmlsCreateVolMesh)
    bpy.utils.register_class(PmlsNormalUnion)
    bpy.utils.register_class(PmlsRegisterAsMesh)
    bpy.utils.register_class(PmlsSplit)
    bpy.utils.register_class(PmlsCopy)
    bpy.utils.register_class(PmlsCut)
    bpy.utils.register_class(PmlsDelete)
    bpy.utils.register_class(PmlsFill)
    bpy.utils.register_class(PmlsMapPointsToMesh)

    bpy.utils.register_class(MessageOperator)
    bpy.utils.register_class(OkOperator)


    bpy.utils.register_class(PmlsPanel)
    bpy.utils.register_class(PmlsHedgehogPanel)
    bpy.utils.register_class(PmlsExtendedHedgehogPanel)
    bpy.utils.register_class(PmlsTurtlePanel)
    bpy.utils.register_class(PmlsExtendedTurtlePanel)
    bpy.utils.register_class(PmlsMultipleObjectPanel)
    bpy.utils.register_class(PmlsSqlitePanel)
    bpy.utils.register_class(PmlsDeformMeshPanel)
    

def unregister():
    bpy.utils.unregister_class(PmlsStart)
    bpy.utils.unregister_class(PmlsStop)
    bpy.utils.unregister_class(PmlsConnect)
    bpy.utils.unregister_class(PmlsDisconnect)
    bpy.utils.unregister_class(PmlsLoadMat)
    bpy.utils.unregister_class(PmlsSaveMat)
    bpy.utils.unregister_class(PmlsUpdateDisplay)
    bpy.utils.unregister_class(PmlsDowdateEhedgehog)
    bpy.utils.unregister_class(PmlsRecalculateTurtles)
    bpy.utils.unregister_class(PmlsHideSelectedStations)
    bpy.utils.unregister_class(PmlsHideUnselectedStations)
    bpy.utils.unregister_class(PmlsRevealStations)
    bpy.utils.unregister_class(PmlsClearTurtles)
    bpy.utils.unregister_class(PmlsDeselectAllStations)
    bpy.utils.unregister_class(PmlsExtendHedgehog)
    bpy.utils.unregister_class(PmlsMergeHedgehogs)
    bpy.utils.unregister_class(PmlsCreateMainCsv)
    bpy.utils.unregister_class(PmlsCreateSurveyCsvs)
    bpy.utils.unregister_class(PmlsImportCsv)
    bpy.utils.unregister_class(PmlsHedgehogUnionAlec)
    bpy.utils.unregister_class(PmlsHedgehogUnion)
    bpy.utils.unregister_class(PmlsSurfaceDeform)
    bpy.utils.unregister_class(PmlsSeparateTurtles)
    bpy.utils.unregister_class(PmlsVoxelizedUnion)
    bpy.utils.unregister_class(PmlsCreateVolMesh)
    bpy.utils.unregister_class(PmlsNormalUnion)
    bpy.utils.unregister_class(PmlsRegisterAsMesh)
    bpy.utils.unregister_class(PmlsSplit)
    bpy.utils.unregister_class(PmlsCopy)
    bpy.utils.unregister_class(PmlsCut)
    bpy.utils.unregister_class(PmlsDelete)
    bpy.utils.unregister_class(PmlsFill)
    bpy.utils.unregister_class(PmlsMapPointsToMesh)

    
    bpy.utils.unregister_class(MessageOperator)
    bpy.utils.unregister_class(OkOperator)
   
    
    bpy.utils.unregister_class(PmlsPanel)
    bpy.utils.unregister_class(PmlsHedgehogPanel)
    bpy.utils.unregister_class(PmlsExtendedHedgehogPanel)
    bpy.utils.unregister_class(PmlsTurtlePanel)
    bpy.utils.unregister_class(PmlsExtendedTurtlePanel)
    bpy.utils.unregister_class(PmlsMultipleObjectPanel)
    bpy.utils.unregister_class(PmlsSqlitePanel)
    bpy.utils.unregister_class(PmlsDeformMeshPanel)
    

if __name__ == "__main__":
    register()
    
