#import "MITDatePickerViewController.h"

@interface MITDatePickerViewController ()

@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerView;

@end

@implementation MITDatePickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Go to Date";
    
    if (!self.shouldHideCancelButton) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithTitle:@"Go" style:UIBarButtonItemStylePlain target:self action:@selector(goPressed)];
    self.navigationItem.rightBarButtonItem = goButton;
    
    if (self.startDate) {
        self.datePickerView.date = self.startDate;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancelPressed
{
    [self.delegate datePickerDidCancel:self];
}

- (void)goPressed
{
    [self.delegate datePicker:self didSelectDate:self.datePickerView.date];
}

#pragma mark - Start Date

- (void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;
    if (self.datePickerView) {
        self.datePickerView.date = startDate;
    }
}

@end
