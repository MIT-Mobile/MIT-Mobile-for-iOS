#import "MGSSafeAnnotation.h"

@interface MGSSafeAnnotation ()
@property (nonatomic,strong) id<MGSAnnotation> annotation;
@end

@implementation MGSSafeAnnotation
- (id)init {
    self = [super init];
    
    if (self) {
        self.annotation = nil;
    }
    
    return self;
}

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation {
    self = [super init];
    
    if (self) {
        self.annotation = annotation;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithAnnotation:self.annotation];
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return true;
    } else if ([object isKindOfClass:[MGSSafeAnnotation class]]) {
        MGSSafeAnnotation *other = (MGSSafeAnnotation*)object;
        return [self.annotation isEqual:other.annotation];
    } else {
        return false;
    }
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)(val)) << (howmuch)) | (((NSUInteger)(val)) >> (NSUINT_BIT - (howmuch))))
- (NSUInteger)hash
{
    return (NSUINTROTATE([self.annotation hash], NSUINT_BIT >> 1));
}

- (NSString*)title
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation title];
    }
    
    return nil;
}

- (NSString*)detail
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation detail];
    }
    
    return nil;
}

- (UIImage*)calloutImage
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation calloutImage];
    }
    
    return nil;
}

- (UIImage*)markerImage
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation markerImage];
    } else {
        return nil;
    }
}

- (MGSMarkerOptions)markerOptions {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation markerOptions];
    }
    
    return MGSMarkerOptionsMake(CGPointMake(0, 0), CGPointMake(0, 0));
}

- (MGSAnnotationType)annotationType
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation annotationType];
    }
    
    return MGSAnnotationMarker;
}

- (id<NSObject>)userData
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation userData];
    }
    
    return nil;
}

- (CLLocationCoordinate2D)coordinate
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation coordinate];
    }
    
    return CLLocationCoordinate2DMake(CGFLOAT_MAX,CGFLOAT_MAX);
}

- (NSArray*)points {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation points];
    }
    
    return nil;
}

- (UIColor*)strokeColor {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation strokeColor];
    }
    
    return nil;
}

- (UIColor*)fillColor {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation fillColor];
    }
    
    return nil;
}

- (CGFloat)lineWidth {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation lineWidth];
    }
    
    return 0.0;
}
@end
