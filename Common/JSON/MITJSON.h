#import <Foundation/Foundation.h>
#import "JSON.h"


@interface MITJSON : NSObject {

}

+ (id)objectWithJSONString:(NSString *)jsonString;
+ (id)objectWithJSONString:(NSString *)jsonString error:(NSError**)error;

+ (id)objectWithJSONData:(NSData *)jsonData;
+ (id)objectWithJSONData:(NSData *)jsonData error:(NSError**)error;


@end
