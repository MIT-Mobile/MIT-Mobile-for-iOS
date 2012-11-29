#import "MGSMapAnnotation.h"
#import "MGSMapAnnotation+Protected.h"

#import "MGSMapCoordinate.h"
#import "MGSMarker.h"
#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSAnnotation.h"

#import "MGSMapAnnotation+AGS.h"
#import "MGSMapCoordinate+AGS.h"

#import "MGSUtility.h"

NSString* const MGSAnnotationAttributeKey = @"MGSAnnotationAttribute";

@implementation MGSIMapAnnotation
+ (id)annotationWithGraphic:(AGSGraphic*)graphic
{
    /*
    AGSPoint *point = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry.envelope.center
                                                                         toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    MGSMapCoordinate *coordinate = [[MGSMapCoordinate alloc] initWithX:point.x
                                                                     y:point.y];
    MGSMapAnnotation *annotation = [[MGSMapAnnotation alloc] init];
    MGSMarker *marker = [[MGSMarker alloc] init];
    marker.style = MGSMarkerStyleRemote;
    
    annotation.coordinate = coordinate;
    annotation.marker = marker;
    annotation.agsGraphic = graphic;
    annotation.attributes = graphic.attributes;
    [graphic.attributes setObject:annotation
                           forKey:MGSAnnotationAttributeKey];
    */
    return nil;
}


+ (AGSSymbol*)symbolForAnnotation:(id<MGSAnnotation>)annotation defaultMarker:(MGSMarker*)templateMarker
{
    AGSSymbol *symbol = nil;
    
    MGSMarker *marker = annotation.marker;
    
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


+ (AGSGraphic*)graphicOfType:(MGSGraphicType)graphicType
               withAnnotation:(id<MGSAnnotation>)annotation
                    template:(MGSMarker*)template
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
@end
