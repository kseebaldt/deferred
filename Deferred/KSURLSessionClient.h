#import "KSNetworkClient.h"

@class KSPromise;

@interface KSURLSessionClient : NSObject <KSNetworkClient>

- (instancetype)init;
- (instancetype)initWithURLSession:(NSURLSession *)session;

@end

