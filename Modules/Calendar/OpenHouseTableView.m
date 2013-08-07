#import "EventCategoriesTableView.h"
#import "EventCategory.h"
#import "CalendarEventsViewController.h"

@implementation OpenHouseTableView
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
	cell.textLabel.text = category.title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    EventCategory *category = self.categories[indexPath.row];
	
	CalendarEventsViewController *vc = [[CalendarEventsViewController alloc] init];
	vc.category = category;
	vc.navigationItem.title = category.title;
	vc.showScroller = NO;
    
    NSArray *events = [category.events allObjects];	
    vc.startDate = [NSDate dateWithTimeIntervalSince1970:OPEN_HOUSE_START_DATE];
	vc.events = events;
    vc.showList = YES;
	[self.parentViewController.navigationController pushViewController:vc animated:YES];

}


@end
