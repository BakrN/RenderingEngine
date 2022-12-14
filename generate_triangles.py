from binner import Triangle , bin_triangle, draw_triangle , Vec3f, Edge, get_dec_from_fp22
vtx0 = Vec3f(581.6837                   , 268.496                  ,0.9055                   )
vtx1 = Vec3f(630.4806                   , 195.724                  ,0.5275                   )
vtx2 = Vec3f(343.4160                   , 51.4249                  ,0.8199                   )
e1 = Edge(vtx0, vtx2)
e2 = Edge(vtx2, vtx1)
e0 = Edge(vtx1 , vtx0)
tr = Triangle(vtx0, vtx1, vtx2,e0=e0, e1=e1,e2=e2)  
tr.print_triangle_info() 

#ee0 = Vec3f (get_dec_from_fp22("0011011111010000010110"),get_dec_from_fp22("1011101000010111110110"),get_dec_from_fp22("1101101000100011001110"))
#ee1 = Vec3f (get_dec_from_fp22("1011011010101101000111"),get_dec_from_fp22("0011101010101001011101"),get_dec_from_fp22("0101011010000101010010")) 
#ee2 = Vec3f (get_dec_from_fp22("1011101001100100111111"),get_dec_from_fp22("1011011100110110000100"),get_dec_from_fp22("0101111110001111111101")) 
#e0.normalize() 
#e1.normalize() 
#e2.normalize() 
#print(get_dec_from_fp22("1101001100100011110001")) 
#print(get_dec_from_fp22("0101011011011100101011")) 
#print(get_dec_from_fp22("1101101000100011001110")) 
#print(f"actual ee0: {ee0}, theoretical ee0: {e0.a} , {e0.b} , {e0.c}")
#print(f"actual ee1: {ee1}, theoretical ee1: {e1.a} , {e1.b} , {e1.c}") 
#print(f"actual ee2: {ee2}, theoretical ee2: {e2.a} , {e2.b} , {e2.c}")
#tile - binner
tile_shader, tile_raster , tile_discar = bin_triangle(tr)  
#
draw_triangle(tr, tile_shader, tile_raster, tile_discar)


#print(get_dec_from_fp22("0111101001111111000011 ") +get_dec_from_fp22("0111101000101001100011" ) + get_dec_from_fp22( "1000001001001001011101" )  ) 
#vtx0 = Vec3f(272.73203211990284,91.29683482394742 , 0.5678275245865031, randomize=False)
#vtx1 = Vec3f(554.1350553918379,335.45663233380793, 0.5678275245865031, randomize=False) 
#e = Edge(vtx0, vtx1)
#e.normalize() 
#print(e.a)
#print(e.b)
#print(e.c)

#PRINTING Vertex Info
#Vertex 0 x(581.6837719541518): 22'b0110001001000101101100  , y(268.4960556553459): 22'b0101111000011000111111  , z(0.9055049054819486): 22'b0011101110011111001111
#Vertex 1 x(630.4806089218879): 22'b0110001001110110011111  , y(195.7249761767946): 22'b0101101100001110111010  , z(0.5275338907514608): 22'b0011101000011100001100
#Vertex 2 x(343.4160441079152): 22'b0101111010101110110101  , y(51.4249629249532): 22'b0101001100110110110011  ,  z(0.8199442458828154):  22'b0011101101000111101000
#PRINTING Edge Info
#Edge 0 a(217.0710927303927):  22'b0101101101100100010010  , b(-238.2677278462366): 22'b1101101110111001000101  , c(-62292.786884948335):22'b1111101111001101010101
#Edge 1 a(-144.3000132518414): 22'b1101101001000001001101  , b(287.0645648139727):  22'b0101111000111110001000  , c(34792.65511304073):  22'b0111101000011111101001
#Edge 2 a(-72.77107947855131): 22'b1101011001000110001011  , b(-48.79683696773611): 22'b1101001100001100110000  , c(55431.514254553214): 22'b0111101101100010001000
#PRINTING Tile Info
#Tile Size(16): 22'b0100111000000000000000
#Tile start_x(336): 22'b0101111010100000000000
#Tile start_y(48):  22'b0101001100000000000000
#Tile x steps(18): 22'b0100111001000000000000
#Tile y steps(13): 22'b0100101101000000000000