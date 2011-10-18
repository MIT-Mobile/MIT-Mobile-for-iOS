//
//  ThankYouViewController.m
//  MIT Mobile
//
//  Created by Jim Kang on 10/17/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "ThankYouViewController.h"


@implementation ThankYouViewController

@synthesize thankYouLabel;
@synthesize thankYouText;
@synthesize doneBlock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Thank You";
    }
    return self;
}

- (void)dealloc
{
    [doneBlock release];
    [thankYouText release];
    [thankYouLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.thankYouLabel.text = self.thankYouText;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Actions
- (IBAction)returnToHomeButtonTapped:(id)sender
{
    [self dismissModalViewControllerAnimated:NO];
    if (self.doneBlock)
    {
        self.doneBlock();
    }
}

@end
