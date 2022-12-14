
from dataclasses import dataclass
import math
import random 


bound_x = 640 
bound_y = 480 
tile_size = 16 
# returns f-22 represenation for decimal number in string format 
# for testing binner/rasterizer and fragshader
import struct
def get_fp_32(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', num))
def convert_to_fp22(fp32): 
    s = fp32[0];
    e8 = fp32[1:9];
    zf = 1 if e8 == "00000000" else 0 
    m23 = fp32[9:]
    assert (len(e8)==8 and len(m23) == 23)
    temp = format( int(m23[:len(m23)-1-7],2) + int(m23[-8]), '#018b') [2:]

    carry =  temp[0]
    m15 = temp[1:] 
    assert (len(m15)==15)
    e8d = format((int(e8,2) - 112 + int(carry)), '#011b')[2:] # -127+15 + carry
 
    if (int(zf)|int(e8d[0])):  
        e5 = "00000"; 
    else : 
        e5 = e8d[-5:] 
    result = ""
    result+= s
    result+= str(e5)
    result+= str(0 if (int(zf) + int(e8d[0])) >=1 else 1 )
    result+= str(m15 )   
    assert len(result) == 22
    return result 

def get_dec_from_fp22(fp): 
    sign = 1 if int(fp[0])==0 else -1
    exp = fp[1:6] 
    integer = fp[6]
    mantissa = fp[7:]
    exp = int(exp, 2) - 15 
    mantissa = int(mantissa, 2) / 2.**(len(mantissa) ) + int(integer)
    return 2**exp * mantissa * sign 

class Vec3f:  
    def __init__(self, x= 0.0, y = 0.0 , z = 0.0, randomize = False, bx = bound_x, by=bound_y, bz=1.0) -> None: 
        if not randomize:
            self.x : float = x 
            self.y : float = y 
            self.z : float = z 
        else: 
            self.x = random.random() * bx
            self.y = random.random() * by 
            self.z = random.random() * bz
    def __repr__(self) -> str:
        return f"x: {self.x} y: {self.y} z: {self.z}"

class Edge: 
    def __init__(self,vtx0 , vtx1) -> None:
        self.a = vtx0.y - vtx1.y
        self.b = vtx1.x - vtx0.x
        self.c = vtx0.x * vtx1.y - vtx1.x*vtx0.y
    def normalize(self) :  
        norm_factor = 1/(abs(self.a) + abs(self.b))
        self.a = self.a * norm_factor
        self.b = self.b * norm_factor
        self.c = self.c * norm_factor
@dataclass 
class Triangle:
    vtx0_pos : Vec3f = Vec3f(randomize=True)  
    vtx1_pos : Vec3f = Vec3f(randomize=True) 
    vtx2_pos : Vec3f = Vec3f(randomize=True)  
    vtx0_col : Vec3f = Vec3f(bx=1.0, by=1.0)   # rgb 
    vtx1_col : Vec3f = Vec3f(bx=1.0, by=1.0) 
    vtx2_col : Vec3f = Vec3f(bx=1.0, by=1.0)  
    e0 :Edge = Edge(vtx0_pos , vtx2_pos) 
    e1 :Edge = Edge(vtx2_pos , vtx1_pos) 
    e2 :Edge = Edge(vtx1_pos , vtx0_pos)  
    def get_tile_min_x(self):  
        return math.floor(min(self.vtx0_pos.x ,self.vtx1_pos.x  ,self.vtx2_pos.x)/tile_size)*tile_size
    def get_tile_min_y(self): 
        return math.floor(min(self.vtx0_pos.y ,self.vtx1_pos.y  ,self.vtx2_pos.y)/tile_size)*tile_size
    def get_tile_max_x(self):  
        return math.floor(max(self.vtx0_pos.x ,self.vtx1_pos.x  ,self.vtx2_pos.x)/tile_size)*tile_size
    def get_tile_max_y(self):  
        return math.floor(max(self.vtx0_pos.y ,self.vtx1_pos.y  ,self.vtx2_pos.y)/tile_size)*tile_size
    def get_tile_step_x(self): 
        return -(int(self.get_tile_min_x()/tile_size) - int(self.get_tile_max_x()/tile_size))+1
    def get_tile_step_y(self):   
        return -(int(self.get_tile_min_y()/tile_size) - int(self.get_tile_max_y()/tile_size))+1
    def print_triangle_info(self):  
        #print vertex info 
        print("PRINTING Vertex Info")
        print(f"Vertex 0 x({self.vtx0_pos.x}): 22'b{convert_to_fp22(get_fp_32(self.vtx0_pos.x))}  , y({self.vtx0_pos.y}): 22'b{convert_to_fp22(get_fp_32(self.vtx0_pos.y))}  , z({self.vtx0_pos.z}): 22'b{convert_to_fp22(get_fp_32(self.vtx0_pos.z))}")
        print(f"Vertex 1 x({self.vtx1_pos.x}): 22'b{convert_to_fp22(get_fp_32(self.vtx1_pos.x))}  , y({self.vtx1_pos.y}): 22'b{convert_to_fp22(get_fp_32(self.vtx1_pos.y))}  , z({self.vtx1_pos.z}): 22'b{convert_to_fp22(get_fp_32(self.vtx1_pos.z))}")
        print(f"Vertex 2 x({self.vtx2_pos.x}): 22'b{convert_to_fp22(get_fp_32(self.vtx2_pos.x))}  , y({self.vtx2_pos.y}): 22'b{convert_to_fp22(get_fp_32(self.vtx2_pos.y))}  , z({self.vtx2_pos.z}): 22'b{convert_to_fp22(get_fp_32(self.vtx2_pos.z))}")
        # printing edges 
        print("PRINTING Edge Info") 
        print(f"Edge 0 a({self.e0.a}): 22'b{convert_to_fp22(get_fp_32(self.e0.a))}  , b({self.e0.b}): 22'b{convert_to_fp22(get_fp_32(self.e0.b))}  , c({self.e0.c}): 22'b{convert_to_fp22(get_fp_32(self.e0.c))}")
        print(f"Edge 1 a({self.e1.a}): 22'b{convert_to_fp22(get_fp_32(self.e1.a))}  , b({self.e1.b}): 22'b{convert_to_fp22(get_fp_32(self.e1.b))}  , c({self.e1.c}): 22'b{convert_to_fp22(get_fp_32(self.e1.c))}")
        print(f"Edge 2 a({self.e2.a}): 22'b{convert_to_fp22(get_fp_32(self.e2.a))}  , b({self.e2.b}): 22'b{convert_to_fp22(get_fp_32(self.e2.b))}  , c({self.e2.c}): 22'b{convert_to_fp22(get_fp_32(self.e2.c))}")
        #printing tile info 
        print("PRINTING Tile Info")  
        print(f"Tile Size({tile_size}): 22'b{convert_to_fp22(get_fp_32(tile_size))}")
        print(f"Tile start_x({self.get_tile_min_x ()}): 22'b{convert_to_fp22(get_fp_32(self.get_tile_min_x ()))}")
        print(f"Tile start_y({self.get_tile_min_y ()}): 22'b{convert_to_fp22(get_fp_32(self.get_tile_min_y ()))}")
        print(f"Tile x steps({self.get_tile_step_x()}): 22'b{convert_to_fp22(get_fp_32(self.get_tile_step_x()))}")
        print(f"Tile y steps({self.get_tile_step_y()}): 22'b{convert_to_fp22(get_fp_32(self.get_tile_step_y()))}")
        




@dataclass 
class Vec2f: 
    x : float = 0.0
    y : float = 0.0 

corner_offsets = [Vec2f(0,0), Vec2f(tile_size, 0) , Vec2f(0, tile_size), Vec2f(tile_size, tile_size)]
def get_offset_index(e : Edge):
    if (e.b >= 0) : 
        if (e.a >= 0):
            return  3
        else: 
            return  2
    else: 
        if (e.a >= 0): 
            return  1
        else: 
            return  0 

    pass
def bin_triangle(prim : Triangle) :  
    tile_shader,tile_raster, tile_discard = [] , [] , []
    prim.e0.normalize() 
    prim.e1.normalize() 
    prim.e2.normalize()  

    tr0 = get_offset_index(prim.e0)
    tr1 = get_offset_index(prim.e1)
    tr2 = get_offset_index(prim.e2)
    ta0 = 3- tr0
    ta1 = 3- tr1
    ta2 = 3- tr2
    print(f"tr0 {tr0},tr1 {tr1},tr2 {tr2} ")
    print(f"ta0 {ta0},ta1 {ta1},ta2 {ta2} ")
    # loop 
    tile_x = prim.get_tile_min_x() 
    tile_y = prim.get_tile_min_y()  
    for i in range (prim.get_tile_step_y()) : 
        for j in range (prim.get_tile_step_x()): 
            # calculate edge function of tr 
            edgeFuncTR0 = prim.e0.c + prim.e0.a * (corner_offsets[tr0].x + tile_x) + (prim.e0.b * (corner_offsets[tr0].y + tile_y))
            edgeFuncTR1 = prim.e1.c + prim.e1.a * (corner_offsets[tr1].x + tile_x) + (prim.e1.b * (corner_offsets[tr1].y + tile_y)) 
            edgeFuncTA0 = prim.e0.c + prim.e0.a * (corner_offsets[ta0].x + tile_x) + (prim.e0.b * (corner_offsets[ta0].y + tile_y))
            edgeFuncTA1 = prim.e1.c + prim.e1.a * (corner_offsets[ta1].x + tile_x) + (prim.e1.b * (corner_offsets[ta1].y + tile_y))
            edgeFuncTA2 = prim.e2.c + prim.e2.a * (corner_offsets[ta2].x + tile_x) + (prim.e2.b * (corner_offsets[ta2].y + tile_y))
            edgeFuncTR2 = prim.e2.c + prim.e2.a * (corner_offsets[tr2].x + tile_x) + (prim.e2.b * (corner_offsets[tr2].y + tile_y))
            print(f"TR edge functions for x: {tile_x}, y:{tile_y} ,tr0: {edgeFuncTR0}, tr1: {edgeFuncTR1}, tr2{edgeFuncTR2} ")
            if (edgeFuncTR0<0 or edgeFuncTR1<0 or edgeFuncTR2<0):  
                print(f"Tile x: {tile_x}, y:{tile_y} discarded!")
                tile_discard.append([tile_x, tile_y])
                pass
            elif (edgeFuncTA0<0 or edgeFuncTA1<0 or edgeFuncTA2<0):  
                print(f"Tile x: {tile_x}, y:{tile_y} sent to raster!")
                tile_raster.append([tile_x, tile_y])
            else:
                print(f"Tile x: {tile_x}, y:{tile_y} sent to frag_shader!")
                tile_shader.append([tile_x, tile_y])
            tile_x += tile_size
        tile_x = prim.get_tile_min_x()
        tile_y += tile_size
    return tile_shader, tile_raster , tile_discard
import matplotlib.pyplot as plt 
from matplotlib.patches import Polygon, Rectangle
import numpy as np
from matplotlib.patches import Patch
def draw_triangle(tri : Triangle, tile_shader, tile_raster, tile_discard): 
    t_shader = np.array (tile_shader)
    t_raster = np.array (tile_raster)
    t_discard = np.array (tile_discard)
    triangle = np.array([[tri.vtx0_pos.x,tri.vtx0_pos.y ],[tri.vtx1_pos.x,tri.vtx1_pos.y ] ,[tri.vtx2_pos.x,tri.vtx2_pos.y ]])
    fig, ax = plt.subplots()
    ax.set_aspect("equal")
    tr = Polygon(triangle, color="blue")  #red : discard , yellow : raster, green: Totally accept
    ax.add_patch(tr) 
    for tile in t_shader: 
        pol = Rectangle(tile ,tile_size, tile_size, color="green")
        ax.add_patch(pol)
    for tile in t_raster: 
        pol = Rectangle(tile ,tile_size, tile_size, color="yellow",alpha=0.5)
        ax.add_patch(pol)
    for tile in t_discard: 
        pol = Rectangle(tile ,tile_size, tile_size, color="red")
        ax.add_patch(pol)
    
    ax.relim()
    ax.autoscale_view()

    legend_elements = [Patch(facecolor='green',label='accepted'), Patch(facecolor='yellow',label='overlap'), Patch(facecolor='red',label='rejected')]
    plt.legend(handles=legend_elements)
    plt.show()

    pass
