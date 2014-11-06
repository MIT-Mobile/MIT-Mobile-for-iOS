#import <Foundation/Foundation.h>

@class MITToursDirectionsToStop;

@interface MITToursHTMLTemplateInjector : NSObject

+ (NSString *)templatedHTMLForDirectionsToStop:(MITToursDirectionsToStop *)directionsToStop viewWidth:(CGFloat)viewWidth;

@end
