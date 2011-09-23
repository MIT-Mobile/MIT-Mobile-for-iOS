#import <Foundation/Foundation.h>


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
@property (nonatomic) BOOL parseFailure;



@end
