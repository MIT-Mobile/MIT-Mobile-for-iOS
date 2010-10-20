
#import <CoreData/CoreData.h>

@class StellarClass;

@interface StellarStaffMember :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) StellarClass * stellarClass;

@end



