#import "LibrariesBookDetailViewController.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "MITModuleList.h"
#import "LibrariesModule.h"

#define TITLE_ROW 0
#define YEAR_AUTHOR_ROW 1
#define ISBN_ROW 2
#define HORIZONTAL_MARGIN 10
#define VERITCAL_PADDING 5

@interface LibrariesBookDetailViewController (Private)
- (void)loadBookDetails;
- (void)updateUI;
@end

@implementation LibrariesBookDetailViewController
@synthesize book;
@synthesize activityView;
@synthesize loadingStatus;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
    self.activityView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger rows = 2;
        if ([self.book isbn]) {
            rows++;
        }
        return rows;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case TITLE_ROW:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Title"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Title"];
                UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERITCAL_PADDING, 
                                                                            tableView.frame.size.width - 2*HORIZONTAL_MARGIN, [self titleHeight:tableView])] autorelease];
                label.numberOfLines = 0;
                label.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
                label.textColor = CELL_STANDARD_FONT_COLOR;
                label.text = self.book.title;
                [cell.contentView addSubview:label];
            }
            return cell;
        }
            
        case YEAR_AUTHOR_ROW:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AuthorYear"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AuthorYear"];
                UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERITCAL_PADDING, 
                                                                            tableView.frame.size.width - 2*HORIZONTAL_MARGIN , [self authorYearHeight:tableView])] autorelease];
                label.numberOfLines = 0;
                label.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
                label.textColor = CELL_DETAIL_FONT_COLOR;
                label.text = [self.book authorYear];
                [cell.contentView addSubview:label];
            }
            return cell;
        }            
        
        case ISBN_ROW:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ISBN"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ISBN"];
                UIFont *fieldFont = [UIFont fontWithName:BOLD_FONT size:CELL_DETAIL_FONT_SIZE];
                CGSize fieldSize = [@"ISBN:" sizeWithFont:fieldFont];
                
                UILabel *fieldLabel = [[[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERITCAL_PADDING, 
                                                                            fieldSize.width, fieldSize.height)] autorelease];
                fieldLabel.text = @"ISBN:";
                fieldLabel.font = fieldFont;
                
                UILabel *valueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + fieldSize.width + 5, VERITCAL_PADDING, 200, fieldSize.height)] autorelease];
                valueLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
                valueLabel.text = [self.book isbn];
                
                [cell.contentView addSubview:fieldLabel];
                [cell.contentView addSubview:valueLabel];
            }
            return cell;
        }
            
            
        default:
            break;
    }
    return nil;
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case TITLE_ROW:
            return [self titleHeight:tableView] + 2*VERITCAL_PADDING;
            
        case YEAR_AUTHOR_ROW:
            return [self authorYearHeight:tableView] + 2*VERITCAL_PADDING;
        default:
            break;
    }
    return 25;
    
}

@end
