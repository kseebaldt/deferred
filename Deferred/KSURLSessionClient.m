#import "KSURLSessionClient.h"
#import "KSPromise.h"

@interface KSURLSessionClient ()
@property (strong, nonatomic, readwrite) NSURLSession *session;
@end

@implementation KSURLSessionClient

- (instancetype)init {
    return [self initWithURLSession:[NSURLSession sharedSession]];
}

- (instancetype)initWithURLSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        self.session = session;
    }
    return self;
}

- (KSPromise KS_GENERIC(KSNetworkResponse *) *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    return [KSPromise promise:^(resolveType  _Nonnull resolve, rejectType  _Nonnull reject) {
        [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [queue addOperationWithBlock:^{
                if (error) {
                    reject(error);
                } else {
                    resolve([KSNetworkResponse networkResponseWithURLResponse:response data:data]);
                }
            }];
        }] resume];
    }];
}

@end
