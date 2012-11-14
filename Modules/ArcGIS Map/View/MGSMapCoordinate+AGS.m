#import "MGSMapCoordinate+AGS.h"
#import "MGSMapCoordinate+Protected.h"
#import <ArcGIS/ArcGIS.h>

@implementation MGSMapCoordinate (AGS)
@dynamic agsPoint;

+ (AGSGeometryEngine*)sharedGeometryEngine
{
    return [AGSGeometryEngine defaultGeometryEngine];
}


- (void)setAgsPoint:(AGSPoint *)agsPoint
{
    AGSPoint *sourcePoint = agsPoint;
    
    if ([[agsPoint spatialReference] wkid] != WKID_WGS84)
    {
        sourcePoint = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:agsPoint
                                                                         toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    }
    
    self.longitude = sourcePoint.x;
    self.latitude = sourcePoint.y;
}

- (AGSPoint*)agsPoint
{
    return [self agsPointWithSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
}

- (AGSPoint*)agsPointWithSpatialReference:(AGSSpatialReference*)reference
{
    return [AGSPoint pointWithX:self.longitude
                              y:self.latitude
               spatialReference:reference];
}
@end
