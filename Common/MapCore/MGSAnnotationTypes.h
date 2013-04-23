#ifndef _MGSAnnotationTypes_h
#define _MGSAnnotationTypes_h

typedef NS_ENUM(NSUInteger,MGSAnnotationType) {
    // Indicates the annotation should place a marker on the map
    // The maker will be the default pin unless the markerImage
    // image property returns a non-nil value. A marker is the only object
    // that can pop up a callout. By default, markers will respond to taps.
    MGSAnnotationMarker = 0x00,
    
    // Indicates that the annotation should draw a line to the map.
    // A polyline requires that the points property return an array of
    // NSValue objects containing CLLocationCoordinate2D points. If points
    // is nil or contains no data, the object will not be added to the map.
    // If the coordinate returns a valid CLLocationCoordinate2D point (verified
    // by CLLocationCoordinate2DIsValid), then the values in the 'points'
    // property are assumed to be relative offsets from the 'coordinate'
    MGSAnnotationPolyline = 0x01,
    MGSAnnotationPolygon = 0x02,
    
    // Indicates that the annotation is a marker for some sort of
    // pre-existing data on the layer. For example, if we were to
    MGSAnnotationPointOfInterest = 0x04
};


typedef struct _MGSMarkerOptions {
    CGPoint hotspot;
    CGPoint offset;
} MGSMarkerOptions;


FOUNDATION_STATIC_INLINE MGSMarkerOptions MGSMarkerOptionsMake(CGPoint relativeHotspot, CGPoint relativeOffset) {
    MGSMarkerOptions settings = { .hotspot = relativeHotspot,
        .offset = relativeOffset };
    
    return settings;
}

#endif
