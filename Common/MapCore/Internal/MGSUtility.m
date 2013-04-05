#import "MGSUtility.h"

AGSPoint* AGSPointFromCLLocationCoordinate2D(CLLocationCoordinate2D coord) {
    // Set the spatial reference to nil here so the point will inherit whatever
    // the reference of its parent object is. This is done to simplify creating
    // complex geometry objects such as AGSPolygon/AGSPolyline since it appears
    // like points in those objects are only reprojected if their spatial
    // reference is inherited.
    AGSPoint *clPoint = [AGSPoint pointWithX:coord.longitude
                                           y:coord.latitude
                            spatialReference:nil];

    return clPoint;
}

AGSPoint* AGSPointFromCLLocationCoordinate2DInSpatialReference(CLLocationCoordinate2D coord, AGSSpatialReference *targetReference) {
    AGSPoint *clPoint = (AGSPoint *) [AGSPoint pointWithX:coord.longitude
                                                        y:coord.latitude
                                         spatialReference:[AGSSpatialReference wgs84SpatialReference]];

    AGSPoint *projectedPoint = (AGSPoint *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:clPoint
                                                                                    toSpatialReference:targetReference];

    return projectedPoint;
}

CLLocationCoordinate2D CLLocationCoordinate2DFromAGSPoint(AGSPoint *point) {
    AGSGeometryEngine *geoEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPoint *projectedPoint = (AGSPoint *) [geoEngine projectGeometry:point
                                                    toSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
    return CLLocationCoordinate2DMake(projectedPoint.y, projectedPoint.x);
}