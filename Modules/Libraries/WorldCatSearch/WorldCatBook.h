#import <Foundation/Foundation.h>

@interface WorldCatHolding : NSObject {
@private
}

@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *library;
@property (nonatomic, retain) NSString *url;

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
@property (nonatomic, retain) NSArray *addresses;
@property (nonatomic, retain) NSArray *extents;
@property (nonatomic, retain) NSArray *holdings;
@property (nonatomic, retain) NSArray *lang;
@property (nonatomic, retain) NSArray *subjects;
@property (nonatomic, retain) NSArray *summarys;
@property (nonatomic, retain) NSArray *editions;

@property (nonatomic) BOOL parseFailure;

- (void)updateDetailsWithDictionary:(NSDictionary *)dict;
- (NSString *)authorYear;
- (NSString *)isbn;

@end
