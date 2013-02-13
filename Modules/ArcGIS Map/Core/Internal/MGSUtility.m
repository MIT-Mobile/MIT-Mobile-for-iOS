#import "MGSUtility.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

NSString* const MGSAnnotationAttributeKey = @"MGSAnnotationAttribute";


AGSPoint* AGSPointFromCLLocationCoordinate(CLLocationCoordinate2D coord)
{
    AGSPoint *clPoint = [AGSPoint pointWithX:coord.longitude
                                           y:coord.latitude
                            spatialReference:[AGSSpatialReference wgs84SpatialReference]];
    
    return clPoint;
}

AGSPoint* AGSPointWithReferenceFromCLLocationCoordinate(CLLocationCoordinate2D coord, AGSSpatialReference *targetReference)
{
    AGSPoint *clPoint = (AGSPoint*)[AGSPoint pointWithX:coord.longitude
                                                      y:coord.latitude
                                       spatialReference:[AGSSpatialReference wgs84SpatialReference]];
    
    AGSPoint *projectedPoint = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:clPoint
                                                                                  toSpatialReference:targetReference];
    
    return projectedPoint;
}

CLLocationCoordinate2D CLLocationCoordinateFromAGSPoint(AGSPoint *point)
{
    AGSGeometryEngine *geoEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPoint *projectedPoint = (AGSPoint*)[geoEngine projectGeometry:point
                                                  toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    return CLLocationCoordinate2DMake(projectedPoint.y, projectedPoint.x);
}