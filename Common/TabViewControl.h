
#import <UIKit/UIKit.h>

@class TabViewControl;

@protocol TabViewControlDelegate<NSObject>

-(void) tabControl:(TabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText;

@end

@interface TabViewControl : UIControl {

	NSArray* _tabs;
	
	int _selectedTab;
	
	int _pressedTab;
	
	UIFont* _tabFont;
	
	id<TabViewControlDelegate> _delegate;
}

@property (nonatomic, retain) NSArray* tabs;
@property int selectedTab;
@property (nonatomic, assign) id<TabViewControlDelegate> delegate;


// adds a tab and returns the index of that tab
-(int) addTab:(NSString*) tabName;




@end
