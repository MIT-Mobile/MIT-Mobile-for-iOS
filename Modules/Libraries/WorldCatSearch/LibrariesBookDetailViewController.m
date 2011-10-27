#import "LibrariesBookDetailViewController.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "LibrariesModule.h"
#import "Foundation+MITAdditions.h"


#define TITLE_ROW 0
#define YEAR_AUTHOR_ROW 1
#define ISBN_ROW 2

static const CGFloat kWebViewHeight = 300.0f;

typedef enum 
{
//    kInfoSection = 0,
    kEmailAndCiteSection = 0
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
- (NSString *)infoHeaderHtml;

@end

@implementation LibrariesBookDetailViewController
@synthesize book;
@synthesize activityView;
@synthesize loadingStatus;

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
    NSInteger sections = 2;
    // TODO: When available libraries are included in the book object, use a 
    // section for each of them.
    sections++;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
    if (self.loadingStatus == BookLoadingStatusCompleted) {        
        NSInteger rows = 0;
        if (kEmailAndCiteSection == section)
        {
            rows = 1;
        }
        else
        {
            // This will be one of the libraries sections.
            // TODO: When libraries info is available, in the book object, 
            // check to see if the library corresponding to the section is 
            // MIT. If so, there should be two rows: one for Request Item, 
            // and one for number of copies.
            rows = 1;
        }
        return rows;
    }
    
    return 0;
}

- (void)configureCell:(UITableViewCell *)cell 
    forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (kEmailAndCiteSection == indexPath.section) 
    {
        // TODO: Mail accessory view.
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"Email & Cite Item";
    }
    else
    {
        // This will be one of the libraries sections.
        cell.textLabel.text = @"View Holdings";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell *cell = 
    [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell)
    {
        cell = 
        [[[UITableViewCell alloc] 
          initWithStyle:UITableViewCellStyleDefault 
          reuseIdentifier:@"Cell"] autorelease];
    }
    [self configureCell:cell forRowAtIndexPath:indexPath];
        
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView 
viewForHeaderInSection:(NSInteger)section
{
    if (section == kEmailAndCiteSection)
    {
        UIWebView *webView = 
        [[[UIWebView alloc] initWithFrame:
          CGRectMake(HORIZONTAL_PADDING, VERTICAL_PADDING, 
                     tableView.frame.size.width - 2 * HORIZONTAL_PADDING, 
                     kWebViewHeight)] autorelease];
        //                webView.delegate = self;      
        // Make web view background transparent.
        webView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;
        webView.tag = kWebViewTag;
        
        [webView 
         loadHTMLString:[self infoHeaderHtml] baseURL:nil];
        
        // The web view is not wrapped in another view, it won't be 
        // transparent.
        UIView *wrapperView = 
        [[[UIView alloc] initWithFrame:
          CGRectMake(0, 0, tableView.frame.size.width, kWebViewHeight)] 
         autorelease];
        wrapperView.opaque = NO;
        wrapperView.backgroundColor = [UIColor clearColor];
        [wrapperView addSubview:webView];
        
        return wrapperView;        
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
    if (kEmailAndCiteSection == section)
    {
        return nil;
    }
    else
    {
        // This will be one of the libraries sections.
        // TODO: Return name of library corresponding to section.
        return @"MIT Libraries";
    }
}

- (CGFloat)tableView:(UITableView *)tableView 
heightForHeaderInSection:(NSInteger)section
{    
    if (kEmailAndCiteSection == section)
    {
        return kWebViewHeight;
    }
    else
    {
        // This will be one of the libraries sections.
        return 44.0f;
    }
}

#pragma mark Web view stuff

+ (NSString *)nonEmptyString:(NSString *)string
{
    if (!string)
    {
        return @"";
    }
    return string;
}

- (NSString *)infoHeaderHtml
{
    NSURL *baseURL = 
    [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = 
    [NSURL URLWithString:@"libraries/book_detail.html" relativeToURL:baseURL];
    NSError *error;
    NSMutableString *target = 
    [NSMutableString 
     stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!target) 
    {
        ELog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
    }
     
    
    [target 
     replaceOccurrencesOfStrings:
     [NSArray arrayWithObjects:
      @"__TITLE__", @"__AUTHORS__", @"__FORMAT__", @"__SUMMARY__",
      @"__PUBLISHER__", @"__DATE__", @"__EDITION__", @"__DESCRIPTION__", 
      @"__ISBN__", nil]
     withStrings:
     [NSArray arrayWithObjects:
      [[self class] nonEmptyString:self.book.title], 
      [[self class] nonEmptyString:
       [self.book.authors componentsJoinedByString:@", "]],
      @"Book", 
      [[self class] nonEmptyString:
       [self.book.summarys componentsJoinedByString:@"; "]],
      [[self class] nonEmptyString:
       [self.book.publishers componentsJoinedByString:@", "]], 
      @"Date",
      [[self class] nonEmptyString:
       [self.book.years componentsJoinedByString:@", "]], 
      @"Description",
      [[self class] nonEmptyString:[self.book isbn]], 
      nil] 
     options:NSLiteralSearch];
    
    return target;
}


@end
