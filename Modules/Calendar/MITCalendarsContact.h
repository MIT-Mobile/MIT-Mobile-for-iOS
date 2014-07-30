#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"


@interface MITCalendarsContact : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * websiteURL;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * phone;

@end
