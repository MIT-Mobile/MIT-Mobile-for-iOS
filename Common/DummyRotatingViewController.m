#import "DummyRotatingViewController.h"


@implementation DummyRotatingViewController

@synthesize canRotate;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return canRotate || interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    [super dealloc];
}


@end
