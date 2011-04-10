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
	self.catID = [NSNumber numberWithInt:[[dict objectForKey:@"catid"] intValue]];
	self.title = [dict objectForKey:@"name"];
	NSArray *subcatArray = [dict objectForKey:@"subcategories"];
	if (subcatArray != nil) {
		self.parentCategory = self;
		for (NSDictionary *subcatDict in subcatArray) {
			NSInteger subcatID = [[subcatDict objectForKey:@"catid"] intValue];
			EventCategory *subCategory = [CalendarDataManager categoryWithID:subcatID forListID:listID];
			subCategory.parentCategory = self;
			subCategory.title = [subcatDict objectForKey:@"name"];
		}
		
	} else if (self.parentCategory == nil) {
		// categories without subcategories
		self.parentCategory = self;
	}
	[CoreDataManager saveData];
}

@end
