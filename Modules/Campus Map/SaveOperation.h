
#import <Foundation/Foundation.h>

@protocol SaveOperationDelegate<NSObject>

-(void) saveOperationCompleteForFile:(NSString*)path withUserData:(NSDictionary*)userData;

@end


@interface SaveOperation : NSOperation
{
	// date object to save to disk
	NSData* _dataToSave;
	
	// name of the file
	NSString* _filename;
	
	// path to which we should write the data. 
	NSString* _path;
	
	// user data that gets passed back to the delegate
	NSDictionary* _userData;
	
	id<SaveOperationDelegate> _delegate;
}

@property (nonatomic, retain) NSData* dataToSave;
@property (nonatomic, retain) NSString* path;
@property (nonatomic, retain) NSString* filename;
@property (nonatomic, retain) NSDictionary* userData;

@property (assign) id<SaveOperationDelegate> delegate;

// init the operation with the data that will be saved and the path to which it will be written
-(id) initWithData:(NSData*) data saveToPath:(NSString*)path filename:(NSString*)filename userData:(NSDictionary*)userData;


@end
