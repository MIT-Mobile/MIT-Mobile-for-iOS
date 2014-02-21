// from http://stackoverflow.com/questions/1328638/placeholder-in-uitextview/1704469#1704469

#import <Foundation/Foundation.h>


@interface PlaceholderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;

-(void)textChanged:(NSNotification*)notification;

@end