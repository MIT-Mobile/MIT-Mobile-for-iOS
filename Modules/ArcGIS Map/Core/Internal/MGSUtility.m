#import "MGSUtility.h"


AGSPoint* AGSPointFromCLLocationCoordinate(CLLocationCoordinate2D coord)
{
    return [AGSPoint pointWithX:coord.longitude
                              y:coord.latitude
               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
}

CLLocationCoordinate2D CLLocationCoordinateFromAGSPoint(AGSPoint *point)
{
    AGSGeometryEngine *geoEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPoint *projectedPoint = (AGSPoint*)[geoEngine projectGeometry:point
                                                  toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    return CLLocationCoordinate2DMake(projectedPoint.y, projectedPoint.x);
}
