# This python script will download the map tiles from MIT's Map Server
# and name them with a column/row convention


tile_extents = [
#	[13, [2476,3029], [2479,3030]],
#	[14, [4953,6058], [4959,6060]],
	[15, [9911,12118], [9915,12121]],
	[16, [19822,24237], [19830,24243]],
	[17, [39645,48475],[39659,48487]],
    [18, [79290,96950],[79318,96974]],
    [19, [158581,193900], [158635,193946]]
]

maxZoom = 17

from urllib2 import Request, urlopen, URLError, HTTPError
file_mode = "b"

# Used on JavaScript map
# url = "http://web.mit.edu/campus-map/tiles/tile_" + str(i) + "_" + str(j) + "_" + str(zoom) + ".png"


# 8-Bit PNGs
# baseURL = "http://maps.mit.edu/ArcGIS/rest/services/Mobile/WhereIs_Mobile/MapServer/tile/"

# 24-Bit PNGs
# baseURL = "http://maps.mit.edu/ArcGIS/rest/services/Mobile/WhereIs_Mobile24/MapServer/tile/" # 

# Both map and Google backing
baseURL = "http://maps.mit.edu/ArcGIS/rest/services/Mobile/WhereIs_MobileAll/MapServer/tile/"


for tile in tile_extents:
	zoom = tile[0]
	start = tile[1]
	end = tile[2]
	
	print 'zoom ', zoom
	print 'start ', start
	print 'end ', end
	
	for i in range( start[0] , end[0]+1 ):	
		for j in range(start[1] , end[1]+1 ):
			t = str(zoom)+"/"+str(i)+"/"+str(j) + ".png"
			
			global maxZoom;
			file_name = "MITTile_" + str(100 / (2**(maxZoom - zoom))) + "_"+ str(i - start[0])+  "_"+ str(j - start[1]) + ".png"

			
			url = baseURL + str(zoom) + "/" + str(j)+"/"+str(i)
			
			req = Request(url)

			try:
				f = urlopen(req)
				print "downloading " + url

				# Open our local file for writing
				local_file = open(file_name, "w" + file_mode)
				#Write to our local file
				local_file.write(f.read())
				local_file.close()

			#handle errors
			except HTTPError, e:
				print "HTTP Error:",e.code , url
			except URLError, e:
				print "URL Error:",e.reason , url
