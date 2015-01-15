#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EmergencyInfoContact : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * contactDescription;

@end
