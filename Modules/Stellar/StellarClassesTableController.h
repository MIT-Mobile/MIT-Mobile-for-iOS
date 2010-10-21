#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "MITModuleURL.h"

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
	
	MITModuleURL *url;
}

@property (nonatomic, retain) NSArray *classes;
@property (nonatomic, retain) LoadClassesInTable *currentClassLoader;
@property (nonatomic, retain) UIView *loadingView;

@property (readonly) MITModuleURL *url;

- (id) initWithCourse: (StellarCourse *)course;
@end
