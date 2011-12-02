#import "CorridorListViewController.h"
#import "MITJSON.h"
#import "CorridorStory.h"
#import "CoreDataManager.h"
#import "CorridorDetailViewController.h"
#import "UIKit+MITAdditions.h"

#define THUMBNAIL_WIDTH 76.0
#define ACCESSORY_WIDTH_PLUS_PADDING 18.0
#define STORY_TEXT_PADDING_TOP 7.0 // with 15pt titles, makes for 8px of actual whitespace
#define STORY_TEXT_PADDING_BOTTOM 8.0 // from baseline of 12pt font, is roughly 5px
#define STORY_TEXT_PADDING_LEFT 9.0
#define STORY_TEXT_PADDING_RIGHT 8.0
#define STORY_TEXT_WIDTH (320.0 - STORY_TEXT_PADDING_LEFT - STORY_TEXT_PADDING_RIGHT - ACCESSORY_WIDTH_PLUS_PADDING) // 8px horizontal padding
#define STORY_TEXT_HEIGHT (THUMBNAIL_WIDTH - STORY_TEXT_PADDING_TOP - STORY_TEXT_PADDING_BOTTOM) // 8px vertical padding (bottom is less because descenders on dekLabel go below baseline)
#define STORY_LABEL_SPACING 2.0
#define STORY_TITLE_FONT_SIZE 18.0
#define STORY_DEK_FONT_SIZE 13.0

@interface CorridorListViewController (Private)

- (void)setupFetchedResultsController;
- (void)loadMore;
- (NSIndexPath *)moreRowIndexPath;
- (void)deleteStoriesOnQuit:(NSNotification *)aNotification;
- (void)resetToIdle:(id)sender;

@end

@implementation CorridorListViewController

@synthesize frc, loadingState;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.title = @"The Corridor";
	loadingState = @"idle";
	
	[self deleteStoriesOnQuit:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteStoriesOnQuit:) name:@"UIApplicationWillTerminateNotification" object:nil];
	
	[self setupFetchedResultsController];
	[self loadMore];
}

- (void)setupFetchedResultsController {
	if (frc) {
		return;
	}
	
	NSManagedObjectContext *context = [CoreDataManager managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	// set up entity and sorting
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CorridorStory" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
	NSSortDescriptor *orderSort = [NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:NO];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:dateSort, orderSort, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	self.frc = [[[NSFetchedResultsController alloc]
				initWithFetchRequest:fetchRequest
				managedObjectContext:context
				sectionNameKeyPath:nil
				cacheName:nil] autorelease];
//	self.frc.delegate = self;
	[fetchRequest release];
	[frc release];
	
	NSError *error = nil;
	BOOL success = [frc performFetch:&error];
	if (!success) {
		ELog(@"%s failed", __FUNCTION__);
        
        if (error)
            ELog(@"%@", [error description]);
	}
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[frc sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[frc sections] objectAtIndex:section];
		return [sectionInfo numberOfObjects] + 1;
	}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath isEqual:[self moreRowIndexPath]]) {
		return 60;
	}
	else {
		return THUMBNAIL_WIDTH;
	}
}

- (NSIndexPath *)moreRowIndexPath {
	
	NSUInteger section = [self numberOfSectionsInTableView:self.tableView] - 1;
	NSUInteger row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row
												inSection:section];
	return indexPath;
}
	 
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	CorridorStory *story = [frc objectAtIndexPath:indexPath];

	UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
	UILabel *dekLabel = (UILabel *)[cell viewWithTag:2];
	
	titleLabel.text = story.title;
	dekLabel.text = story.plainBody;
	
	// Calculate height
	CGFloat availableHeight = STORY_TEXT_HEIGHT;
	CGSize titleDimensions = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
	availableHeight -= titleDimensions.height + STORY_LABEL_SPACING;
	
	CGSize dekDimensions = CGSizeZero;
	// if not even one line will fit, don't show the deck at all
	if (availableHeight > dekLabel.font.leading) {
		dekDimensions = [dekLabel.text sizeWithFont:dekLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
	}
	
	
	titleLabel.frame = CGRectMake(STORY_TEXT_PADDING_LEFT, 
								  STORY_TEXT_PADDING_TOP, 
								  STORY_TEXT_WIDTH, 
								  titleDimensions.height);
	dekLabel.frame = CGRectMake(STORY_TEXT_PADDING_LEFT, 
								ceil(CGRectGetMaxY(titleLabel.frame) + STORY_LABEL_SPACING), 
								STORY_TEXT_WIDTH, 
								dekDimensions.height);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    UITableViewCell *cell = nil; 

	// More button - last row of last section
	if ([indexPath isEqual:[self moreRowIndexPath]]) {
		static NSString *MoreIdentifier = @"MoreCell";
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MoreIdentifier] autorelease];
			
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.textAlignment = UITextAlignmentCenter;

			if ([loadingState isEqualToString:@"idle"] ) {
				cell.textLabel.textColor = [UIColor colorWithHexString:@"#990000"];
				cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
				cell.textLabel.text = @"Load more...";
			} else if ([loadingState isEqualToString:@"loading"]) {
				cell.textLabel.textColor = [UIColor colorWithHexString:@"#999999"];
				cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
				cell.textLabel.text = @"Loading...";
			} else if ([loadingState isEqualToString:@"nothingNew"]) {
				cell.textLabel.textColor = [UIColor colorWithHexString:@"#999999"];
				cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
				cell.textLabel.text = @"End of the Corridor";
			}
		}
	}
	// Everything else
	else {
		static NSString *CorridorIdentifier = @"CorridorCell";
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CorridorIdentifier] autorelease];
			
			// Title View
			UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			titleLabel.tag = 1;
			titleLabel.font = [UIFont boldSystemFontOfSize:STORY_TITLE_FONT_SIZE];
			titleLabel.numberOfLines = 0;
			titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
			titleLabel.highlightedTextColor = [UIColor whiteColor];
			[cell.contentView addSubview:titleLabel];
			[titleLabel release];
			
			// Summary View
			UILabel *dekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			dekLabel.tag = 2;
			dekLabel.font = [UIFont systemFontOfSize:STORY_DEK_FONT_SIZE];
			dekLabel.textColor = [UIColor colorWithHexString:@"#333333"];
			dekLabel.highlightedTextColor = [UIColor whiteColor];
			dekLabel.numberOfLines = 0;
			dekLabel.lineBreakMode = UILineBreakModeTailTruncation;
			dekLabel.highlightedTextColor = [UIColor whiteColor];
			[cell.contentView addSubview:dekLabel];
			[dekLabel release];
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		[self configureCell:cell atIndexPath:indexPath];
	}

    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// More button
	if ([indexPath isEqual:[self moreRowIndexPath]])  {
		if ([loadingState isEqualToString:@"idle"]) {
			[self loadMore];
		}
		if ([loadingState isEqualToString:@"nothingNew"]) {
			loadingState = @"idle";
			// cancel the pending auto-update, as it would cause a momentary fade of the "Load more..." text
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetToIdle:) object:nil];
		}
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	// Everything else
	else {
		CorridorDetailViewController *detailViewController = [[CorridorDetailViewController alloc] initWithNibName:nil bundle:nil];
		detailViewController.story = [frc objectAtIndexPath:indexPath];
		
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
	}
}

- (void)loadMore {
	loadingState = @"loading";
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self moreRowIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
	
	// make request to mobile server for next offset
	NSUInteger offset = [[frc fetchedObjects] count];
	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	// http://mobile-dev.mit.edu/api/?module=corridor&command=list&offset=2
	BOOL dispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"corridor", @"module", @"list", @"command", [NSString stringWithFormat:@"%d", offset], @"offset", nil]];
	if (!dispatched) {
		DLog(@"%@", @"problem making corridor api request");
	}
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
	if ([result isKindOfClass:[NSArray class]]) {
		NSArray *stories = result;
		[stories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj isKindOfClass:[NSDictionary class]]) {
				[CorridorStory corridorStoryWithDictionary:obj];
			}
		}];
		[CoreDataManager saveData];
	}

	NSUInteger oldTotal = [[frc fetchedObjects] count];
	NSError *error;
	BOOL success = [frc performFetch:&error];
	if (!success) {
		ELog(@"%s failed", __FUNCTION__);
		ELog(@"%@", [error description]);
	}

	NSUInteger newTotal = [[frc fetchedObjects] count];
	if (newTotal > oldTotal) {
		loadingState = @"idle";
		[self.tableView reloadData];
	} else {
		loadingState = @"nothingNew";
		[self performSelector:@selector(resetToIdle:) withObject:nil afterDelay:1.5];
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self moreRowIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	loadingState = @"idle";
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self moreRowIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
	
	return YES;
}

- (void)resetToIdle:(id)sender {
	loadingState = @"idle";
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self moreRowIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            // Reloading the section inserts a new row and ensures that titles are updated appropriately.
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillTerminateNotification" object:nil];

	self.frc.delegate = nil;
	self.frc = nil;
    [super dealloc];
}

- (void)deleteStoriesOnQuit:(NSNotification *)aNotification {
	NSArray *allStories = [CoreDataManager objectsForEntity:@"CorridorStory" matchingPredicate:[NSPredicate predicateWithValue:TRUE]];
	[CoreDataManager deleteObjects:allStories];
	[CoreDataManager saveData];
}

@end

