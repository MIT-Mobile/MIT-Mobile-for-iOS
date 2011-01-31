/*	DataCache.h
 *
 *		This is a basic aged cache object; this stores up to the capacity
 *	number of objects, and objects which haven't been accessed are dropped
 */

/***

Copyright 2008 William Woody, All Rights Reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

Neither the name of Chaos In Motion nor the names of its contributors may be 
used to endorse or promote products derived from this software without 
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
THE POSSIBILITY OF SUCH DAMAGE.

Contact William Woody at woody@alumni.caltech.edu or at 
woody@chaosinmotion.com. Chaos In Motion is at http://www.chaosinmotion.com

***/

// modified for MIT Mobile to allow object deletion.

#import <Foundation/Foundation.h>


@interface DataCache : NSObject 
{
	int fCapacity;
	NSMutableDictionary *fDictionary;
	NSMutableArray *fAge;
}

- (id)initWithCapacity:(int)cap;

- (id)objectForKey:(id)key;
- (void)setObject:(id)value forKey:(id)key;
- (void)removeObjectForKey:(id)key;

@end
