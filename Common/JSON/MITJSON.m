#import "MITJSON.h"


@implementation MITJSON

+ (id)objectWithJSONString:(NSString *)jsonString {
	if(![jsonString length]) {
		return nil;
	}
	
	SBJSON *jsonParser = [[SBJSON alloc] init];
    id result = [jsonParser objectWithString:jsonString error:NULL];
    
    // if this is just a quoted string, wrap it in [] to make it an array and then parse to clean out escaped characters
    if (!result && jsonString && [[jsonString substringToIndex:1] isEqualToString:@"\""]) {
        jsonString = [NSString stringWithFormat:@"[%@]", jsonString];
        result = [jsonParser objectWithString:jsonString error:NULL];
        result = [((NSArray *)result) objectAtIndex:0];
    }
    
    [jsonParser release];
    
	return result;
}

+ (id)objectWithJSONData:(NSData *)jsonData {
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    return [self objectWithJSONString:jsonString];
}

@end
