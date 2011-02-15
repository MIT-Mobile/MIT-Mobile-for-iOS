
#import "SaveOperation.h"


@implementation SaveOperation
@synthesize dataToSave = _dataToSave;
@synthesize path = _path;
@synthesize filename = _filename;
@synthesize delegate = _delegate;
@synthesize userData = _userData;


-(id) initWithData:(NSData*) data saveToPath:(NSString*)path filename:(NSString*)filename userData:(NSDictionary*)userData
{
	self = [super init];
	if (self) {
		self.dataToSave = data;
		self.path = path;
		self.filename = filename;
		self.userData = userData;
	}
	
	return self;
}

-(void) dealloc
{
	self.path = nil;
	self.dataToSave = nil;
	self.filename = nil;
	self.userData = nil;
	self.delegate = nil;

	[super dealloc];
}
	
-(void) main
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:self.path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
	
	NSString *fullPath = [self.path stringByAppendingPathComponent:self.filename];
	if ([self.dataToSave writeToFile:fullPath atomically:YES])
	{
		[self.delegate saveOperationCompleteForFile:fullPath withUserData:self.userData];
	}
	[pool release];
}

@end
