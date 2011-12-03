#import <Foundation/Foundation.h>

extern NSString * const MITLibrariesOCLCCode;

@interface WorldCatHolding : NSObject {
@private
}

@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *library;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSArray *availability;
@property (nonatomic) NSUInteger count;

- (NSDictionary*)libraryAvailability;

- (NSUInteger)inLibraryCount;
- (NSUInteger)inLibraryCountForLocation:(NSString*)location;
@end


@interface WorldCatBook : NSObject {
    
}

- (id)initWithDictionary:(NSDictionary *)dict;

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) NSArray *authors;
@property (nonatomic, retain) NSArray *publishers;
@property (nonatomic, retain) NSArray *years;
@property (nonatomic, retain) NSArray *isbns;

// detail fields
@property (nonatomic, retain) NSArray *formats;
@property (nonatomic, retain) NSArray *addresses;
@property (nonatomic, retain) NSArray *extents;
@property (nonatomic, retain) NSDictionary *holdings; // sort these by library title
@property (nonatomic, retain) NSArray *lang;
@property (nonatomic, retain) NSArray *subjects;
@property (nonatomic, retain) NSArray *summarys;
@property (nonatomic, retain) NSArray *editions;
@property (nonatomic, retain) NSString *emailAndCiteMessage;
@property (nonatomic, retain) NSString *url;

@property (nonatomic) BOOL parseFailure;

- (void)updateDetailsWithDictionary:(NSDictionary *)dict;
- (NSString *)yearWithAuthors;
- (NSArray *)addressesWithPublishers;
- (NSString *)isbn;

@end
