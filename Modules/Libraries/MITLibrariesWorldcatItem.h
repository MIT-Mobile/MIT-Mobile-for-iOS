#import <Foundation/Foundation.h>
#import "MITLibrariesHolding.h"
#import "MITLibrariesCitation.h"
#import "MITLibrariesCoverImage.h"
#import "MITLibrariesWebservices.h"

#import "MITMappedObject.h"

@interface MITLibrariesWorldcatItem : NSObject <MITInitializableWithDictionaryProtocol, MITMappedObject>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *worldCatUrl;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *coverImages;
@property (nonatomic, strong) NSArray *author;
@property (nonatomic, strong) NSArray *year;
@property (nonatomic, strong) NSArray *publisher;
@property (nonatomic, strong) NSArray *format;
@property (nonatomic, strong) NSArray *isbns;
@property (nonatomic, strong) NSArray *subject;
@property (nonatomic, strong) NSArray *language;
@property (nonatomic, strong) NSArray *extent;
@property (nonatomic, strong) NSArray *summaries;
@property (nonatomic, strong) NSArray *editions;
@property (nonatomic, strong) NSArray *address;
@property (nonatomic, strong) NSArray *holdings;
@property (nonatomic, strong, readonly) NSArray *citations;
@property (nonatomic, strong) NSString *composedHTML;

- (NSString *)yearsString;
- (NSString *)authorsString;
- (NSString *)formatsString;
- (NSString *)publishersString;
- (NSString *)firstSummaryString;

@end
