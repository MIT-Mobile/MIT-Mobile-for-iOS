
#import <Foundation/Foundation.h>


@interface MITMapCategory : NSObject 
{
	// queryable text of this category
	NSString* _categoryName;
	
	// items in this category
	NSArray* _categoryItems;
}


@property (nonatomic, retain) NSString* categoryName;
@property (nonatomic, retain) NSArray* categoryItems;

-(id) initWithInfo:(NSDictionary*)info;


@end
