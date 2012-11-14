#import <Foundation/Foundation.h>

@interface MGSRouteOperation : NSOperation
- (id)initWithStops:(NSArray*)stops completion:(void (^)(NSArray *annotation, NSArray *locatedAnnotations, NSError *error))completionBlock;
@end
