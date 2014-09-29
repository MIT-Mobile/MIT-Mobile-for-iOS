#import <Foundation/Foundation.h>
#import "MITMappedObject.h"


@interface MITLibrariesTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *dates;

@property (nonatomic, strong) NSArray *regularTerm;
@property (nonatomic, strong) NSArray *closingsTerm;
@property (nonatomic, strong) NSArray *exceptionsTerm;

@end
