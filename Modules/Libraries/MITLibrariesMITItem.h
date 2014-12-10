#import <Foundation/Foundation.h>
#import "MITLibrariesCoverImage.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesMITItem : NSObject

@property (nonatomic, strong) NSString *callNumber;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *year;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imprint;
@property (nonatomic, strong) NSString *isbn;
@property (nonatomic, strong) NSString *docNumber;
@property (nonatomic, strong) NSString *material;
@property (nonatomic, strong) NSString *subLibrary;
@property (nonatomic, strong) NSString *barcode;
@property (nonatomic, strong) NSArray *coverImages;

+ (NSDictionary *)attributeMappings;
+ (NSArray *)relationshipMappings; // [RKRelationshipMapping]

@end
