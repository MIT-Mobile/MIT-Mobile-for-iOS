
#import <Foundation/Foundation.h>
#import "StellarModel.h"

@class StellarClassesTableController;
@interface LoadClassesInTable : NSObject<ClassesLoadedDelegate> {
	StellarClassesTableController *tableController;
}

@property (nonatomic, assign) StellarClassesTableController *tableController;
@end


@interface StellarClassesTableController : UITableViewController<UIAlertViewDelegate> {
	StellarCourse *course;
	NSArray *classes;
	LoadClassesInTable *currentClassLoader;
	UIView *loadingView;
}

@property (nonatomic, retain) NSArray *classes;
@property (nonatomic, retain) LoadClassesInTable *currentClassLoader;
@property (nonatomic, retain) UIView *loadingView;

- (id) initWithCourse: (StellarCourse *)course;

- (void) alertViewCancel: (UIAlertView *)alertView;
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex;

@end
