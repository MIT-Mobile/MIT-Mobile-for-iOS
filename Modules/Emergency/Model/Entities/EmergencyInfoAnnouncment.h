#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface EmergencyInfoAnnouncment : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * published_at;
@property (nonatomic, retain) NSString * announcement_text;
@property (nonatomic, retain) NSDate * announcement_html;

@end
