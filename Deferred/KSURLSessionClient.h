#import "KSNetworkClient.h"

@class KSPromise;

@interface KSURLSessionClient : NSObject <KSNetworkClient>

@property (nonatomic, readonly) NSURLSession *session;

- (instancetype)init;
- (instancetype)initWithURLSession:(NSURLSession *)session;

@end

