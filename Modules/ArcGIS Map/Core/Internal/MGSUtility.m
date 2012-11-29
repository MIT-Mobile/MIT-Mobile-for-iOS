#import "MGSUtility.h"
NSString* const MGSAnnotationAttributeKey = @"MGSAnnotationAttribute";


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


AGSSymbol* AGSSymbolFromAnnotation(id<MGSAnnotation> annotation, MGSMarker *templateMarker)
{
    AGSSymbol *symbol = nil;
    
    MGSMarker *marker =nil;
    
    if ([annotation respondsToSelector:@selector(marker)])
    {
        marker = annotation.marker;
    }
    
    if (marker == nil)
    {
        marker = templateMarker;
    }
    
    UIColor *markerColor = (marker.color ?
                            marker.color :
                            [UIColor blueColor]);
    
    CGFloat markerSize = MAX(marker.size.height, marker.size.height);
    
    // Don't use a zero check here, floats lie
    markerSize = (markerSize < 0.1 ? 32.0 : markerSize);
    
    switch (marker.style) {
        case MGSMarkerStyleSquare:
        {
            AGSSimpleMarkerSymbolStyle symbolStyle = AGSSimpleMarkerSymbolStyleSquare;
            AGSSimpleMarkerSymbol *markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:markerColor];
            markerSymbol.style = symbolStyle;
            markerSymbol.size = markerSize;
            symbol = markerSymbol;
            break;
        }
            
        case MGSMarkerStyleCircle:
        {
            AGSSimpleMarkerSymbolStyle symbolStyle = AGSSimpleMarkerSymbolStyleCircle;
            AGSSimpleMarkerSymbol *markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:markerColor];
            markerSymbol.style = symbolStyle;
            markerSymbol.size = markerSize;
            symbol = markerSymbol;
        }
            break;
            
        case MGSMarkerStyleIcon:
        {
            UIImage *markerImage = marker.icon;
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
            pictureSymbol.yoffset = (CGFloat) (ceil(markerImage.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }
            
        case MGSMarkerStyleRemote:
        {
            symbol = nil;
        }
            
        case MGSMarkerStylePin:
        default:
        {
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"map_pin_complete"];
            pictureSymbol.yoffset = (CGFloat) (ceil(pictureSymbol.image.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }
    }
    
    return symbol;
}


AGSGraphic* AGSGraphicFromAnnotation(id<MGSAnnotation> annotation, MGSGraphicType graphicType, MGSMarker *template)
{
    AGSGraphic *graphic = nil;
    
    switch(graphicType)
    {
        case MGSGraphicStop:
            graphic = [AGSStopGraphic graphicWithGeometry:AGSPointFromCLLocationCoordinate(annotation.coordinate)
                                                   symbol:[self symbolForAnnotation:annotation
                                                                      defaultMarker:template]
                                               attributes:[NSMutableDictionary dictionary]
                                     infoTemplateDelegate:[MGSAnnotationInfoTemplateDelegate sharedInfoTemplate]];
        case MGSGraphicDefault:
        default:
            graphic = [AGSGraphic graphicWithGeometry:AGSPointFromCLLocationCoordinate(annotation.coordinate)
                                               symbol:[self symbolForAnnotation:annotation
                                                                  defaultMarker:template]
                                           attributes:[NSMutableDictionary dictionary]
                                 infoTemplateDelegate:[MGSAnnotationInfoTemplateDelegate sharedInfoTemplate]];
    }
    
    return graphic;
}

+ (AGSGraphic*)graphicForAnnotation:(id<MGSAnnotation>)annotation template:(MGSMarker*)template
{
    return [self graphicOfType:MGSGraphicDefault
                withAnnotation:annotation
                      template:template];
}