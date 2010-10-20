#import "MITMoreListController.h"
#import "MITModuleList.h"
#import "MITTabBarController.h"
#import "MITTabBarItem.h"
#import "MITUIConstants.h"
#import <math.h>

#define TAB_COUNT 4

@implementation MITMoreListController

@synthesize theTabBarController;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UnreadBadgeValuesChangeNotification object:nil];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

#pragma mark -
#pragma mark More table dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            NSInteger vcCount = [theTabBarController.viewControllers count];
            NSInteger rowCount = (vcCount > TAB_COUNT) ? [theTabBarController.viewControllers count] - TAB_COUNT : 0;
            return rowCount;
            break;
        }
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    MITMoreListTableViewCell *cell = (MITMoreListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MITMoreListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *cellText = nil;
    UIImage *cellImage = nil;
    UIImage *cellHighlightedImage = nil;
    
    switch (indexPath.section) {
        case 0: {
            UIViewController *vc = [theTabBarController.viewControllers objectAtIndex:indexPath.row + TAB_COUNT];
            cellText = vc.navigationItem.title;
			MITTabBarItem *tabBarItem = (MITTabBarItem *)vc.tabBarItem;
            cellImage = tabBarItem.tableImage;
            cellHighlightedImage = tabBarItem.image;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			cell.badgeValue = [[appDelegate moduleForTabBarItem:tabBarItem] badgeValue];
			
            break;
        }
        default:
            break;
    }
    cell.textLabel.text = cellText;
    cell.imageView.image = cellImage;
    cell.imageView.highlightedImage = cellHighlightedImage;
    
    return cell;
}

#pragma mark -
#pragma mark More table delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            // showItemOnMoreListAtIndex:indexPath.row + TAB_COUNT
            [theTabBarController showItemOnMoreList:[theTabBarController.allItems objectAtIndex:indexPath.row + TAB_COUNT]];
            break;
        }
        default:
            break;
    }
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


@end

@implementation MITMoreListTableViewCell
@dynamic badgeValue;
			
- (id) initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString *)identifier {
	if(self = [super initWithStyle:style reuseIdentifier:identifier]) {
		self.textLabel.opaque = NO;
		badgeView = [[TableCellBadgeView alloc] initWithFrame:CGRectMake(230, 9, 60, 25)];
		[self.contentView addSubview:badgeView];
    }
	return self;
}
					
- (void) dealloc {
	[badgeView release];
	[super dealloc];
}

- (NSString *) badgeView {
	return badgeView.badgeValue;
}
			
- (void) setBadgeValue: (NSString *)badgeValue {
	badgeView.badgeValue = badgeValue;
	[badgeView setNeedsDisplay];
}
@end
					
					
@implementation TableCellBadgeView
@synthesize badgeValue;

- (id) initWithFrame: (CGRect)frame {
	if(self = [super initWithFrame:frame]) {
		self.badgeValue = nil;
		self.opaque = NO;
	}
	return self;
}

- (void) drawRect: (CGRect)rect {
	// do not draw anything if there is no badge value
	if(![self.badgeValue length]) {
		return;
	}

	UIColor *ovalColor, *textColor;
	if(((UITableViewCell *)self.superview.superview).highlighted) {
		ovalColor = [UIColor whiteColor];
		textColor = CELL_SELECTION_BLUE;
	} else {
		ovalColor = [UIColor grayColor];
		textColor = [UIColor whiteColor];
	}
	
	UIFont *font = [UIFont systemFontOfSize:rect.size.height - 5.0];	
	[ovalColor setFill];
	
	CGSize textSize = [self.badgeValue sizeWithFont:font];
	CGFloat textWidth = textSize.width;
	CGFloat width = rect.size.width;
	CGFloat height = rect.size.height;
	
	// the diameter of the arcs we draw will be the height of the Frame
	CGFloat radius = height/2;

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextAddArc(context, width-radius, radius, radius, -M_PI/2, M_PI/2, 0);
	CGContextAddArc(context, width-radius-textWidth, radius, radius, M_PI/2, -M_PI/2, 0);
	CGContextClosePath(context);

	// the straight parts of the path drawn automaticlly
	CGContextDrawPath(context, kCGPathFill);
	
	[textColor setFill];
	[self.badgeValue drawAtPoint:CGPointMake(width-radius-textWidth, round((rect.size.height-textSize.height)/2)) withFont:font];
	 
}

@end
