#import <Foundation/Foundation.h>

@class KSPromise;

@interface KSNetworkResponse : NSObject
@property (strong, nonatomic, readonly) NSURLResponse *response;
@property (strong, nonatomic, readonly) NSData *data;
@end

@interface KSNetworkClient : NSObject
- (KSPromise *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue;
@end
