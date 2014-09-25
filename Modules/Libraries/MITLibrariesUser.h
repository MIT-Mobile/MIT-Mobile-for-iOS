#import <Foundation/Foundation.h>
#import "MITLibrariesMITFineItem.h"
#import "MITLibrariesMITHoldItem.h"
#import "MITLibrariesMITLoanItem.h"

@interface MITLibrariesUser : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *loans;
@property (nonatomic, strong) NSArray *holds;
@property (nonatomic, strong) NSArray *fines;

@end