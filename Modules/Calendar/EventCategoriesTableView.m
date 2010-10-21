#import "EventCategoriesTableView.h"
#import "EventCategory.h"
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"

@implementation EventCategoriesTableView

@synthesize categories, parentViewController;

- (BOOL)isSubcategoryView
{
	return (parentViewController.catID != kCalendarTopLevelCategoryID);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//NSLog(@"viewing %@", [self description]);
	if (categories) {
		return [categories count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    EventCategory *category = [self.categories objectAtIndex:indexPath.row];
	if ([self isSubcategoryView] && category.parentCategory == category) {
		cell.textLabel.text = [NSString stringWithFormat:@"All %@", category.title];
	} else {
		cell.textLabel.text = category.title;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    EventCategory *category = [self.categories objectAtIndex:indexPath.row];
	
	CalendarEventsViewController *vc = [[CalendarEventsViewController alloc] init];
	vc.catID = [category.catID intValue];
	vc.navigationItem.title = category.title;
	vc.showScroller = NO;

	if ([category hasSubCategories] && ![self isSubcategoryView]) {
		vc.activeEventList = CalendarEventListTypeCategory;
		
	} else {
	
		NSArray *events = [category.events allObjects];	
		vc.events = events;
		vc.activeEventList = CalendarEventListTypeEvents;
		vc.showList = YES;
	}

	[self.parentViewController.navigationController pushViewController:vc animated:YES];
	[vc release];

}

- (void)dealloc {
    [categories release];
    parentViewController = nil;
    
    [super dealloc];
}


@end

