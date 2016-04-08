#import "KSURLConnectionClient.h"
#import "KSPromise.h"

@implementation KSNetworkClient

- (KSPromise KS_GENERIC(KSNetworkResponse *) *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    return [KSPromise promise:^(resolveType  _Nonnull resolve, rejectType  _Nonnull reject) {
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                reject(error);
            } else {
                resolve([KSNetworkResponse networkResponseWithURLResponse:response                                                               data:data]);
            }
        }];
    }];
}

@end

@implementation KSURLConnectionClient
@end
