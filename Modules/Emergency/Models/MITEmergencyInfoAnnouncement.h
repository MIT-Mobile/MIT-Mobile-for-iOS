#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITEmergencyInfoAnnouncement : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *announcement_html;
@property (nonatomic, strong) NSString *announcement_text;
@property (nonatomic, strong) NSDate *published_at;
@property (nonatomic, strong) NSString *url;

@end
