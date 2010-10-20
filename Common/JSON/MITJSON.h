#import <Foundation/Foundation.h>
#import "JSON.h"


@interface MITJSON : NSObject {

}

+ (id)objectWithJSONString:(NSString *)jsonString;
+ (id)objectWithJSONData:(NSData *)jsonData;

@end
