#import "MapSelectionController.h"
#import "BookmarksTableViewController.h"
#import "RecentSearchesViewController.h"
#import "CategoriesTableViewController.h"
#import "UIKit+MITAdditions.h"

@interface MapSelectionController ()
@property(nonatomic, strong) UIBarButtonItem* cancelButton;
@property(nonatomic, copy) NSArray* toolbarButtonItems;
@end

@implementation MapSelectionController
- (id)initWithMapSelectionControllerSegment:(MapSelectionControllerSegment)segment campusMap:(CampusMapViewController*)mapVC;
{
	UIViewController* vc = nil;
	
	switch (segment) {
		case MapSelectionControllerSegmentBookmarks:
			vc = [[BookmarksTableViewController alloc] initWithMapSelectionController:self];
			break;
		case MapSelectionControllerSegmentRecents:
			vc = [[RecentSearchesViewController alloc] initWithMapSelectionController:self];
			break;
		
		case MapSelectionControllerSegmentBrowse:
			vc = [[CategoriesTableViewController alloc] initWithMapSelectionController:self];
			[(CategoriesTableViewController*)vc setTopLevel:YES];
			break;
			
		default:
			break;
	}
	
	if (vc) {
		self = [super initWithRootViewController:vc];
	} else {
		self = [super init];
	}

    if (self) {
        _mapVC = mapVC;

        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Bookmarks", @"Recents", @"Browse"]];
        seg.selectedSegmentIndex = segment;
        seg.segmentedControlStyle = UISegmentedControlStyleBar;
        seg.tintColor = [UIColor darkGrayColor];
        
        [seg addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        
        // TODO: Find a way to make this center itself. Hardcoding sizes is awful.
        UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:seg];
        item.width = 308.0;

        _toolbarButtonItems = @[item];
        
        [self setToolbarHidden:NO];
        [self.toolbar setBarStyle:UIBarStyleBlack];
        
        
        _cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(cancelButtonTapped)];
    }

	return self;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark User Actions
-(void) cancelButtonTapped
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}


-(void) segmentChanged:(id)sender
{
	UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
	UIViewController* vc = nil;
	
	switch (segmentedControl.selectedSegmentIndex) {
		case MapSelectionControllerSegmentBookmarks:
			vc = [[BookmarksTableViewController alloc] initWithMapSelectionController:self];
			break;
			
		case MapSelectionControllerSegmentRecents:
			vc = [[RecentSearchesViewController alloc] initWithMapSelectionController:self];
			break;
		
		case MapSelectionControllerSegmentBrowse:
			vc = [[CategoriesTableViewController alloc] initWithMapSelectionController:self];
			[(CategoriesTableViewController*)vc setTopLevel:YES];
			break;
			
		default:
			break;
	}
	
	if(vc) {
		[self setViewControllers:@[vc]];
    }
}

@end
