#import "LibrariesBookDetailViewController.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "LibrariesModule.h"
#import "Foundation+MITAdditions.h"
#import "BookDetailTableViewCell.h"
#import "WorldCatHoldingsViewController.h"

#define TITLE_ROW 0
#define YEAR_AUTHOR_ROW 1
#define ISBN_ROW 2

static const CGFloat kWebViewHeight = 300.0f;

typedef enum 
{
    kInfoSection = 0,
    kEmailAndCiteSection = 1,
    kMITHoldingSection = 2,
    kBLCHoldingSection = 3
}
BookDetailSections;

typedef enum
{
    kWebViewTag = 0x438
}
BookDetailViewTags;

#define HORIZONTAL_MARGIN 10
#define VERTICAL_PADDING 5
#define HORIZONTAL_PADDING 5

@interface LibrariesBookDetailViewController (Private)
- (void)loadBookDetails;
- (void)updateUI;
- (void)configureCell:(UITableViewCell *)cell 
    forRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation LibrariesBookDetailViewController
@synthesize book;
@synthesize activityView;
@synthesize loadingStatus;
@synthesize bookInfo;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.activityView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor clearColor];
    self.activityView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
    self.activityView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.activityView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self loadBookDetails];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.activityView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSString *)subtitleDisplayStringHTML:(BOOL)isHTML
{
    NSString *result = nil;
    if (self.book) {
        NSMutableArray *subtitleParts = [NSMutableArray array];
        if (self.book.authors.count) {
            [subtitleParts addObject:[self.book.authors componentsJoinedByString:@", "]];
        }
        if (self.book.formats.count) {
            [subtitleParts addObject:[NSString stringWithFormat:@"Format: %@", [self.book.formats componentsJoinedByString:@"\n"]]];
        }
        
        NSString *separator = isHTML ? @"<br/>" : @"\n";
        result = [subtitleParts componentsJoinedByString:separator];
    }
    return result;
}

- (void)loadBookDetails {
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:self.book.identifier forKey:@"id"];
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:LibrariesTag command:@"detail" parameters:parameters] autorelease];
    
    self.loadingStatus = BookLoadingStatusPartial;
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        [self.activityView removeFromSuperview];
        
        if (error) {
            [MITMobileWebAPI showErrorWithHeader:@"WorldCat Book Details"];
            self.loadingStatus = BookLoadingStatusFailed;

        } else {
            [self.book updateDetailsWithDictionary:jsonResult];
            
            NSMutableArray *bookAttribs = [NSMutableArray array];
            
            // title, author, format
            NSString *bookTitle = self.book.title ? self.book.title : @"";
            NSString *bookSubtitle = [self subtitleDisplayStringHTML:NO];
            
            [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:bookTitle
                                                                          subtitle:bookSubtitle
                                                                         separator:@"\n"]];

            // summary
            if (self.book.summarys.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"Summary"
                                                                              subtitle:[self.book.summarys componentsJoinedByString:@"; "]
                                                                             separator:@": "]];
            }

            // publisher
            if (self.book.publishers.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"Publisher"
                                                                              subtitle:[self.book.publishers componentsJoinedByString:@"; "]
                                                                             separator:@": "]];
            }

            // date
            if (self.book.years.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"Date"
                                                                              subtitle:[self.book.years componentsJoinedByString:@", "]
                                                                             separator:@": "]];
            }
            
            // edition
            if (self.book.editions.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"Edition"
                                                                              subtitle:[self.book.editions componentsJoinedByString:@", "]
                                                                             separator:@": "]];
            }

            // description
            if (self.book.extents.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"Description"
                                                                              subtitle:[self.book.extents componentsJoinedByString:@", "]
                                                                             separator:@": "]];
            }

            // isbn
            if (self.book.isbns.count) {
                [bookAttribs addObject:[BookDetailTableViewCell displayStringWithTitle:@"ISBN"
                                                                              subtitle:[self.book.isbns componentsJoinedByString:@" : "]
                                                                             separator:@": "]];
            }
            
            self.bookInfo = [NSArray arrayWithArray:bookAttribs];

            self.loadingStatus = BookLoadingStatusCompleted;
            [self.tableView reloadData];
        }
    };
    
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:request];
}
    
- (CGFloat)titleHeight:(UITableView *)tableView {
    CGSize titleSize = [self.book.title sizeWithFont:
        [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE] 
                                   constrainedToSize:CGSizeMake(tableView.frame.size.width-2*HORIZONTAL_MARGIN, 400)];
    return titleSize.height;
}

- (CGFloat)authorYearHeight:(UITableView *)tableView {
    CGSize authorYearSize = [[self.book authorYear] sizeWithFont:
                             [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE] 
                                               constrainedToSize:CGSizeMake(tableView.frame.size.width-2*HORIZONTAL_MARGIN, 400)];
    return authorYearSize.height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 2; // one for book info, one for email & cite
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger numHoldings = self.book.holdings.count;
        if ([self.book.holdings objectForKey:MITLibrariesOCLCCode]) {
            sections++; // one section for MIT holdings
            numHoldings--;
        }
        if (numHoldings > 0) {
            sections++; // one section for all other holdings
        }
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger rows = 0;
        switch (section) {
            case kInfoSection:
                rows = self.bookInfo.count;
                break;
            case kEmailAndCiteSection:
                rows = 1;
                break;
            default: // one of the holdings sections
                rows = 1;
                break;
        }
        return rows;
    }
    
    return 0;
}

- (void)configureCell:(UITableViewCell *)cell 
    forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.textLabel.text = @"Email & Cite Item";
            break;
        case kMITHoldingSection:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.textLabel.text = @"Request Item";
            break;
        case kBLCHoldingSection:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"View Holdings";
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            if ([MFMailComposeViewController canSendMail]) {
                NSString *bodyString = [NSString stringWithFormat:
                                        @"<strong>%@</strong><br/>%@",
                                        self.book.title,
                                        [self subtitleDisplayStringHTML:YES]];
                
                MFMailComposeViewController *mailView = [[[MFMailComposeViewController alloc] init] autorelease];
                [mailView setMailComposeDelegate:self];
                [mailView setSubject:self.book.title];
                [mailView setMessageBody:bodyString isHTML:YES];
                [self presentModalViewController:mailView animated:YES]; 
            }
            break;
        case kMITHoldingSection:
        {
            WorldCatHolding *holding = [self.book.holdings objectForKey:MITLibrariesOCLCCode];
            NSURL *url = [NSURL URLWithString:holding.url];
            if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case kBLCHoldingSection:
        {
            WorldCatHoldingsViewController *vc = [[[WorldCatHoldingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            vc.book = self.book;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kInfoSection) {
        NSAttributedString *displayString = [self.bookInfo objectAtIndex:indexPath.row];
        return [BookDetailTableViewCell sizeForDisplayString:displayString tableView:tableView].height + 8;
    }
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *identifier = [NSString stringWithFormat:@"%d", indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        if (indexPath.section == kInfoSection) {
            cell = [[[BookDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:identifier] autorelease];
        } else {        
            cell = [[[LibrariesBorderedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                          reuseIdentifier:identifier] autorelease];
        }
    }

    if (indexPath.section == kInfoSection) {
        NSAttributedString *displayString = [self.bookInfo objectAtIndex:indexPath.row];
        BookDetailTableViewCell *bookCell = (BookDetailTableViewCell *)cell;
        bookCell.displayString = displayString;
    } else {
        LibrariesBorderedTableViewCell *borderCell = (LibrariesBorderedTableViewCell *)cell;
        if (indexPath.row == 0) {
            borderCell.cellPosition = borderCell.cellPosition | TableViewCellPositionFirst;
        }
        if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
            borderCell.cellPosition = borderCell.cellPosition | TableViewCellPositionLast;
        }
        
        [self configureCell:cell forRowAtIndexPath:indexPath];
    }
        
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    switch (section) {
        case kMITHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                return @"MIT Libraries";
            }
            break;
        case kBLCHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                return @"Boston Library Consortium";
            }
            break;
        case kEmailAndCiteSection:
        case kInfoSection:
        default:
            break;
    }
    return title;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error 
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
