#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;

extern NSString* const FacilitiesLocationContactNameKey;
extern NSString* const FacilitiesLocationContactPhoneKey;
extern NSString* const FacilitiesLocationContactEmailKey;

@interface FacilitiesProperty : NSManagedObject {
@private
}
@property (nonatomic) BOOL hidden;
@property (nonatomic) BOOL leased;
@property (nonatomic, retain) NSDictionary *contactInfo;
@property (nonatomic, retain) FacilitiesLocation *location;

@end
