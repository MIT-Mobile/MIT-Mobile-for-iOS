//
//  MITScannerDetailViewController.m
//  MIT Mobile
//

#import "MITScannerDetailViewController.h"
#import "QRReaderResult.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "MITScannerDetailTableViewCell.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"

NSString * const kCodeType = @"codeType";
NSString * const kCodeDisplayType = @"kCodeDisplayType";
NSString * const kCodeDisplayName = @"kCodeDisplayName";
NSString * const kActions = @"kActions";
NSString * const kActionTitle = @"kActionTitle";
NSString * const kActionSubtitle = @"kActionSubtitle";
NSString * const kActionURL = @"kActionUrl";

@interface MITScannerDetailViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSOperation *urlMappingOperation;

@property (strong, nonatomic) NSMutableDictionary *scannerCodeParams;

@end

@interface MITScannerDetailViewController (ScannerCodeParser)
- (void)requestScanInfoFromServer;
@end

@interface MITScannerDetailViewController (TableViewDelegate) <UITableViewDelegate, UITableViewDataSource>
@end

#pragma mark - Implementations
@implementation MITScannerDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.tableView setTableFooterView:[UIView new]];
    [self.tableView registerNib:[UINib nibWithNibName:@"MITScannerDetailTableViewCell" bundle:nil] forCellReuseIdentifier:@"detailCell"];
    
    if( NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 ) {
        self.tableView.estimatedRowHeight = 55.0;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
    }
    
    self.navigationItem.title = @"Scan Detail";

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(shareButtonTapped:)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self tableViewHeaderDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self requestScanInfoFromServer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.urlMappingOperation cancel];
}

- (void)tableViewHeaderDidLoad
{
    UIImageView *headerView = (UIImageView *)[self.tableView tableHeaderView];
    
    if (self.scanResult.scanImage) {
        headerView.image = self.scanResult.scanImage;
    } else {
        headerView.image = [UIImage imageNamed:MITImageScannerMissingImage];
    }
}

- (void)shareButtonTapped:(id)sender
{
    NSMutableArray *activityItems = [NSMutableArray array];
    if( self.scanResult.text != nil )
    {
        [activityItems addObject:self.scanResult.text];
    }
    
    UIActivityViewController *sharingViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                        applicationActivities:nil];
    sharingViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact];
    
    if( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:sharingViewController];
        [popoverController setPopoverContentSize:CGSizeMake(100, 100)];
        [popoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        [self presentViewController:sharingViewController animated:YES completion:nil];
    }
}

- (void)doneButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate detailFormSheetViewDidDisappear];
    }];
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm a"];
    }
    return dateFormatter;
}

@end

@implementation MITScannerDetailViewController (TableViewDelegate)

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 )
    {
        return UITableViewAutomaticDimension;
    }
    
    return 80;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( self.scannerCodeParams == nil )
    {
        // not ready to display yet.. waiting for a response from server
        return 0;
    }
    
    return 2 + [self.scannerCodeParams[kActions] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForMITPropertyTagAtIndexPath:indexPath];
}

- (MITScannerDetailTableViewCell *)cellForMITPropertyTagAtIndexPath:(NSIndexPath *)indexPath
{
    MITScannerDetailTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"detailCell" forIndexPath:indexPath];
    
    cell.accessoryView = nil;
    
    if( indexPath.row == 0 )
    {
        cell.cellHeaderTitle.text = self.scannerCodeParams[kCodeDisplayType];
        [cell.cellHeaderTitle sizeToFit];
        
        cell.cellDescription.text = self.scannerCodeParams[kCodeDisplayName];
        cell.cellDescription.numberOfLines = 0;
        [cell.cellDescription setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f]];
        [cell.cellDescription sizeToFit];
        
        [cell removeLineSeparator];
    }
    else if( indexPath.row == 1 )
    {
        cell.cellHeaderTitle.text = @"scanned";
        [cell.cellHeaderTitle sizeToFit];
        
        cell.cellDescription.text = [[self dateFormatter] stringFromDate:self.scanResult.date];
        [cell.cellDescription setFont:[UIFont systemFontOfSize:17.0f]];
        [cell.cellDescription sizeToFit];
        
        if( [self.tableView numberOfRowsInSection:0] == 2 )
        {
            [cell removeLineSeparator];
        }
    }
    else if( indexPath.row == 2 )
    {
        if( [self.scannerCodeParams[kActions] count] > 0 )
        {
            NSDictionary *action = self.scannerCodeParams[kActions][0];
            cell.cellHeaderTitle.text = action[kActionTitle];
            [cell.cellHeaderTitle setFont:[UIFont systemFontOfSize:17]];
            [cell.cellHeaderTitle sizeToFit];
            
            cell.cellDescription.text = action[kActionSubtitle];
            [cell.cellDescription setFont:[UIFont systemFontOfSize:14]];
            [cell.cellDescription setTextColor:[UIColor mit_greyTextColor]];
            [cell.cellDescription sizeToFit];
            
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageActionExternal]
                                                   highlightedImage:[UIImage imageNamed:MITImageActionExternalHighlight]];
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        [cell removeLineSeparator];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if( indexPath.row != 2 )
    {
        return;
    }
    
    NSArray *codeActions = self.scannerCodeParams[kActions];
    if( [codeActions count] > 0 )
    {
        NSDictionary *action = codeActions[0];

        if( [[UIApplication sharedApplication] canOpenURL:action[kActionURL]] )
        {
            [[UIApplication sharedApplication] openURL:action[kActionURL]];
        }
    }
}

@end

@implementation MITScannerDetailViewController (ScannerCodeParser)

- (void)requestScanInfoFromServer
{
    NSURL *url = [NSURL URLWithString:@"http://mobile-dev.mit.edu/apis/scanner/mappings/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                              parameters:@{@"q" : self.scanResult.text}
                                                  method:@"GET"];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    __weak MITScannerDetailViewController *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *codeInfo) {
        [weakSelf handleScanInfoResponse:codeInfo error:nil];
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        [weakSelf handleScanInfoResponse:nil error:error];
    }];
    
    self.urlMappingOperation = requestOperation;
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (void)handleScanInfoResponse:(NSDictionary *)codeInfo error:(NSError *)error
{
    self.scannerCodeParams = [NSMutableDictionary dictionary];
    
    BOOL validResponse = (error == nil) && codeInfo[@"type"] != nil;
    NSArray *actions = codeInfo[@"actions"];
    validResponse = validResponse && actions && [actions isKindOfClass:[NSArray class]];
    
    if( validResponse == NO )
    {
        [self parseNonServerScannerCode];
        [self.tableView reloadData];
        return;
    }
    
    NSString *codeType = codeInfo[@"type"];
    if( codeType != nil )
    {
        [self.scannerCodeParams setObject:codeType forKey:kCodeType];
    }
    
    NSString *codeDisplayType = codeInfo[@"display_type"];
    if( codeDisplayType != nil )
    {
        [self.scannerCodeParams setObject:codeDisplayType forKey:kCodeDisplayType];
    }
    
    NSString *displayName = codeInfo[@"display_name"];
    if( displayName != nil )
    {
        [self.scannerCodeParams setObject:displayName forKey:kCodeDisplayName];
    }
    
    NSMutableArray *codeActions = [NSMutableArray array];
    for( NSDictionary *actionDict in actions )
    {
        NSString *actionTitle = actionDict[@"title"];
        NSString *actionUrl = actionDict[@"url"];
        
        if( actionTitle != nil && actionUrl != nil )
        {
            NSString *actionSubtitle = [codeType isEqualToString:@"tag"] ? @"Property Office Use Only" : @"";
            
            [codeActions addObject:@{kActionTitle : actionTitle,
                                     kActionURL : [NSURL URLWithString:actionUrl],
                                     kActionSubtitle : actionSubtitle}];
        }
    }
    
    [self.scannerCodeParams setObject:codeActions forKey:kActions];
    
    [self.tableView reloadData];
}

- (void)parseNonServerScannerCode
{
    NSURL *url = [NSURL URLWithString:self.scanResult.text];
    
    if( [[UIApplication sharedApplication] canOpenURL:url] )
    {
        [self.scannerCodeParams setObject:@"url" forKey:kCodeDisplayType];
        
        [self.scannerCodeParams setObject:@[@{kActionTitle: @"Open in Safari", kActionURL: url}]
                                   forKey:kActions];
    }
    else
    {
        [self.scannerCodeParams setObject:@"other" forKey:kCodeDisplayType];
    }
    
    [self.scannerCodeParams setObject:self.scanResult.text forKey:kCodeDisplayName];
}

@end
