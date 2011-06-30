#import "FacilitiesProperty.h"
#import "FacilitiesLocation.h"

NSString* const FacilitiesLocationContactNameKey = @"FacilitiesLocationContactName";
NSString* const FacilitiesLocationContactPhoneKey = @"FacilitiesLocationContactPhone";
NSString* const FacilitiesLocationContactEmailKey = @"FacilitiesLocationContactEmail";

@implementation FacilitiesProperty
@dynamic hidden;
@dynamic leased;
@dynamic contactInfo;
@dynamic location;

@end
