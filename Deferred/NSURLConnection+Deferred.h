#import <Foundation/Foundation.h>
#import "KSDeferred.h"

@interface NSURLConnection (KSDeferred)

+ (KSPromise *)sendRequest:(NSURLRequest *)request;
+ (KSPromise *)sendRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue;

@end
