#import "KSNetworkClient.h"
#import "KSNullabilityCompat.h"

@class KSPromise;

NS_ASSUME_NONNULL_BEGIN

@interface KSURLSessionClient : NSObject <KSNetworkClient>

@property (nonatomic, readonly) NSURLSession *session;

- (instancetype)init;
- (instancetype)initWithURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
