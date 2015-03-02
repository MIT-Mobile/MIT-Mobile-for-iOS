#import "MITScannerHistoryViewController.h"
#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "CoreDataManager.h"
#import "MITScannerDetailViewController.h"

#import "UIImage+Resize.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"
#import "SVProgressHUD.h"

#define NO_INDEX_TO_OPEN -1

@interface MITScannerHistoryViewController (MITActionSheetHandler) <UIActionSheetDelegate>
@end

@interface MITScannerHistoryViewController ()<UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (strong) NSFetchedResultsController *fetchController;
@property (strong) NSManagedObjectContext *fetchContext;

@property (strong) QRReaderHistoryData *scannerHistory;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) UIToolbar *multiEditToolbar;
@property (nonatomic, weak) UIBarButtonItem *deleteButton;

@end

@implementation MITScannerHistoryViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        NSManagedObjectContext *fetchContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        fetchContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
        fetchContext.undoManager = nil;
        fetchContext.stalenessInterval = 0;
        
        self.scannerHistory = [[QRReaderHistoryData alloc] initWithManagedContext:fetchContext];
        self.fetchContext = fetchContext;
        
        NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                       ascending:NO];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"QRReaderResult"];
        fetchRequest.sortDescriptors = @[dateDescriptor];
        
        self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:fetchContext
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
        self.fetchController.delegate = self;
        
        self.itemToOpenOnLoadIndex = NO_INDEX_TO_OPEN;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // make navigation bar visible
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
    [self.navigationController.navigationBar setTintColor:[UIColor mit_tintColor]];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    self.navigationItem.title = @"History";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.tintColor = [UIColor mit_tintColor];
    self.tableView.rowHeight = [QRReaderResult defaultThumbnailSize].height;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.fetchController performFetch:nil];
    
    [self.scannerHistory resetHistoryNewScanCounter];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if( self.itemToOpenOnLoadIndex != NO_INDEX_TO_OPEN )
    {
        QRReaderResult *result = [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForRow:self.itemToOpenOnLoadIndex inSection:0]];
        [self showDetailsForResult:result];
        
        // so that it only loads first item on initial launch.
        self.itemToOpenOnLoadIndex = NO_INDEX_TO_OPEN;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applicationDidEnterBackground:(id)sender
{
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

- (void)showDetailsForResult:(QRReaderResult *)result
{
    MITScannerDetailViewController *detailsVC = [[MITScannerDetailViewController alloc] init];
    detailsVC.scanResult = result;
    [self.navigationController pushViewController:detailsVC animated:YES];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellId = @"HistoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellId];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reusableCellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:16.0];
        
        UIView *selectedClearView = [[UIView alloc] initWithFrame:cell.frame];
        selectedClearView.backgroundColor = [UIColor clearColor];
        cell.multipleSelectionBackgroundView = selectedClearView;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    
    return [sectionInfo numberOfObjects];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteScanResults:@[result] withStatusMessage:@"Deleting"];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if( editing )
    {
        [self.tableView setEditing:YES animated:YES];
        [self setMultiEditToolbarHidden:NO];
    }
    else
    {
        [self.tableView setEditing:NO animated:YES];
        [self setMultiEditToolbarHidden:YES];
    }
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = result.text;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    CGRect frame = cell.imageView.frame;
    frame.size = result.thumbnail.size;
    cell.imageView.frame = frame;
    cell.imageView.image = result.thumbnail;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.tableView.editing )
    {
        [self updateDeleteButtonTitle];
        
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self showDetailsForResult:[self.fetchController objectAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.tableView.editing )
    {
        [self updateDeleteButtonTitle];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    [self updateDeleteButtonTitle];
}

#pragma mark - multi edit logic

- (UIToolbar *)multiEditToolbar
{
    if ( _multiEditToolbar == nil )
    {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        toolbar.barStyle = UIBarStyleDefault;
        toolbar.hidden = YES;
        toolbar.tintColor = [UIColor mit_tintColor];
        
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDelete:)];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        toolbar.items = @[flexibleItem, deleteItem, flexibleItem];
        
        [toolbar sizeToFit];
        
        CGRect toolbarFrame = toolbar.frame;
        toolbarFrame.origin.y = self.view.frame.size.height - toolbarFrame.size.height;
        toolbarFrame.size.width = self.view.frame.size.width;
        toolbar.frame = toolbarFrame;
        
        [self.view addSubview:toolbar];
        _multiEditToolbar = toolbar;
        _deleteButton = deleteItem;
    }
    
    return _multiEditToolbar;
}

- (void)setMultiEditToolbarHidden:(BOOL)isHidden
{
    [self.multiEditToolbar setHidden:isHidden];
    
    // update tableView content size based on added toolbar at the bottom
    CGFloat updatedContentHeight = isHidden ? (self.tableView.contentSize.height - self.multiEditToolbar.frame.size.height) : (self.tableView.contentSize.height + self.multiEditToolbar.frame.size.height);
    self.tableView.contentSize = CGSizeMake(self.tableView.contentSize.width, updatedContentHeight);
    
    // reset to 'delete all' every time bar gets unhidden
    if( isHidden == NO ) {
        [self updateDeleteButtonTitle];
    }
}

- (void)updateDeleteButtonTitle
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    self.deleteButton.title = [selectedRows count] > 0 ? @"Delete" : @"Delete All";
}

- (void)didTapDelete:(id)sender
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    if( [selectedRows count] > 0 )
    {
        [self deleteItemsAtIndexPaths:selectedRows];
    }
    else
    {
        [self deleteAll];
    }
}

- (void)deleteAll
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete All"
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *scanResults = [NSMutableArray array];
    for( NSIndexPath *indexPath in indexPaths )
    {
        [scanResults addObject:[self.fetchController objectAtIndexPath:indexPath]];
    }
    
    [self deleteScanResults:scanResults withStatusMessage:@"Deleting"];
}

- (void)deleteScanResults:(NSArray *)results withStatusMessage:(NSString *)message
{
    [SVProgressHUD showWithStatus:message maskType:SVProgressHUDMaskTypeGradient];
    
    [self.scannerHistory deleteScanResults:results completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if( [self.fetchContext hasChanges] )
            {
                NSError *error;
                [self.fetchContext save:&error];
            }
            
            if( self.tableView.isEditing )
            {
                [self setEditing:NO animated:YES];
            }
            
            [SVProgressHUD dismiss];
        });
    }];
}

@end

@implementation MITScannerHistoryViewController (MITActionSheetHandler)

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex != actionSheet.cancelButtonIndex )
    {
        [self deleteScanResults:[self.fetchController fetchedObjects] withStatusMessage:@"Deleting all history"];
    }
}

@end

