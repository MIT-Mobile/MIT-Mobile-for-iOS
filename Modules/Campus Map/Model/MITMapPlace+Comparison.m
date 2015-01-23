#import "MITMapPlace+Comparison.h"

@implementation MITMapPlace (Comparison)

-(NSComparisonResult)compare:(MITMapPlace *)anotherPlace
{
    NSString *myPlace = self.subtitle ? self.subtitle : self.title;
    NSString *theirPlace = anotherPlace.subtitle ? anotherPlace.subtitle : anotherPlace.title;
    
    return [myPlace localizedStandardCompare:theirPlace];
}

@end
