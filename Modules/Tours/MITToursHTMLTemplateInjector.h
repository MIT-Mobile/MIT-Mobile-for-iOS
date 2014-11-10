#import <Foundation/Foundation.h>

@class MITToursDirectionsToStop, MITToursStop;

@interface MITToursHTMLTemplateInjector : NSObject

+ (NSString *)templatedHTMLForDirectionsToStop:(MITToursDirectionsToStop *)directionsToStop viewWidth:(CGFloat)viewWidth;
+ (NSString *)templatedHTMLForSideTripStop:(MITToursStop *)sideTripStop fromMainLoopStop:(MITToursStop *)mainLoopStop viewWidth:(CGFloat)viewWidth;

@end
