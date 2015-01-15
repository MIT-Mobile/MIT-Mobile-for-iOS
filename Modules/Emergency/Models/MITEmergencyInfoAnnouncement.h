#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITEmergencyInfoAnnouncement : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *announcementHTML;
@property (nonatomic, strong) NSString *announcementText;
@property (nonatomic, strong) NSDate *published_at;
@property (nonatomic, strong) NSString *url;

@end
