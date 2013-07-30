#import "LibrariesBookDetailViewController.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "LibrariesModule.h"
#import "Foundation+MITAdditions.h"
#import "BookDetailTableViewCell.h"
#import "WorldCatHoldingsViewController.h"
#import "LibrariesHoldingsDetailViewController.h"

typedef enum {
    kInfoSection = 0,
    kEmailAndCiteSection = 1,
    kMITHoldingSection = 2,
    kBLCHoldingSection = 3
} BookDetailSections;

typedef enum {
    BookLoadingStatusPartial,
    BookLoadingStatusFailed,
    BookLoadingStatusCompleted
} BookLoadingStatus;

@interface LibrariesBookDetailViewController ()
@property BookLoadingStatus loadingStatus;

- (void)loadBookDetails;
- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation LibrariesBookDetailViewController
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = @"Book Detail";
    }
    return self;
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.88
                                                       alpha:1.0];
    
    MITLoadingActivityView *activityView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
    activityView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
    activityView.backgroundColor = [UIColor colorWithWhite:0.88
                                                     alpha:1.0];
    [self.view addSubview:activityView];
    self.activityView = activityView;
    
    [self loadBookDetails];
}


- (void)viewDidUnload {
    [super viewDidUnload];
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

- (void)loadBookDetails {
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:LibrariesTag
                                                                             command:@"detail"
                                                                          parameters:@{@"id" : self.book.identifier}];
    
    self.loadingStatus = BookLoadingStatusPartial;
    
    request.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        [self.activityView removeFromSuperview];
        
        if (error) {
            [UIAlertView alertViewForError:error withTitle:@"WorldCat Book Details" alertViewDelegate:nil];
            self.loadingStatus = BookLoadingStatusFailed;

        } else {
            [self.book updateDetailsWithDictionary:content];
            
            NSMutableArray *bookAttribs = [NSMutableArray array];
            
            // title
            [bookAttribs addObject:[BookDetailTableViewCell 
                                    displayStringWithTitle:self.book.title
                                    subtitle:nil
                                    separator:nil
                                    fontSize:BookDetailFontSizeTitle]];

            // year; authors
            [bookAttribs addObject:[BookDetailTableViewCell
                                    displayStringWithTitle:nil
                                    subtitle:[self.book yearWithAuthors]
                                    separator:nil
                                    fontSize:BookDetailFontSizeDefault]];
            
            // format
            if (self.book.formats.count) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"Format" 
                                        subtitle:[self.book.formats componentsJoinedByString:@","] 
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
            }

            // summary
            if (self.book.summarys.count) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"Summary"
                                        subtitle:[self.book.summarys componentsJoinedByString:@"; "]
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
            }

            // publisher
            NSArray *addressesWithPublishers = [self.book addressesWithPublishers];
            if ([addressesWithPublishers count] > 0) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"Publisher"
                                        subtitle:[addressesWithPublishers componentsJoinedByString:@"; "]
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
            }

            // edition
            if (self.book.editions.count) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"Edition"
                                        subtitle:[self.book.editions componentsJoinedByString:@", "]
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
            }

            // description
            if (self.book.extents.count) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"Description"
                                        subtitle:[self.book.extents componentsJoinedByString:@", "]
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
            }

            // isbn
            if (self.book.isbns.count) {
                [bookAttribs addObject:[BookDetailTableViewCell 
                                        displayStringWithTitle:@"ISBN"
                                        subtitle:[self.book.isbns componentsJoinedByString:@" : "]
                                        separator:@": "
                                        fontSize:BookDetailFontSizeDefault]];
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

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 2; // one for book info, one for email & cite
    
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger numHoldings = self.book.holdings.count;
        if (self.book.holdings[MITLibrariesOCLCCode]) {
            sections++; // one section for MIT holdings
            numHoldings--;
        }
        
        if (numHoldings > 0) {
            sections++; // one section for all other holdings
        }
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger rows = 0;
        switch (section) {
            case kInfoSection:
                rows = self.bookInfo.count;
                break;
            case kEmailAndCiteSection:
                rows = 1;
                break;
            case kMITHoldingSection: {
                WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                rows = [[mitHoldings libraryAvailability] count] + 1;
                break;
            }
            default: // one of the holdings sections
                rows = 1;
                break;
        }
        return rows;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *infoIdentifier = @"info";
    static NSString *availabilityIdentifier = @"availability";
    static NSString *defaultIdentifier = @"default";
    
    UITableViewCell *cell = nil; 
    
    switch (indexPath.section) {
        case kInfoSection: {
            BookDetailTableViewCell *bookDetailCell = [tableView dequeueReusableCellWithIdentifier:infoIdentifier];
            if (!cell) {
                bookDetailCell = [[BookDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:infoIdentifier];
            }
            
            bookDetailCell.displayString = self.bookInfo[indexPath.row];
            cell = bookDetailCell;
            break;
        }
            
        case kMITHoldingSection: {
            NSString *reuseIdentifier = (indexPath.row == 0) ? defaultIdentifier : availabilityIdentifier;
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
            
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:reuseIdentifier];
            }
            
            [self configureCell:cell forRowAtIndexPath:indexPath];
            break;
        }
            
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:defaultIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:defaultIdentifier];
            }
            [self configureCell:cell forRowAtIndexPath:indexPath];
            break;
        }
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.textLabel.text = @"Email & Cite Item";
            break;
        case kMITHoldingSection: {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            switch (indexPath.row) {
                case 0:
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.text = @"Request Item";
                    break;
                default: {
                    WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                    NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                    NSArray *libraries = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                    
                    NSString *location = libraries[indexPath.row - 1];
                    NSUInteger available = [mitHoldings inLibraryCountForLocation:location];
                    NSUInteger total = [libraryAvailability[location] count];
                    
                    cell.textLabel.text = location;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu of %lu available", (unsigned long)available, (unsigned long)total];
                    cell.detailTextLabel.numberOfLines = 1;
                    cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
            }
            break;
        }
        case kBLCHoldingSection:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = @"View Holdings";
            break;
        default:
            break;
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = tableView.rowHeight;
    switch (indexPath.section) {
        case kInfoSection: {
            NSAttributedString *displayString = self.bookInfo[indexPath.row];
            height = [BookDetailTableViewCell sizeForDisplayString:displayString tableView:tableView].height + 8;
            break;
        }
        case kMITHoldingSection: {
            if (indexPath.row >= 1) {
                WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                NSArray *libraries = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                NSString *location = libraries[indexPath.row - 1];
                NSUInteger available = [mitHoldings inLibraryCountForLocation:location];
                NSUInteger total = [libraryAvailability[location] count];
                
                NSString *detail = [NSString stringWithFormat:@"%lu of %lu available", (unsigned long)available, (unsigned long)total];
                
                CGSize titleSize = [location sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE]
                                     constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000.0) 
                                         lineBreakMode:UILineBreakModeWordWrap];
                
                CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE]
                                       constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000.0) 
                                           lineBreakMode:UILineBreakModeWordWrap];
                
                height = titleSize.height + detailSize.height + 2.0 * 10.0;
            }
            break;
        }
        default:
            break;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            if ([MFMailComposeViewController canSendMail]) {
                NSString *subject = [NSString stringWithFormat:@"MIT Libraries Item Details for: %@", self.book.title];
                NSString *body = self.book.emailAndCiteMessage;
                
                MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                [mailView setMailComposeDelegate:self];
                [mailView setSubject:subject];
                [mailView setMessageBody:body isHTML:YES];
                [self presentModalViewController:mailView animated:YES]; 
            }
            break;
        case kMITHoldingSection:
        {
            WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
            
            if (indexPath.row == 0) {
                NSURL *url = [NSURL URLWithString:mitHoldings.url];
                
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                NSArray *locations = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                NSString *location = locations[indexPath.row - 1];
                NSArray *holdings = libraryAvailability[location];
                
                LibrariesHoldingsDetailViewController *detailVC = [[LibrariesHoldingsDetailViewController alloc] initWithHoldings:holdings];
                detailVC.title = location;
                [self.navigationController pushViewController:detailVC
                                                     animated:YES];
                [tableView deselectRowAtIndexPath:indexPath
                                         animated:YES];
            }
            break;
        }
        case kBLCHoldingSection:
        {
            WorldCatHoldingsViewController *vc = [[WorldCatHoldingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            vc.book = self.book;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case kMITHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                title = @"MIT Libraries";
            }
            break;
        case kBLCHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                title = @"Boston Library Consortium";
            }
            break;
        case kEmailAndCiteSection:
        case kInfoSection:
        default:
            break;
    }
	return [UITableView groupedSectionHeaderWithTitle:title];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kMITHoldingSection:
        case kBLCHoldingSection:
            return GROUPED_SECTION_HEADER_HEIGHT;
        case kEmailAndCiteSection:
        case kInfoSection:
        default:
            return 0;
    }
}

#pragma mark - MFMailComposeViewController Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}

@end
