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
    def __init__(self, x= 0.0, y = 0.0 , z = 0.0, randomize = True, bx = bound_x, by=bound_y, bz=1.0) -> None: 
        if not randomize:
            self.x : float = x 
            self.y : float = y 
            self.z : float = z 
        else: 
            self.x = random.random() * bx
            self.y = random.random() * by 
            self.z = random.random() * bz
    
class Edge: 
    def __init__(self,vtx0 , vtx1) -> None:
        self.a = vtx0.y - vtx1.y
        self.b = vtx1.x - vtx0.x
        self.c = -(self.a*vtx0.x + self.b*vtx0.y)
    def normalize(self) :  
        norm_factor = 1/(abs(self.a) + abs(self.b))
        self.a = self.a * norm_factor
        self.b = self.b * norm_factor
        self.c = self.c * norm_factor
@dataclass 
class Triangle:
    vtx0_pos : Vec3f = Vec3f()  
    vtx1_pos : Vec3f = Vec3f() 
    vtx2_pos : Vec3f = Vec3f()  
    vtx0_col : Vec3f = Vec3f(bx=1.0, by=1.0)   # rgb 
    vtx1_col : Vec3f = Vec3f(bx=1.0, by=1.0) 
    vtx2_col : Vec3f = Vec3f(bx=1.0, by=1.0)  
    e0 :Edge = Edge(vtx2_pos , vtx1_pos) 
    e1 :Edge = Edge(vtx0_pos , vtx2_pos) 
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
        return -(int(self.get_tile_min_x()/tile_size) - int(self.get_tile_max_x()/tile_size))
    def get_tile_step_y(self):   
        return -(int(self.get_tile_min_y()/tile_size) - int(self.get_tile_max_y()/tile_size))
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
        
        


#tr = Triangle()  
#tr.print_triangle_info()
print(get_dec_from_fp22("0101101011000000000000"))
vtx0 = Vec3f(272.73203211990284,91.29683482394742 , 0.5678275245865031, randomize=False)
vtx1 = Vec3f(554.1350553918379,335.45663233380793, 0.5678275245865031, randomize=False) 
e = Edge(vtx0, vtx1)
e.normalize() 
print(e.a)
print(e.b)
print(e.c)

#PRINTING Vertex Info 
#Vertex 0 x(519.4523698477817): 22'b0110001000000111011101  , y(43.98934897169747): 22'b0101001010111111110101  , z(0.4740296407027099): 22'b0011011111001010110100
#Vertex 1 x(554.1350553918379): 22'b0110001000101010001001  , y(335.45663233380793): 22'b0101111010011110111010  , z(0.7742591991054101): 22'b0011101100011000110110
#Vertex 2 x(272.73203211990284): 22'b0101111000100001011110  , y(91.29683482394742): 22'b0101011011011010011000  , z(0.5678275245865031): 22'b0011101001000101011101

#PRINTING Edge Info
#Edge 0 a(-244.1597975098605): 22'b1101101111010000101001  , b(281.40302327193507): 22'b0101111000110010110100  , c(40898.99240223096): 22'b0111101001111111000011
#Edge 1 a(-47.307485852249954): 22'b1101001011110100111011  , b(-246.72033772787887):   22'b1101101111011010111000  , c(35427.052672218364):     22'b0111101000101001100011
#Edge 2 a(291.4672833621105):   22'b0101111001000110111100  , b(-34.6826855440562):     22'b1101001000101010111011  , c(-149877.70231787008):    22'b1000001001001001011101

#PRINTING Tile Info
#Tile Size(16): 22'b0100111000000000000000
#Tile start_x(272): 22'b0101111000100000000000
#Tile start_y(32):  22'b0101001000000000000000
#Tile x steps(17): 22'b0100111000100000000000
#Tile y steps(18): 22'b0100111001000000000000