#import "KSURLConnectionClient.h"
#import "KSDeferred.h"

@implementation KSNetworkClient

- (KSPromise<KSNetworkResponse *> *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    KSDeferred<KSNetworkResponse *> *deferred = [KSDeferred defer];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   [deferred rejectWithError:error];
                               } else {
                                   [deferred resolveWithValue:[KSNetworkResponse networkResponseWithURLResponse:response
                                                                                                           data:data]];
                               }
                           }];
    return deferred.promise;
}

@end

@implementation KSURLConnectionClient
@end
