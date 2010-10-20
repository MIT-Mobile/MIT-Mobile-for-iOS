
#import <CoreData/CoreData.h>

@class StellarClass;

@interface StellarClassTime :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) StellarClass * stellarClass;

@end



