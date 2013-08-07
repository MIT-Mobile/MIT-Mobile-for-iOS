#import "EventCategory.h"
#import "CalendarDataManager.h"
#import "MITCalendarEvent.h"
#import "CoreDataManager.h"

@implementation EventCategory 

@dynamic catID;
@dynamic listID;
@dynamic title;
@dynamic subCategories;
@dynamic parentCategory;
@dynamic events;

- (BOOL)hasSubCategories
{
	// don't count if event is subcategory of itself
	return ([self.subCategories count] > 1);
}

- (void)updateWithDict:(NSDictionary *)dict forListID:(NSString *)listID;
{
	self.catID = @([dict[@"catid"] integerValue]);
	self.title = dict[@"name"];
	NSArray *subcategories = dict[@"subcategories"];
    
    [subcategories enumerateObjectsUsingBlock:^(NSDictionary *category, NSUInteger idx, BOOL *stop) {
        NSInteger subcatID = [category[@"catid"] integerValue];
        
        EventCategory *subCategory = [CalendarDataManager categoryWithID:subcatID
                                                               forListID:listID];
        subCategory.title = category[@"name"];
        subCategory.parentCategory = self;
    }];
    
	[CoreDataManager saveData];
}

@end
