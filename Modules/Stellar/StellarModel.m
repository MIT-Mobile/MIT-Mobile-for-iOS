#import "StellarModel.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarAnnouncement.h"
#import "StellarCache.h"
#import "ConnectionWrapper.h"
#import "CoreDataManager.h"

#define DAY 24 * 60 * 60
#define MONTH 30 * DAY

NSString * const StellarHeader = @"Stellar";
NSString * const MyStellarChanged = @"MyStellarChanged";

/** This class is responsible for grabbing stellar data 
 the methods are written to accept callbacks, so everything is asynchronous
 
 there are two levels of data retrieval (depending on the type of query being executed)
 
 CoreData (semi permanent on disk storage)
 
 MITMobileWebAPI (requires server connection to call the mit mobile web server)
**/


NSInteger classNameCompare(id class1, id class2, void *context);
NSInteger classNameInCourseCompare(id class1, id class2, void *context);
NSString* cleanPersonName(NSString *personName);

@interface StellarModel (Private)

+ (BOOL) classesFreshForCourse: (StellarCourse *)course;
+ (NSArray *) classesForCourse: (StellarCourse *)course;
+ (void) classesForCourseCompleteRequest:(ClassesRequest *)classesRequest;

@end

@implementation StellarModel

+ (BOOL) coursesCached {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSDate *coursesLastSaved = (NSDate *)[settings objectForKey:@"stellarCoursesLastSaved"];
	if(coursesLastSaved == nil) {
		return NO;
	} else {
		return (BOOL)(-[coursesLastSaved timeIntervalSinceNow] < MONTH);
	}
}

+ (void) loadCoursesFromServerAndNotify: (id<CoursesLoadedDelegate>)delegate {
	if([StellarModel coursesCached]) {
		[delegate coursesLoaded];
		return;
	}
	
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI 
		jsonLoadedDelegate:[[[CoursesRequest alloc] 
			initWithCoursesDelegate:delegate] autorelease]];
	[apiRequest requestObjectFromModule:@"stellar" command:@"courses" parameters:nil];
}

+ (BOOL) classesFreshForCourse: (StellarCourse *)course term: (NSString *)term {
	// check for an existance of a last cached date first
	if (![course.term length] || !course.lastCache || !term) {
		return NO;
	}

	// check if term is old
	if (![course.term isEqualToString:term]) {
		// new term remove all the classes for this course
		[course removeStellarClasses:course.stellarClasses];
		course.lastChecksum = nil;
		course.lastCache = nil;
		[CoreDataManager saveData];
		return NO;
	}
		
	return (-[course.lastCache timeIntervalSinceNow] < 2 * DAY);
}
	
+ (void) loadClassesForCourse: (StellarCourse *)stellarCourse delegate: (NSObject<ClassesLoadedDelegate>*) delegate {
	ClassesRequest *classesRequest = [[[ClassesRequest alloc] initWithDelegate:delegate course:stellarCourse] autorelease];
	// check if the current class list cache for course is old

	NSString *term = [[NSUserDefaults standardUserDefaults] objectForKey:StellarTermKey];
	if ([StellarModel classesFreshForCourse:stellarCourse term:term]) {
		[classesRequest performSelector:@selector(notifyClassesLoadedDelegate) withObject:nil afterDelay:0.1];
	} else {
		// see if the class info has changed using a checksum		
		if(stellarCourse.lastChecksum) {
			MITMobileWebAPI *apiRequest = [MITMobileWebAPI
										   jsonLoadedDelegate:[[[ClassesChecksumRequest alloc] initWithClassesRequest:classesRequest] autorelease]];
		
			[apiRequest 
				requestObjectFromModule:@"stellar" 
				command:@"subjectList" 
				parameters:[NSDictionary dictionaryWithObjectsAndKeys: 
					stellarCourse.number, @"id", 
					@"true", @"checksum", 
					nil]];
		} else {
			[self classesForCourseCompleteRequest:classesRequest];
		}
	}
}

/* this method is the final call to the server, to retreive all the classes for a given course
   along with a checksum for detecting changes to a course
 */
+ (void) classesForCourseCompleteRequest:(ClassesRequest *)classesRequest {
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI jsonLoadedDelegate:classesRequest];
	[apiRequest 
	 requestObjectFromModule:@"stellar" 
	 command:@"subjectList" 
	 parameters:[NSDictionary dictionaryWithObjectsAndKeys: 
		classesRequest.stellarCourse.number, @"id",
		@"true", @"checksum",
		@"true", @"full",
		nil]];
}

+ (NSArray *) classesForCourse:(StellarCourse *)course {
	return [[course.stellarClasses allObjects] sortedArrayUsingFunction:classNameInCourseCompare context:course];
}

+ (void) executeStellarSearch: (NSString *)searchTerms delegate: (id<ClassesSearchDelegate>)delegate {
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI
		jsonLoadedDelegate:[[[ClassesSearchRequest alloc]
			initWithDelegate:delegate searchTerms:searchTerms] autorelease]];
	[apiRequest 
		requestObjectFromModule:@"stellar" 
		command:@"search" 
		parameters:[NSDictionary dictionaryWithObject:searchTerms forKey:@"query"]];
}
	
+ (NSArray *) allCourses {
	return [CoreDataManager fetchDataForAttribute:StellarCourseEntityName];
}

+ (NSArray *) myStellarClasses {
	return [[CoreDataManager objectsForEntity:StellarClassEntityName 
				matchingPredicate:[NSPredicate predicateWithFormat:@"isFavorited == 1"]]
			 sortedArrayUsingFunction:classNameCompare context:NULL];
				
}

+ (NSArray *) sortedAnnouncements: (StellarClass *)class {
	return [[class.announcement allObjects]
	 sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO] autorelease]]];
}

+ (void) loadAllClassInfo: (StellarClass *)class delegate: (id<ClassInfoLoadedDelegate>)delegate {
	// there three states class info can exist in
	// 1) just contains general information such as the name and location and instructors
	// 2) contains all the information and has been recently retrived from the mobile web server (therefore is up-to-date)
	
	
	if([class.name length]) {
		[delegate generalClassInfoLoaded:class];
	}
	
	if([class.isFavorited boolValue]) {
		[delegate initialAllClassInfoLoaded:class];
	}
	
	// finally we call the server to get the most definitive data
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI
		jsonLoadedDelegate:[[[ClassInfoRequest alloc] 
			initWithClassInfoDelegate:delegate] autorelease]];
	
	[apiRequest 
		requestObjectFromModule:@"stellar" 
		command:@"subjectInfo" 
		parameters:[NSDictionary dictionaryWithObject: class.masterSubjectId forKey:@"id"]];
}

+ (void) saveClassToFavorites: (StellarClass *)class {
	class.isFavorited = [NSNumber numberWithInt:1];
	[CoreDataManager saveData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
}

+ (void) removeClassFromFavorites: (StellarClass *)class notify: (BOOL)sendNotification{
	class.isFavorited = [NSNumber numberWithInt:0];
	[CoreDataManager saveData];

	if(sendNotification) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
	}
}

+ (void) removeClassFromFavorites: (StellarClass *)class {
	[self removeClassFromFavorites:class notify:YES];
}

+ (void) removeOldFavorites: (id<ClearMyStellarDelegate>)delegate {
	// we call the server to get the current semester
	NSArray *favorites = [self myStellarClasses];
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI
		jsonLoadedDelegate:[[[TermRequest alloc] 
			initWithClearMyStellarDelegate:delegate stellarClasses:favorites] autorelease]];
		
	[apiRequest requestObjectFromModule:@"stellar" command:@"term" parameters:nil];
}

+ (StellarCourse *) courseWithId: (NSString *)courseId {
	return [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"number" value:courseId];
}

+ (StellarClass *) classWithMasterId: (NSString *)masterSubjectId {
	StellarClass *stellarClass;
	NSArray *stellarClasses = [CoreDataManager objectsForEntity:StellarClassEntityName 
		matchingPredicate:[NSPredicate predicateWithFormat:@"masterSubjectId == %@", masterSubjectId]];
	if([stellarClasses count]) {
		stellarClass = [stellarClasses objectAtIndex:0];
	} else {
		stellarClass = (StellarClass *)[CoreDataManager insertNewObjectForEntityForName:StellarClassEntityName];
		stellarClass.masterSubjectId = masterSubjectId;
	}
	return stellarClass;
}
	
+ (StellarClass *) StellarClassFromDictionary: (NSDictionary *)aDict {
	StellarClass *stellarClass = [StellarModel classWithMasterId:[aDict objectForKey:@"masterId"]];
	
	NSString *name = [aDict objectForKey:@"name"];
	// if name is not defined do not attempt to overwrite with new information
	if([name length]) {		
		stellarClass.name = name;
		stellarClass.title = [aDict objectForKey:@"title"];
		stellarClass.blurb = [aDict objectForKey:@"description"];
		stellarClass.term = [aDict objectForKey:@"term"];
		stellarClass.url = [aDict objectForKey:@"stellarUrl"];
		stellarClass.lastAccessedDate = [NSDate date];
	
		// add the class times
		for(NSManagedObject *managedObject in stellarClass.times) {
			// remove the old version of the class times
			[CoreDataManager deleteObject:managedObject];
		}
		NSInteger orderId = 0;
		for(NSDictionary *time in (NSArray *)[aDict objectForKey:@"times"]) {
			[stellarClass addTimesObject:[StellarModel stellarTimeFromDictionary:time class:stellarClass orderId:orderId]];
			orderId++;
		}
	
		// add the class staff
		for(NSManagedObject *managedObject in stellarClass.staff) {
			// remove the old version of the class staff
			[CoreDataManager deleteObject:managedObject];
		}
		NSDictionary *staff = (NSDictionary *)[aDict objectForKey:@"staff"];
		NSArray *instructors = (NSArray *)[staff objectForKey:@"instructors"];
		NSArray *tas = (NSArray *)[staff objectForKey:@"tas"];
		for(NSString *staff in instructors) {
			[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"instructor"]];
		}
		for(NSString *staff in tas) {
			[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"ta"]];
		}

		// add the annoucements
		NSArray *annoucements = [aDict objectForKey:@"announcements"];
		if(annoucements) {
			for(NSManagedObject *managedObject in stellarClass.announcement) {
				// remove the old version of the class annoucements
				[CoreDataManager deleteObject:managedObject];
			}
			for(NSDictionary *annoucementDict in annoucements) {
				[stellarClass addAnnouncementObject:[StellarModel stellarAnnouncementFromDict:annoucementDict]];
			}
		}
	}
	return stellarClass;
}

+ (StellarClassTime *) stellarTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)class orderId: (NSInteger)orderId {
	StellarClassTime *stellarClassTime = (StellarClassTime *)[CoreDataManager insertNewObjectForEntityForName:StellarClassTimeEntityName];
	stellarClassTime.stellarClass = class;
	stellarClassTime.title = [time objectForKey:@"title"];
	stellarClassTime.location = [time objectForKey:@"location"];
	stellarClassTime.time = [time objectForKey:@"time"];
	stellarClassTime.order = [NSNumber numberWithInt:orderId];
	return stellarClassTime;
}

+ (StellarStaffMember *) stellarStaffFromName: (NSString *)name class:(StellarClass *)class type: (NSString *)type {
	StellarStaffMember *stellarStaffMember = (StellarStaffMember *)[CoreDataManager insertNewObjectForEntityForName:StellarStaffMemberEntityName];
	stellarStaffMember.stellarClass = class;
	stellarStaffMember.name = cleanPersonName(name);
	stellarStaffMember.type = type;
	return stellarStaffMember;
}

+ (StellarAnnouncement *) stellarAnnouncementFromDict: (NSDictionary *)dict {
	StellarAnnouncement *stellarAnnouncement = (StellarAnnouncement *)[CoreDataManager insertNewObjectForEntityForName:StellarAnnouncementEntityName];
	stellarAnnouncement.pubDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[(NSNumber *)[dict objectForKey:@"unixtime"] doubleValue]];
	stellarAnnouncement.title = (NSString *)[dict objectForKey:@"title"];
	stellarAnnouncement.text = (NSString *)[dict objectForKey:@"text"];
	return stellarAnnouncement;
}
	
@end

@implementation CoursesRequest
@synthesize coursesLoadedDelegate;

- (id) initWithCoursesDelegate: (id<CoursesLoadedDelegate>)delegate {
	self = [super init];
	if (self) {
		self.coursesLoadedDelegate = delegate;
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSArray *courses = (NSArray *)object;
	if (courses.count == 0) {
		// no courses to save
		return;
	}

	for(NSDictionary *aDict in courses) {
		StellarCourse *oldStellarCourse = [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"number" value:[aDict objectForKey:@"short"]];
		if(oldStellarCourse) {
			// delete old course (will replace all the data, occasionally non-critical relationships
			// between a course and its subject will be lost
			[CoreDataManager deleteObject:oldStellarCourse];
		}
		
		StellarCourse *newStellarCourse = (StellarCourse *)[CoreDataManager insertNewObjectForEntityForName:StellarCourseEntityName];
		newStellarCourse.number = [aDict objectForKey:@"short"];
		newStellarCourse.title = [aDict objectForKey:@"name"];
	}
	[CoreDataManager saveData];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"stellarCoursesLastSaved"];
	[self.coursesLoadedDelegate coursesLoaded];
}
	
- (void) dealloc {
	[coursesLoadedDelegate release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	if([StellarModel allCourses].count) {
		// courses failed to load, but we still have courses save on disk so it is okay
		[self.coursesLoadedDelegate coursesLoaded];
	}
}
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return ([StellarModel allCourses].count == 0);
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error {
	return StellarHeader;
}

@end

@implementation ClassesChecksumRequest
- (id) initWithClassesRequest: (ClassesRequest *)aClassesRequest {
	self = [super init];
	if (self) {
		classesRequest = [aClassesRequest retain];
	}
	return self;
}

- (void) dealloc {
	[classesRequest release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	if([classesRequest.stellarCourse.lastChecksum isEqualToString:[(NSDictionary *)object objectForKey:@"checksum"]]) {
		// checksum is the same no need to update class list
		[classesRequest markCourseAsNew];
		[classesRequest notifyClassesLoadedDelegate];
	} else {
		[StellarModel classesForCourseCompleteRequest:classesRequest];
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[classesRequest handleConnectionFailureForRequest:request];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error {
	return StellarHeader;
}

@end
@implementation ClassesRequest
@synthesize classesLoadedDelegate, stellarCourse;

- (id) initWithDelegate: (id<ClassesLoadedDelegate>)delegate course: (StellarCourse *)course {
	self = [super init];
	if (self) {
		self.classesLoadedDelegate = delegate;
		self.stellarCourse = course;
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSArray *classes = [object objectForKey:@"classes"];
	for(NSDictionary *aDict in classes) {
		[[StellarModel StellarClassFromDictionary:aDict] addCourseObject:self.stellarCourse];
	}
	self.stellarCourse.lastChecksum = [object objectForKey:@"checksum"];
	[self markCourseAsNew];
	[self notifyClassesLoadedDelegate];
}	

- (void) markCourseAsNew {
	self.stellarCourse.lastCache = [NSDate dateWithTimeIntervalSinceNow:0];
	self.stellarCourse.term = [[NSUserDefaults standardUserDefaults] objectForKey:StellarTermKey];
	[CoreDataManager saveData];
}
	
- (void) notifyClassesLoadedDelegate {
	[self.classesLoadedDelegate classesLoaded:[StellarModel classesForCourse:self.stellarCourse]];
}

- (void) dealloc {
	[classesLoadedDelegate release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[self.classesLoadedDelegate handleCouldNotReachStellar];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return StellarHeader;
}

- (id<UIAlertViewDelegate>)request:(MITMobileWebAPI *)request alertViewDelegateForError:(NSError *)error {
	return [self.classesLoadedDelegate standardErrorAlertDelegate];
}

@end

@implementation ClassesSearchRequest

- (id) initWithDelegate: (id<ClassesSearchDelegate>)delegate searchTerms: (NSString *)theSearchTerms {
	self = [super init];
	if (self) {
		classesSearchDelegate = [delegate retain];
		searchTerms = [theSearchTerms retain];
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSMutableArray *classes = [NSMutableArray array];
	for(NSDictionary *aDict in (NSArray *)object) {
		[classes addObject:[StellarModel StellarClassFromDictionary:aDict]];
	}
	[CoreDataManager saveData];
	[classesSearchDelegate searchComplete:classes searchTerms:searchTerms];
}	

- (void) dealloc {
	[classesSearchDelegate release];
	[searchTerms release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[classesSearchDelegate handleCouldNotReachStellarWithSearchTerms:searchTerms];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error {
	return StellarHeader;
}

@end

@implementation ClassInfoRequest
@synthesize classInfoLoadedDelegate;

- (id) initWithClassInfoDelegate: (id<ClassInfoLoadedDelegate>)delegate {
	self = [super init];
	if (self) {
		self.classInfoLoadedDelegate = delegate;
	}
	return self;
}

- (void) dealloc {
	[classInfoLoadedDelegate release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {	
	if([(NSDictionary *)object objectForKey:@"error"]) {
		[self.classInfoLoadedDelegate handleClassNotFound];
		return;
	}
	
	StellarClass *class = [StellarModel StellarClassFromDictionary:(NSDictionary *)object];
	
	[CoreDataManager saveData];
	[self.classInfoLoadedDelegate finalAllClassInfoLoaded:class];
}

- (void) handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[self.classInfoLoadedDelegate handleCouldNotReachStellar];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error {
	return StellarHeader;
}

@end


@implementation TermRequest

- (id) initWithClearMyStellarDelegate: (id<ClearMyStellarDelegate>)delegate stellarClasses: (NSArray *)theMyStellarClasses {
	self = [super init];
	if (self) {
		clearMyStellarDelegate = [delegate retain];
		myStellarClasses = [theMyStellarClasses retain];
		
	}
	return self;
}

- (void) dealloc {
	[myStellarClasses release];
	[clearMyStellarDelegate release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSString *term = [(NSDictionary *)object objectForKey:@"term"];
	[[NSUserDefaults standardUserDefaults] setObject:term forKey:StellarTermKey];
	
	NSMutableArray *oldClasses = [NSMutableArray array];
	for(StellarClass *class in myStellarClasses) {
		if(![term isEqualToString:class.term]) {
			[StellarModel removeClassFromFavorites:class notify:NO];
			[oldClasses addObject:class];
		}
	}
	
	if([oldClasses count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
		[clearMyStellarDelegate classesRemoved:oldClasses];
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return NO;
}
    
@end


NSInteger classIdCompare(NSDictionary *classId1, NSDictionary *classId2) {
	// check the nil cases first
	if(!classId1 && !classId2) {
		return 0;
	}
	if(!classId1) {
		return 1;
	}
	if(!classId2) {
		return -1;
	}
	
	NSString *coursePart1 = [classId1 objectForKey:@"coursePart"];
	NSString *classPart1 = [classId1 objectForKey:@"classPart"];
	NSString *coursePart2 = [classId2 objectForKey:@"coursePart"];
	NSString *classPart2 = [classId2 objectForKey:@"classPart"];
	
	if([coursePart1 compare:coursePart2 options:NSNumericSearch] != 0) {
		return [coursePart1 compare:coursePart2 options:NSNumericSearch];
	}
	
	return [classPart1 compare:classPart2];
}	
	
NSArray *extractClassIds(StellarClass *class) {
	// implementing a cache for this function because
	// this function apparantly is performance bottleneck
	NSArray *classIds = [StellarCache getClassIdsForName:class.name];
	if (classIds) {
		return classIds;
	}
	
	NSArray *words = [class.name componentsSeparatedByString:@" "];
	
	classIds = [NSArray array];
    //filter out words that our class ids
	for(NSString *word in words) {
		NSArray *parts = [word componentsSeparatedByString:@"."];
		if([parts count] == 2) {
			classIds = [classIds arrayByAddingObject:[NSDictionary 
				dictionaryWithObjectsAndKeys:[parts objectAtIndex:0], @"coursePart", [parts objectAtIndex:1], @"classPart", nil]
			];
		}
	}
	
	if(class.name) {
		[StellarCache addClassIds:classIds forName:class.name];
	}
	return classIds;
}

NSDictionary *firstClassId(StellarClass *class) {
	NSArray *classIds = extractClassIds(class);
	if([classIds count]) {
		return [classIds objectAtIndex:0];
	}
	return nil;
}

// compares any two class names
NSInteger classNameCompare(id class1, id class2, void *context) {
	// examples.. if class is "6.002 / 8.003", coursePart=@"6", classPart=@"002" 

	NSString *name1 = ((StellarClass *)class1).name;
	NSDictionary *classId1 = firstClassId((StellarClass *)class1);
	
	NSString *name2 = ((StellarClass *)class2).name;
	NSDictionary *classId2 = firstClassId((StellarClass *)class2);

	NSInteger classIdCompareResult = classIdCompare(classId1, classId2);
	if(classIdCompareResult) {
		return classIdCompareResult;
	}
	return [name1 compare:name2];
}

// compares class name by the part of the name that corresponds to certain class
NSInteger classNameInCourseCompare(id class1, id class2, void *context) {
	NSString *courseId = ((StellarCourse *)context).number;
	StellarClass *stellarClass1 = class1;
	StellarClass *stellarClass2 = class2;
	
	NSDictionary *classId1 = nil;
	NSArray *classIds1 = extractClassIds((StellarClass *)class1);
	for(NSDictionary *classId in classIds1) {
		if([[classId objectForKey:@"coursePart"] isEqualToString:courseId]) {
			classId1 = classId;
			break;
		}
	}
	
	NSDictionary *classId2 = nil;
	NSArray *classIds2 = extractClassIds((StellarClass *)class2);
	for(NSDictionary *classId in classIds2) {
		if([[classId objectForKey:@"coursePart"] isEqualToString:courseId]) {
			classId2 = classId;
			break;
		}
	}
	
	NSInteger classIdCompareResult = classIdCompare(classId1, classId2);
	if(classIdCompareResult) {
		return classIdCompareResult;
	}
	
	NSInteger nameCompare = [stellarClass1.name compare:stellarClass2.name];
	if(nameCompare) {
		return nameCompare;
	}
	
	return [stellarClass1.title compare:stellarClass2.title];
}	

NSString* cleanPersonName(NSString *personName) {
	NSArray *parts = [personName componentsSeparatedByString:@" "];
	NSMutableArray *cleanParts = [NSMutableArray array];
	for (NSString *part in parts) {
		if([part length]) {
			[cleanParts addObject:part];
		}
	}
	return [cleanParts componentsJoinedByString:@" "];
}
