#import "EventCategoriesTableView.h"
#import "EventCategory.h"
#import "CalendarEventsViewController.h"

@implementation EventCategoriesTableView
- (BOOL)isSubcategoryView
{
	return (self.parentViewController.category != nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    EventCategory *category = self.categories[indexPath.row];
	if ([self isSubcategoryView] && !category.parentCategory) {
		cell.textLabel.text = [NSString stringWithFormat:@"All %@", category.title];
	} else {
		cell.textLabel.text = category.title;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    EventCategory *category = self.categories[indexPath.row];
	
	CalendarEventsViewController *vc = [[CalendarEventsViewController alloc] init];
	vc.category = category;
	vc.navigationItem.title = category.title;
	vc.showScroller = NO;

	if ([category hasSubCategories] && ![self isSubcategoryView]) {
		//vc.activeEventList = CalendarEventListTypeCategory;
		vc.activeEventList = [[CalendarDataManager sharedManager] eventListWithID:@"categories"];
		
	} else {
	
		NSArray *events = [category.events allObjects];	
		vc.events = events;
		//vc.activeEventList = CalendarEventListTypeEvents;
		vc.showList = YES;
	}

	[self.parentViewController.navigationController pushViewController:vc animated:YES];

}

@end
