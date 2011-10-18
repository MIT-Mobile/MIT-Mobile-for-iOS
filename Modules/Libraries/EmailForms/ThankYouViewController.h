//
//  ThankYouViewController.h
//  MIT Mobile
//
//  Created by Jim Kang on 10/17/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThankYouViewController : UITableViewController {
    
}

@property (nonatomic, retain) NSString *thankYouText;
@property (nonatomic, retain) dispatch_block_t doneBlock;

- (IBAction)returnToHomeButtonTapped:(id)sender;

@end
