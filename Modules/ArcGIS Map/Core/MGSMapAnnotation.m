#import "MGSMapAnnotation.h"
#import "MGSMapAnnotation+Protected.h"

#import "MGSMapCoordinate.h"
#import "MGSMarker.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

#import "MGSMapAnnotation+AGS.h"
#import "MGSMapCoordinate+AGS.h"

NSString* const MGSAnnotationAttributeKey = @"MGSAnnotationAttribute";

@implementation MGSMapAnnotation
+ (id)annotationWithGraphic:(AGSGraphic*)graphic
{
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
    
    return annotation;
}


+ (AGSSymbol*)symbolForAnnotation:(MGSMapAnnotation*)annotation defaultMarker:(MGSMarker*)templateMarker
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
               withAnnotation:(MGSMapAnnotation*)annotation
                    template:(MGSMarker*)template
{
    AGSGraphic *graphic = nil;
    
    switch(graphicType)
    {
        case MGSGraphicStop:
            graphic = [AGSStopGraphic graphicWithGeometry:[annotation.coordinate agsPoint]
                                                symbol:[self symbolForAnnotation:annotation
                                                                   defaultMarker:template]
                                            attributes:[NSMutableDictionary dictionary]
                                  infoTemplateDelegate:[MGSAnnotationInfoTemplateDelegate sharedInfoTemplate]];
        case MGSGraphicDefault:
        default:
            graphic = [AGSGraphic graphicWithGeometry:[annotation.coordinate agsPoint]
                                            symbol:[self symbolForAnnotation:annotation
                                                               defaultMarker:template]
                                        attributes:[NSMutableDictionary dictionary]
                              infoTemplateDelegate:[MGSAnnotationInfoTemplateDelegate sharedInfoTemplate]];
    }
    
    [graphic.attributes setObject:annotation
                           forKey:MGSAnnotationAttributeKey];
    
    return graphic;
}

+ (AGSGraphic*)graphicForAnnotation:(MGSMapAnnotation*)annotation template:(MGSMarker*)template
{
    return [self graphicOfType:MGSGraphicDefault
                 withAnnotation:annotation
                      template:template];
}

- (id)initWithTitle:(NSString *)title
         detailText:(NSString *)detail
       atCoordinate:(MGSMapCoordinate *)coordinate {
    self = [super init];

    if (self) {
        self.title = title;
        self.detail = detail;
        self.coordinate = coordinate;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MGSMapAnnotation *annotation = [[MGSMapAnnotation allocWithZone:zone] initWithTitle:self.title
                                                                             detailText:self.detail
                                                                           atCoordinate:self.coordinate];
    annotation.image = self.image;
    annotation.marker = self.marker;
    
    return annotation;
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    else if ([object isKindOfClass:[self class]]) {
        return [self isEqualToAnnotation:(MGSMapAnnotation *) object];
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToAnnotation:(MGSMapAnnotation *)mapAnnotation {
    if (mapAnnotation == self) {
        return YES;
    }
    else {
        return ([self.title isEqualToString:mapAnnotation.title] &&
                [self.detail isEqualToString:mapAnnotation.detail] &&
                [self.coordinate isEqual:mapAnnotation.coordinate]);
    }
}

- (NSUInteger)hash
{
    return ([self.title hash] ^
            [self.detail hash] ^
            [self.coordinate hash]);
}

- (void)setAgsGraphic:(AGSGraphic *)agsGraphic
{
    [self.agsGraphic.attributes removeObjectForKey:MGSAnnotationAttributeKey];
    
    if (agsGraphic)
    {
        [self.agsGraphic.attributes setObject:self
                                       forKey:MGSAnnotationAttributeKey];
    }
    
    _agsGraphic = agsGraphic;
}

@end
