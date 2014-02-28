#import "MITJSON.h"


@implementation MITJSON

+ (id)objectWithJSONString:(NSString *)jsonString {
    return [self objectWithJSONData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (id)objectWithJSONString:(NSString *)jsonString error:(NSError **)error {
    if(![jsonString length]) {
		return nil;
	} else {
        return [self objectWithJSONData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] error:error];
    }
}


+ (id)objectWithJSONData:(NSData *)jsonData {
    NSError *error = nil;
    id result = [self objectWithJSONData:jsonData error:&error];

    if (error) {
        DDLogWarn(@"failed to parse json: %@",error);
    }

    return result;
}

+ (id)objectWithJSONData:(NSData *)jsonData error:(NSError **)error {
    return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:error];
}

@end
