#import <Foundation/Foundation.h>

extern NSString * const MITLibrariesOCLCCode;

@interface WorldCatHolding : NSObject
@property (copy) NSString *code;
@property (copy) NSString *address;
@property (copy) NSString *library;
@property (copy) NSString *collection;
@property (copy) NSString *url;
@property (nonatomic,copy) NSArray *availability;
@property (nonatomic,readonly,copy) NSDictionary *libraryAvailability;
@property NSUInteger count;

- (NSUInteger)inLibraryCount;
- (NSUInteger)inLibraryCountForLocation:(NSString*)location;
@end


@interface WorldCatBook : NSObject
@property (copy) NSString *identifier;
@property (copy) NSString *title;
@property (copy) NSString *imageURL;
@property (copy) NSArray *authors;
@property (copy) NSArray *publishers;
@property (copy) NSArray *years;
@property (copy) NSArray *isbns;

// detail fields
@property (copy) NSArray *formats;
@property (copy) NSArray *addresses;
@property (copy) NSArray *extents;
@property (copy) NSDictionary *holdings; // sort these by library title
@property (copy) NSArray *lang;
@property (copy) NSArray *subjects;
@property (copy) NSArray *summarys;
@property (copy) NSArray *editions;
@property (copy) NSString *emailAndCiteMessage;
@property (copy) NSString *url;

@property (getter = isParseFailure) BOOL parseFailure;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)updateDetailsWithDictionary:(NSDictionary *)dict;
- (NSString *)yearWithAuthors;
- (NSArray *)addressesWithPublishers;
- (NSString *)isbn;

@end
