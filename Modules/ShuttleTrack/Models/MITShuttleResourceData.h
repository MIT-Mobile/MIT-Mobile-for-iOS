#import <Foundation/Foundation.h>

extern const NSInteger kResourceSectionCount;

extern NSString * const kResourceDescriptionKey;
extern NSString * const kResourcePhoneNumberKey;
extern NSString * const kResourceFormattedPhoneNumberKey;
extern NSString * const kResourceURLKey;

extern NSString * const kContactInformationHeaderTitle;
extern NSString * const kMBTAInformationHeaderTitle;

@interface MITShuttleResourceData : NSObject

@property (copy, nonatomic) NSArray *contactInformation;
@property (copy, nonatomic) NSArray *mbtaInformation;

@end
